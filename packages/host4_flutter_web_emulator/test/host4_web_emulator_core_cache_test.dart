import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_web_emulator/host4_flutter_web_emulator.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('core_cache_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// 创建包含 .js 和 .wasm 的 ZIP bytes，用于模拟 HTTP 下载。
  List<int> buildCoreZip({
    required List<int> jsBytes,
    required List<int> wasmBytes,
    String coreName = 'mgba',
  }) {
    final archive = Archive();
    archive.addFile(
      ArchiveFile('${coreName}_libretro.js', jsBytes.length, jsBytes),
    );
    archive.addFile(
      ArchiveFile('${coreName}_libretro.wasm', wasmBytes.length, wasmBytes),
    );
    return ZipEncoder().encode(archive);
  }

  final jsContent = 'fake-js-content'.codeUnits;
  final wasmContent = 'fake-wasm-content'.codeUnits;

  /// 创建一个测试用的 core 定义和对应的 fake ZIP。
  ({Host4WebEmulatorCore core, List<int> zipBytes}) buildTestCore() {
    final zipBytes = buildCoreZip(jsBytes: jsContent, wasmBytes: wasmContent);
    final zipSha = sha256.convert(zipBytes).toString();
    final wasmSha = sha256.convert(wasmContent).toString();

    final core = Host4WebEmulatorCore(
      name: 'mgba',
      version: 'v-test',
      zipUrl: 'http://localhost:0/mgba_libretro.zip',
      zipSha256: zipSha,
      wasmSha256: wasmSha,
    );

    return (core: core, zipBytes: zipBytes);
  }

  group('resolve from cache', () {
    test('returns base64 data when cached files exist and SHA-256 matches',
        () async {
      final (:core, :zipBytes) = buildTestCore();
      final cache = Host4WebEmulatorCoreCache(cacheRoot: tempDir);

      // 预先写入缓存文件
      final coreDir = Directory('${tempDir.path}/${core.cacheSubPath}');
      await coreDir.create(recursive: true);
      await File('${coreDir.path}/${core.jsFileName}')
          .writeAsBytes(jsContent);
      await File('${coreDir.path}/${core.wasmFileName}')
          .writeAsBytes(wasmContent);

      final resolved = await cache.resolve(core);

      expect(base64Decode(resolved.jsBase64), jsContent);
      expect(base64Decode(resolved.wasmBase64), wasmContent);
    });

    test('re-downloads when cached wasm SHA-256 does not match', () async {
      final (:core, :zipBytes) = buildTestCore();

      // 预先写入 SHA-256 不匹配的缓存
      final coreDir = Directory('${tempDir.path}/${core.cacheSubPath}');
      await coreDir.create(recursive: true);
      await File('${coreDir.path}/${core.jsFileName}').writeAsBytes([0]);
      await File('${coreDir.path}/${core.wasmFileName}').writeAsBytes([0]);

      final server = await HttpServer.bind('127.0.0.1', 0);
      final url = 'http://127.0.0.1:${server.port}/mgba_libretro.zip';
      server.listen((request) {
        request.response.add(zipBytes);
        request.response.close();
      });

      try {
        final coreWithUrl = Host4WebEmulatorCore(
          name: core.name,
          version: core.version,
          zipUrl: url,
          zipSha256: core.zipSha256,
          wasmSha256: core.wasmSha256,
        );

        final cache = Host4WebEmulatorCoreCache(cacheRoot: tempDir);
        final resolved = await cache.resolve(coreWithUrl);

        // 校验返回的 base64 能还原为正确数据
        final wasmBytes = base64Decode(resolved.wasmBase64);
        expect(sha256.convert(wasmBytes).toString(), core.wasmSha256);
      } finally {
        await server.close();
      }
    });

    test('re-downloads when cached files are missing', () async {
      final (:core, :zipBytes) = buildTestCore();

      final server = await HttpServer.bind('127.0.0.1', 0);
      final url = 'http://127.0.0.1:${server.port}/mgba_libretro.zip';
      server.listen((request) {
        request.response.add(zipBytes);
        request.response.close();
      });

      try {
        final coreWithUrl = Host4WebEmulatorCore(
          name: core.name,
          version: core.version,
          zipUrl: url,
          zipSha256: core.zipSha256,
          wasmSha256: core.wasmSha256,
        );

        final cache = Host4WebEmulatorCoreCache(cacheRoot: tempDir);
        final resolved = await cache.resolve(coreWithUrl);

        // 确认缓存文件已写入
        final coreDir = Directory('${tempDir.path}/${core.cacheSubPath}');
        expect(
            File('${coreDir.path}/${core.jsFileName}').existsSync(), isTrue);
        expect(
            File('${coreDir.path}/${core.wasmFileName}').existsSync(), isTrue);

        // 确认返回了有效 base64
        expect(base64Decode(resolved.jsBase64), isNotEmpty);
        expect(base64Decode(resolved.wasmBase64), isNotEmpty);
      } finally {
        await server.close();
      }
    });
  });

  group('download and verify', () {
    test('throws when ZIP SHA-256 does not match', () async {
      final (:core, :zipBytes) = buildTestCore();

      final server = await HttpServer.bind('127.0.0.1', 0);
      server.listen((request) {
        request.response.add([0, 1, 2, 3]);
        request.response.close();
      });

      try {
        final coreWithUrl = Host4WebEmulatorCore(
          name: core.name,
          version: core.version,
          zipUrl: 'http://127.0.0.1:${server.port}/bad.zip',
          zipSha256: core.zipSha256,
          wasmSha256: core.wasmSha256,
        );

        final cache = Host4WebEmulatorCoreCache(cacheRoot: tempDir);
        await expectLater(
          cache.resolve(coreWithUrl),
          throwsA(isA<Host4CoreCacheException>().having(
            (e) => e.message,
            'message',
            contains('ZIP SHA-256 mismatch'),
          )),
        );
      } finally {
        await server.close();
      }
    });

    test('throws on HTTP error', () async {
      final (:core, :zipBytes) = buildTestCore();

      final server = await HttpServer.bind('127.0.0.1', 0);
      server.listen((request) {
        request.response.statusCode = 404;
        request.response.close();
      });

      try {
        final coreWithUrl = Host4WebEmulatorCore(
          name: core.name,
          version: core.version,
          zipUrl: 'http://127.0.0.1:${server.port}/not-found.zip',
          zipSha256: core.zipSha256,
          wasmSha256: core.wasmSha256,
        );

        final cache = Host4WebEmulatorCoreCache(cacheRoot: tempDir);
        await expectLater(
          cache.resolve(coreWithUrl),
          throwsA(isA<Host4CoreCacheException>().having(
            (e) => e.message,
            'message',
            contains('HTTP 404'),
          )),
        );
      } finally {
        await server.close();
      }
    });
  });

  group('launch config integration', () {
    test('toJson includes base64 when resolvedCoreData is provided', () {
      final resolved = ResolvedCoreData(
        jsBase64: 'JS_BASE64',
        wasmBase64: 'WASM_BASE64',
      );

      final config = Host4WebEmulatorLaunchConfig(
        system: Host4WebEmulatorSystem.gb,
        romFileUrl: Uri.file('/tmp/demo.gb'),
        romName: 'demo.gb',
      );

      final json = config.toJson(resolvedCoreData: resolved);
      expect(json['coreJsBase64'], 'JS_BASE64');
      expect(json['coreWasmBase64'], 'WASM_BASE64');
      expect(json.containsKey('coreZipUrl'), isFalse);
    });

    test('toJson falls back to coreZipUrl when resolvedCoreData is null', () {
      final config = Host4WebEmulatorLaunchConfig(
        system: Host4WebEmulatorSystem.gb,
        romFileUrl: Uri.file('/tmp/demo.gb'),
        romName: 'demo.gb',
      );

      final json = config.toJson();
      expect(json.containsKey('coreZipUrl'), isTrue);
      expect(json.containsKey('coreJsBase64'), isFalse);
    });
  });

  test('core defines wasm SHA-256 for cache verification', () {
    expect(
      Host4WebEmulatorCore.mgba.wasmSha256,
      '3a80ac96ae8e82628ed483e8bb528669b03e7186a2cf90abf89a6d66c3aba6bb',
    );
  });

  test('core provides cache path helpers', () {
    expect(Host4WebEmulatorCore.mgba.cacheSubPath, 'mgba/v1.22.2');
    expect(Host4WebEmulatorCore.mgba.jsFileName, 'mgba_libretro.js');
    expect(Host4WebEmulatorCore.mgba.wasmFileName, 'mgba_libretro.wasm');
  });
}
