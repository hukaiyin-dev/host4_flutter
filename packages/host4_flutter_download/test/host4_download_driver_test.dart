import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_download_manager/flutter_download_manager.dart' as fdm;
import 'package:host4_flutter_download/src/driver/host4_download_driver.dart';
import 'package:host4_flutter_download/host4_flutter_download.dart';
import 'package:host4_flutter_download/src/storage/host4_download_store.dart';

void main() {
  late Directory tempRoot;
  late Host4DownloadStore store;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('host4_download_driver_');
    store = Host4DownloadStore(rootDirectoryProvider: () async => tempRoot);
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  test('keeps partial file only when Range probe returns 206', () async {
    final entry = await store.prepare(
      Host4DownloadRequest(url: Uri.parse('https://example.com/a.bin')),
    );
    await entry.partialFile.writeAsBytes([1, 2, 3]);
    final driver = FlutterDownloadManagerDriver(
      rangeProbe: (_, bytes) async {
        expect(bytes, 3);
        return 206;
      },
    );

    final decision = await driver.prepareStart(entry);

    expect(decision.kind, Host4DownloadStartKind.resumePartial);
    expect(decision.resumePartial, isTrue);
    expect(await entry.partialFile.exists(), isTrue);
  });

  test(
    'deletes partial file and starts fresh when Range probe returns 200',
    () async {
      final entry = await store.prepare(
        Host4DownloadRequest(url: Uri.parse('https://example.com/a.bin')),
      );
      await entry.partialFile.writeAsBytes([1, 2, 3]);
      final driver = FlutterDownloadManagerDriver(
        rangeProbe: (_, _) async => 200,
      );

      final decision = await driver.prepareStart(entry);

      expect(decision.kind, Host4DownloadStartKind.fresh);
      expect(decision.resumePartial, isFalse);
      expect(await entry.partialFile.exists(), isFalse);
    },
  );

  test('range fallback deletes only the current task partial file', () async {
    final first = await store.prepare(
      Host4DownloadRequest(url: Uri.parse('https://example.com/a.bin')),
    );
    final second = await store.prepare(
      Host4DownloadRequest(url: Uri.parse('https://example.com/b.bin')),
    );
    await first.partialFile.writeAsBytes([1, 2, 3]);
    await second.partialFile.writeAsBytes([4, 5, 6, 7]);
    final probed = <String, int>{};
    final driver = FlutterDownloadManagerDriver(
      rangeProbe: (url, bytes) async {
        probed[url.toString()] = bytes;
        return 200;
      },
    );

    final decision = await driver.prepareStart(first);

    expect(decision.kind, Host4DownloadStartKind.fresh);
    expect(probed, {first.url.toString(): 3});
    expect(await first.partialFile.exists(), isFalse);
    expect(await second.partialFile.exists(), isTrue);
    expect(await second.partialFile.readAsBytes(), [4, 5, 6, 7]);
  });

  test(
    'deletes partial file and starts fresh when Range probe returns non-206',
    () async {
      final entry = await store.prepare(
        Host4DownloadRequest(url: Uri.parse('https://example.com/a.bin')),
      );
      await entry.partialFile.writeAsBytes([1, 2, 3]);
      final driver = FlutterDownloadManagerDriver(
        rangeProbe: (_, _) async => 500,
      );

      final decision = await driver.prepareStart(entry);

      expect(decision.kind, Host4DownloadStartKind.fresh);
      expect(decision.resumePartial, isFalse);
      expect(await entry.partialFile.exists(), isFalse);
    },
  );

  test(
    'deletes empty partial file and starts fresh without probing Range',
    () async {
      final entry = await store.prepare(
        Host4DownloadRequest(url: Uri.parse('https://example.com/a.bin')),
      );
      await entry.partialFile.create();
      var probed = false;
      final driver = FlutterDownloadManagerDriver(
        rangeProbe: (_, _) async {
          probed = true;
          return 206;
        },
      );

      final decision = await driver.prepareStart(entry);

      expect(decision.kind, Host4DownloadStartKind.fresh);
      expect(probed, isFalse);
      expect(await entry.partialFile.exists(), isFalse);
    },
  );

  test(
    'deletes partial file and starts fresh when Range probe fails',
    () async {
      final entry = await store.prepare(
        Host4DownloadRequest(url: Uri.parse('https://example.com/a.bin')),
      );
      await entry.partialFile.writeAsBytes([1, 2, 3]);
      final driver = FlutterDownloadManagerDriver(
        rangeProbe: (_, _) => throw StateError('probe failed'),
      );

      final decision = await driver.prepareStart(entry);

      expect(decision.kind, Host4DownloadStartKind.fresh);
      expect(decision.resumePartial, isFalse);
      expect(await entry.partialFile.exists(), isFalse);
    },
  );

  test(
    'does not start third party download when complete file is readable',
    () async {
      final entry = await store.prepare(
        Host4DownloadRequest(url: Uri.parse('https://example.com/a.bin')),
      );
      await entry.file.writeAsBytes([1, 2, 3]);
      var started = false;
      final driver = FlutterDownloadManagerDriver(
        rangeProbe: (_, _) async => 206,
        startDownload: (_, {required resumePartial}) async {
          started = true;
          throw StateError('should not start');
        },
      );

      final decision = await driver.prepareStart(entry);

      expect(decision.kind, Host4DownloadStartKind.completedFile);
      expect(decision.completeFileReadable, isTrue);
      expect(started, isFalse);
    },
  );

  test('does not treat an empty target file as a completed download', () async {
    final entry = await store.prepare(
      Host4DownloadRequest(url: Uri.parse('https://example.com/a.bin')),
    );
    await entry.file.create();
    final driver = FlutterDownloadManagerDriver(
      rangeProbe: (_, _) async => 206,
    );

    final decision = await driver.prepareStart(entry);

    expect(decision.kind, Host4DownloadStartKind.fresh);
    expect(decision.completeFileReadable, isFalse);
  });

  test(
    'third party completed status still requires a readable non-empty file',
    () async {
      final entry = await store.prepare(
        Host4DownloadRequest(
          url: Uri.parse(
            'https://example.com/${DateTime.now().microsecondsSinceEpoch}.bin',
          ),
        ),
      );
      await entry.file.create();
      final driver = FlutterDownloadManagerDriver(
        rangeProbe: (_, _) async => 206,
      );
      final decision = await driver.prepareStart(entry);

      final handle = await driver.start(entry, decision: decision);

      await expectLater(handle.done, throwsA(isA<StateError>()));
    },
  );

  test('start returns a handle that identifies its taskKey', () async {
    final entry = await store.prepare(
      Host4DownloadRequest(url: Uri.parse('https://example.com/a.bin')),
    );
    final driver = FlutterDownloadManagerDriver(
      startDownload: (entry, {required resumePartial}) async {
        return _FakeDriverHandle(entry.taskKey);
      },
    );
    final decision = await driver.prepareStart(entry);

    final handle = await driver.start(entry, decision: decision);

    expect(handle.taskKey, entry.taskKey);
  });

  test('injects provided Dio into the underlying download manager', () {
    final dio = Dio();
    final manager = fdm.DownloadManager(maxConcurrentTasks: 1);
    final previousDio = manager.dio;
    addTearDown(() {
      manager.dio = previousDio;
    });

    FlutterDownloadManagerDriver(dio: dio, downloadManager: manager);

    expect(manager.dio, same(dio));
  });

  test(
    'does not override provided download manager concurrency by default',
    () {
      final manager = fdm.DownloadManager();
      final previousMaxConcurrentTasks = manager.maxConcurrentTasks;
      addTearDown(() {
        fdm.DownloadManager(maxConcurrentTasks: previousMaxConcurrentTasks);
      });
      fdm.DownloadManager(maxConcurrentTasks: 4);

      FlutterDownloadManagerDriver(downloadManager: manager);

      expect(manager.maxConcurrentTasks, 4);
    },
  );

  test('driver source lives under src/driver and old root path is removed', () {
    expect(
      File('lib/src/driver/host4_download_driver.dart').existsSync(),
      isTrue,
    );
    expect(File('lib/src/host4_download_driver.dart').existsSync(), isFalse);
  });

  test(
    'driver directory is the only lib source that imports Dio or download manager',
    () {
      final src = Directory('lib/src');
      final offenders = <String>[];

      for (final entity in src.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) {
          continue;
        }
        final content = entity.readAsStringSync();
        final importsThirdParty =
            content.contains("package:dio/") ||
            content.contains("package:flutter_download_manager/");
        if (importsThirdParty &&
            !entity.path.endsWith('driver/host4_download_driver.dart')) {
          offenders.add(entity.path);
        }
      }

      expect(offenders, isEmpty);
    },
  );
}

class _FakeDriverHandle implements Host4DownloadDriverHandle {
  _FakeDriverHandle(this.taskKey);

  @override
  final String taskKey;

  @override
  Stream<double> get progress => const Stream<double>.empty();

  @override
  Future<void> get done => Future<void>.value();

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> cancel() async {}
}
