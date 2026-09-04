import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

import 'host4_web_emulator_core.dart';

/// 从磁盘缓存或网络下载解析 core 文件，返回 base64 编码的数据。
///
/// 缓存结构：
/// ```
/// <cacheRoot>/<core.name>/<core.version>/
///   ├── <core.name>_libretro.js
///   └── <core.name>_libretro.wasm
/// ```
///
/// 使用 base64 而非 file URL 传递给 WebView，因为 WKWebView 和 Android
/// WebView 的文件访问沙盒不允许读取 Application Support 下的文件。
class Host4WebEmulatorCoreCache {
  Host4WebEmulatorCoreCache({
    required this.cacheRoot,
    HttpClient? httpClient,
    this.downloadTimeout = const Duration(seconds: 30),
  }) : _httpClient = httpClient;

  final Directory cacheRoot;
  final HttpClient? _httpClient;

  /// HTTP 连接 + 响应读取的总超时。
  final Duration downloadTimeout;

  /// 解析 core：优先使用本地缓存，缓存不存在或校验失败时从网络下载。
  ///
  /// 返回 base64 编码的 JS 和 WASM 数据，可直接注入 WebView。
  Future<ResolvedCoreData> resolve(Host4WebEmulatorCore core) async {
    final coreDir = Directory('${cacheRoot.path}/${core.cacheSubPath}');
    final jsFile = File('${coreDir.path}/${core.jsFileName}');
    final wasmFile = File('${coreDir.path}/${core.wasmFileName}');

    // 尝试使用本地缓存
    if (await jsFile.exists() && await wasmFile.exists()) {
      final wasmBytes = await wasmFile.readAsBytes();
      final localSha256 = sha256.convert(wasmBytes).toString();
      if (localSha256 == core.wasmSha256) {
        final jsBytes = await jsFile.readAsBytes();
        return ResolvedCoreData(
          jsBase64: base64Encode(jsBytes),
          wasmBase64: base64Encode(wasmBytes),
        );
      }
      // SHA-256 不匹配，删除旧缓存
      await coreDir.delete(recursive: true);
    }

    // 下载并缓存
    await _downloadAndExtract(core, coreDir, jsFile, wasmFile);

    final jsBytes = await jsFile.readAsBytes();
    final wasmBytes = await wasmFile.readAsBytes();
    return ResolvedCoreData(
      jsBase64: base64Encode(jsBytes),
      wasmBase64: base64Encode(wasmBytes),
    );
  }

  Future<void> _downloadAndExtract(
    Host4WebEmulatorCore core,
    Directory coreDir,
    File jsFile,
    File wasmFile,
  ) async {
    final client = _httpClient ?? HttpClient();
    try {
      final zipBytes = await _downloadZip(client, core.zipUrl)
          .timeout(downloadTimeout, onTimeout: () {
        throw Host4CoreCacheException(
          'Core download timed out after ${downloadTimeout.inSeconds}s',
        );
      });

      // 校验 ZIP SHA-256
      final zipDigest = sha256.convert(zipBytes);
      if (zipDigest.toString() != core.zipSha256) {
        throw Host4CoreCacheException(
          'ZIP SHA-256 mismatch: expected ${core.zipSha256}, '
          'got $zipDigest',
        );
      }

      // 解压
      final archive = ZipDecoder().decodeBytes(zipBytes);
      List<int>? jsBytes;
      List<int>? wasmBytes;

      for (final entry in archive) {
        if (entry.isFile) {
          if (entry.name.endsWith('.js')) {
            jsBytes = entry.content as List<int>;
          } else if (entry.name.endsWith('.wasm')) {
            wasmBytes = entry.content as List<int>;
          }
        }
      }

      if (jsBytes == null || wasmBytes == null) {
        throw Host4CoreCacheException(
          'Core ZIP missing .js or .wasm for ${core.name}',
        );
      }

      // 校验 wasm SHA-256
      final wasmDigest = sha256.convert(wasmBytes);
      if (wasmDigest.toString() != core.wasmSha256) {
        throw Host4CoreCacheException(
          'WASM SHA-256 mismatch: expected ${core.wasmSha256}, '
          'got $wasmDigest',
        );
      }

      // 写入缓存目录
      await coreDir.create(recursive: true);
      await jsFile.writeAsBytes(jsBytes, flush: true);
      await wasmFile.writeAsBytes(wasmBytes, flush: true);
    } finally {
      if (_httpClient == null) client.close();
    }
  }

  static Future<List<int>> _downloadZip(
    HttpClient client,
    String url,
  ) async {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    if (response.statusCode != 200) {
      throw Host4CoreCacheException(
        'Failed to download core ZIP: HTTP ${response.statusCode}',
      );
    }
    final chunks = <List<int>>[];
    await for (final chunk in response) {
      chunks.add(chunk);
    }
    return chunks.expand((c) => c).toList(growable: false);
  }
}

/// core 解析结果，包含 base64 编码的 JS 和 WASM 数据。
class ResolvedCoreData {
  const ResolvedCoreData({
    required this.jsBase64,
    required this.wasmBase64,
  });

  final String jsBase64;
  final String wasmBase64;
}

class Host4CoreCacheException implements Exception {
  const Host4CoreCacheException(this.message);

  final String message;

  @override
  String toString() => 'Host4CoreCacheException: $message';
}
