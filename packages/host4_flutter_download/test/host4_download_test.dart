import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_download_manager/flutter_download_manager.dart' as fdm;
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_download/host4_flutter_download.dart';
import 'package:host4_flutter_download/src/driver/host4_download_driver.dart';
import 'package:host4_flutter_download/src/storage/host4_download_store.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempRoot;
  late Host4DownloadStore store;
  late _FakeStarter starter;
  late FlutterDownloadManagerDriver driver;
  late Host4Download download;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('host4_download_');
    store = Host4DownloadStore(rootDirectoryProvider: () async => tempRoot);
    starter = _FakeStarter();
    driver = FlutterDownloadManagerDriver(
      rangeProbe: (_, _) async => 206,
      startDownload: starter.start,
    );
    download = Host4Download.debug(store: store, driver: driver);
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  test('rejects non HTTP URLs without creating managed files', () async {
    await expectLater(
      () => download.download(Uri.parse('file:///tmp/firmware.bin')),
      throwsArgumentError,
    );

    expect(
      Directory(p.join(tempRoot.path, 'host4', 'downloads')).existsSync(),
      isFalse,
    );
    expect(starter.started, isEmpty);
  });

  test(
    'returns active same URL task without starting another download',
    () async {
      final url = Uri.parse('https://example.com/a.bin');

      final first = await download.download(url);
      final second = await download.download(url);

      expect(second, same(first));
      expect(starter.started, hasLength(1));
      expect(first.status, Host4DownloadStatus.downloading);
    },
  );

  test(
    'returns the same queued task for concurrent same URL requests',
    () async {
      final url = Uri.parse('https://example.com/a.bin');

      final firstFuture = download.download(url);
      final secondFuture = download.download(url);
      final first = await firstFuture;
      final second = await secondFuture;

      expect(second, same(first));
      expect(starter.started, hasLength(1));
    },
  );

  test('maps driver progress and delegates task controls', () async {
    final task = await download.download(Uri.parse('http://example.com/a.bin'));

    starter.last.emitProgress(0.42);
    await Future<void>.delayed(Duration.zero);
    expect(task.progress, 0.42);

    task.pause();
    expect(task.status, Host4DownloadStatus.paused);
    expect(starter.last.pauseCount, 1);

    task.resume();
    expect(task.status, Host4DownloadStatus.downloading);
    expect(starter.last.resumeCount, 1);

    task.cancel();
    expect(task.status, Host4DownloadStatus.canceled);
    expect(starter.last.cancelCount, 1);
    await expectLater(task.result, throwsStateError);
  });

  test('creates independent active tasks for different URLs', () async {
    final firstUrl = Uri.parse('https://example.com/a.bin');
    final secondUrl = Uri.parse('https://example.com/b.bin');

    final first = await download.download(firstUrl);
    final second = await download.download(secondUrl);

    expect(second, isNot(same(first)));
    expect(second.taskKey, isNot(first.taskKey));
    expect(first.status, Host4DownloadStatus.downloading);
    expect(second.status, Host4DownloadStatus.downloading);
    expect(starter.started, hasLength(2));
  });

  test(
    'rejects concurrent different URL before startup IO can mutate files',
    () async {
      final firstUrl = Uri.parse('https://example.com/a.bin');
      final secondUrl = Uri.parse('https://example.com/b.bin');

      final firstFuture = download.download(firstUrl);

      final second = await download.download(secondUrl);

      final first = await firstFuture;
      expect(first.request.url, firstUrl);
      expect(second.request.url, secondUrl);
      expect(first.taskKey, isNot(second.taskKey));
    },
  );

  test('download(Uri) delegates to downloadRequest request flow', () async {
    final url = Uri.parse('https://example.com/a.bin');

    final first = await download.downloadRequest(
      Host4DownloadRequest(url: url),
    );
    final second = await download.download(url);

    expect(second, same(first));
    expect(first.taskKey, Host4DownloadRequest(url: url).taskKey);
    expect(starter.started, hasLength(1));
  });

  test(
    'force refresh reuses active task without canceling or deleting partial',
    () async {
      final url = Uri.parse('https://example.com/a.bin');
      final first = await download.download(url);
      final entry = await store.prepare(Host4DownloadRequest(url: url));
      await entry.partialFile.writeAsBytes([1, 2, 3]);

      final second = await download.downloadRequest(
        Host4DownloadRequest(url: url, forceRefresh: true),
      );

      expect(second, same(first));
      expect(starter.started, hasLength(1));
      expect(starter.last.cancelCount, 0);
      expect(await entry.partialFile.exists(), isTrue);
    },
  );

  test('force refresh deletes stale partial before starting fresh', () async {
    final url = Uri.parse('https://example.com/a.bin');
    final first = await download.download(url);
    await starter.last.writePartialBytes([1, 2, 3]);
    starter.last.fail(StateError('network'));
    await expectLater(first.result, throwsStateError);

    final second = await download.downloadRequest(
      Host4DownloadRequest(url: url, forceRefresh: true),
    );

    expect(second, isNot(same(first)));
    expect(starter.started, hasLength(2));
    expect(starter.started.last.resumePartial, isFalse);
  });

  test(
    'maxConcurrentDownloads queues extra tasks and pumps on completion',
    () async {
      download = Host4Download.debug(
        store: store,
        driver: driver,
        maxConcurrentDownloads: 1,
      );

      final first = await download.download(
        Uri.parse('https://example.com/a.bin'),
      );
      final second = await download.download(
        Uri.parse('https://example.com/b.bin'),
      );

      expect(first.status, Host4DownloadStatus.downloading);
      expect(second.status, Host4DownloadStatus.queued);
      expect(starter.started, hasLength(1));

      await starter.started[0].writeCompleteBytes([1, 2, 3]);
      starter.started[0].complete();
      await expectLater(first.result, completes);
      await _waitFor(() => starter.started.length == 2);

      expect(second.status, Host4DownloadStatus.downloading);
      expect(starter.started, hasLength(2));
      expect(starter.started[1].entry.request.url.path, '/b.bin');
    },
  );

  test(
    'public constructor passes maxConcurrentDownloads to third party manager',
    () {
      final manager = fdm.DownloadManager();
      final previousMaxConcurrentTasks = manager.maxConcurrentTasks;
      addTearDown(() {
        fdm.DownloadManager(maxConcurrentTasks: previousMaxConcurrentTasks);
      });
      fdm.DownloadManager(maxConcurrentTasks: 1);

      Host4Download(maxConcurrentDownloads: 4);

      expect(manager.maxConcurrentTasks, 4);
    },
  );

  test('cancel releases queue slot even when driver cancel throws', () async {
    final previousOnError = FlutterError.onError;
    final reportedErrors = <FlutterErrorDetails>[];
    FlutterError.onError = reportedErrors.add;
    addTearDown(() {
      FlutterError.onError = previousOnError;
    });
    download = Host4Download.debug(
      store: store,
      driver: driver,
      maxConcurrentDownloads: 1,
    );
    final first = await download.download(
      Uri.parse('https://example.com/a.bin'),
    );
    final second = await download.download(
      Uri.parse('https://example.com/b.bin'),
    );
    starter.started[0].throwOnCancel = true;

    first.cancel();
    await expectLater(first.result, throwsStateError);
    await _waitFor(() => starter.started.length == 2);

    expect(first.status, Host4DownloadStatus.canceled);
    expect(second.status, Host4DownloadStatus.downloading);
    expect(starter.started[1].entry.request.url.path, '/b.bin');
    expect(reportedErrors.single.exception, isA<StateError>());
  });

  test(
    'failed completion releases the queue slot and pumps next task',
    () async {
      download = Host4Download.debug(
        store: store,
        driver: driver,
        maxConcurrentDownloads: 1,
      );

      final first = await download.download(
        Uri.parse('https://example.com/a.bin'),
      );
      final second = await download.download(
        Uri.parse('https://example.com/b.bin'),
      );

      expect(first.status, Host4DownloadStatus.downloading);
      expect(second.status, Host4DownloadStatus.queued);
      expect(starter.started, hasLength(1));

      starter.started[0].complete();
      await expectLater(first.result, throwsStateError);
      await _waitFor(() => starter.started.length == 2);

      expect(first.status, Host4DownloadStatus.failed);
      expect(second.status, Host4DownloadStatus.downloading);
      expect(starter.started[1].entry.request.url.path, '/b.bin');
    },
  );

  test('one task failure does not change other active task status', () async {
    final first = await download.download(
      Uri.parse('https://example.com/a.bin'),
    );
    final second = await download.download(
      Uri.parse('https://example.com/b.bin'),
    );

    starter.started[0].fail(StateError('network'));
    await expectLater(first.result, throwsStateError);
    await Future<void>.delayed(Duration.zero);

    expect(first.status, Host4DownloadStatus.failed);
    expect(second.status, Host4DownloadStatus.downloading);
    expect(starter.started, hasLength(2));
  });

  test('task controls are isolated to their own driver handle', () async {
    final first = await download.download(
      Uri.parse('https://example.com/a.bin'),
    );
    final second = await download.download(
      Uri.parse('https://example.com/b.bin'),
    );

    first.pause();
    first.resume();
    first.cancel();
    await expectLater(first.result, throwsStateError);

    expect(starter.started[0].taskKey, first.taskKey);
    expect(starter.started[0].pauseCount, 1);
    expect(starter.started[0].resumeCount, 1);
    expect(starter.started[0].cancelCount, 1);
    expect(starter.started[1].taskKey, second.taskKey);
    expect(starter.started[1].pauseCount, 0);
    expect(starter.started[1].resumeCount, 0);
    expect(starter.started[1].cancelCount, 0);
    expect(second.status, Host4DownloadStatus.downloading);
  });

  test(
    'creates a new task for the same URL after a completed terminal task',
    () async {
      final url = Uri.parse('https://example.com/a.bin');
      final first = await download.download(url);
      await starter.last.writeCompleteBytes([1, 2, 3, 4]);
      starter.last.complete();
      await expectLater(first.result, completes);

      final second = await download.download(url);

      expect(second, isNot(same(first)));
      expect(second.status, Host4DownloadStatus.completed);
      expect(starter.started, hasLength(1));
      await expectLater(second.result, completes);
    },
  );

  test('completed task returns and persists observed sha256', () async {
    const expectedSha256 =
        '039058c6f2c0cb492c533b0a4d14ef77cc0f78abccced5287d84a1a2011cfb81';
    final url = Uri.parse('https://example.com/a.bin');
    final task = await download.downloadRequest(
      Host4DownloadRequest(url: url, expectedSha256: expectedSha256),
    );

    await starter.last.writeCompleteBytes([1, 2, 3]);
    starter.last.complete();
    final file = await task.result;
    final records = await download.list();

    expect(file.observedSha256, expectedSha256);
    expect(file.expectedSha256, expectedSha256);
    expect(file.verified, isTrue);
    expect(records.single.observedSha256, expectedSha256);
    expect(records.single.expectedSha256, expectedSha256);
  });

  test(
    'sha256 mismatch fails task without returning a firmware file',
    () async {
      final url = Uri.parse('https://example.com/a.bin');
      final task = await download.downloadRequest(
        Host4DownloadRequest(url: url, expectedSha256: 'f' * 64),
      );

      await starter.last.writeCompleteBytes([1, 2, 3]);
      starter.last.complete();

      await expectLater(task.result, throwsStateError);
      expect(task.status, Host4DownloadStatus.failed);
      final records = await download.list();
      expect(records.single.status, Host4DownloadStatus.failed);
      expect(
        records.single.observedSha256,
        '039058c6f2c0cb492c533b0a4d14ef77cc0f78abccced5287d84a1a2011cfb81',
      );
    },
  );

  test(
    'expected size mismatch fails task without returning a firmware file',
    () async {
      final url = Uri.parse('https://example.com/a.bin');
      final task = await download.downloadRequest(
        Host4DownloadRequest(url: url, expectedSize: 4),
      );

      await starter.last.writeCompleteBytes([1, 2, 3]);
      starter.last.complete();

      await expectLater(task.result, throwsStateError);
      expect(task.status, Host4DownloadStatus.failed);
      final records = await download.list();
      expect(records.single.status, Host4DownloadStatus.failed);
      expect(records.single.size, 3);
    },
  );

  test('same active URL rejects different validation metadata', () async {
    final url = Uri.parse('https://example.com/a.bin');
    final first = await download.downloadRequest(
      Host4DownloadRequest(url: url),
    );

    await expectLater(
      () => download.downloadRequest(
        Host4DownloadRequest(url: url, expectedSha256: 'a' * 64),
      ),
      throwsStateError,
    );

    expect(first.status, Host4DownloadStatus.downloading);
    expect(starter.started, hasLength(1));
  });

  test(
    'resumes an existing partial file after a failed terminal task',
    () async {
      final url = Uri.parse('https://example.com/a.bin');
      final first = await download.download(url);
      await starter.last.writePartialBytes([1, 2, 3]);
      starter.last.fail(StateError('network'));
      await expectLater(first.result, throwsStateError);

      final second = await download.download(url);

      expect(second, isNot(same(first)));
      expect(starter.started, hasLength(2));
      expect(starter.started.last.resumePartial, isTrue);
      expect(second.status, Host4DownloadStatus.downloading);
    },
  );

  test('canceled task does not return a downloadable firmware file', () async {
    final task = await download.download(
      Uri.parse('https://example.com/a.bin'),
    );

    task.cancel();

    expect(task.status, Host4DownloadStatus.canceled);
    await expectLater(task.result, throwsStateError);
    await _waitForAsync(() async {
      final records = await download.list();
      return records.length == 1 &&
          records.single.status == Host4DownloadStatus.canceled;
    });
  });

  test(
    'driver canceled completion does not overwrite canceled manifest as failed',
    () async {
      final task = await download.download(
        Uri.parse('https://example.com/a.bin'),
      );

      task.cancel();
      starter.last.fail(StateError('late canceled notification'));
      await expectLater(task.result, throwsStateError);

      await _waitForAsync(() async {
        final records = await download.list();
        return records.length == 1 &&
            records.single.status == Host4DownloadStatus.canceled;
      });

      expect(task.status, Host4DownloadStatus.canceled);
    },
  );

  test('driver failure does not return a downloadable firmware file', () async {
    final task = await download.download(
      Uri.parse('https://example.com/a.bin'),
    );

    starter.last.fail(StateError('download failed'));

    await expectLater(task.result, throwsStateError);
    expect(task.status, Host4DownloadStatus.failed);
  });

  test(
    'real HTTP failure completes task result without leaking uncaught errors',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      unawaited(
        server.forEach((request) async {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
        }),
      );

      final tempRoot = await Directory.systemTemp.createTemp(
        'host4_download_real_failure_',
      );
      addTearDown(() async {
        if (await tempRoot.exists()) {
          await tempRoot.delete(recursive: true);
        }
      });

      final realDownload = Host4Download.debug(
        store: Host4DownloadStore(rootDirectoryProvider: () async => tempRoot),
        driver: FlutterDownloadManagerDriver(),
      );
      final url = Uri(
        scheme: 'http',
        host: InternetAddress.loopbackIPv4.address,
        port: server.port,
        path: '/missing.bin',
      );
      final task = await realDownload.download(url);
      Object? resultError;
      try {
        await task.result.timeout(const Duration(seconds: 5));
      } catch (error) {
        resultError = error;
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(resultError, isNotNull);
      expect(resultError, isNot(isA<TimeoutException>()));
      expect(task.status, Host4DownloadStatus.failed);
    },
  );

  test(
    'clear task is rejected for active tasks without deleting files or manifest',
    () async {
      final url = Uri.parse('https://example.com/a.bin');
      final task = await download.download(url);
      final entry = await store.prepare(Host4DownloadRequest(url: url));
      await entry.partialFile.writeAsBytes([1, 2, 3]);
      await store.writeManifest(entry);

      await expectLater(() => download.clear(task.taskKey), throwsStateError);

      expect(await entry.partialFile.exists(), isTrue);
      expect(await entry.manifestFile.exists(), isTrue);
    },
  );

  test('clear task is rejected while a task is still queued', () async {
    download = Host4Download.debug(
      store: store,
      driver: driver,
      maxConcurrentDownloads: 1,
    );
    await download.download(Uri.parse('https://example.com/a.bin'));
    final queued = await download.download(
      Uri.parse('https://example.com/b.bin'),
    );

    await expectLater(() => download.clear(queued.taskKey), throwsStateError);

    expect(queued.status, Host4DownloadStatus.queued);
    expect(starter.started, hasLength(1));
  });

  test(
    'clear is rejected while a task is paused without deleting files',
    () async {
      final url = Uri.parse('https://example.com/a.bin');
      final task = await download.download(url);
      final entry = await store.prepare(Host4DownloadRequest(url: url));
      await entry.partialFile.writeAsBytes([1, 2, 3]);
      await store.writeManifest(entry);

      task.pause();
      await expectLater(() => download.clear(task.taskKey), throwsStateError);

      expect(task.status, Host4DownloadStatus.paused);
      expect(await entry.partialFile.exists(), isTrue);
      expect(await entry.manifestFile.exists(), isTrue);
    },
  );

  test(
    'clear after terminal task deletes complete, partial, and manifest',
    () async {
      final url = Uri.parse('https://example.com/a.bin');
      final task = await download.download(url);
      await starter.last.writeCompleteBytes([1, 2, 3]);
      await starter.last.writePartialBytes([4]);
      starter.last.complete();
      final file = await task.result;
      final entry = await store.prepare(Host4DownloadRequest(url: url));
      expect(File(file.localPath).existsSync(), isTrue);
      expect(await entry.partialFile.exists(), isTrue);

      await download.clear(task.taskKey);

      expect(await entry.file.exists(), isFalse);
      expect(await entry.partialFile.exists(), isFalse);
      expect(await entry.manifestFile.exists(), isFalse);
      expect(File(file.localPath).existsSync(), isFalse);
      expect(task.status, Host4DownloadStatus.completed);

      final next = await download.download(url);

      expect(next, isNot(same(task)));
      expect(next.status, Host4DownloadStatus.downloading);
      expect(starter.started, hasLength(2));
    },
  );

  test(
    'clear after failed or canceled terminal tasks deletes managed files',
    () async {
      final failedUrl = Uri.parse('https://example.com/failed.bin');
      final failedTask = await download.download(failedUrl);
      await starter.last.writePartialBytes([1, 2]);
      starter.last.fail(StateError('network'));
      await expectLater(failedTask.result, throwsStateError);
      final failedEntry = await store.prepare(
        Host4DownloadRequest(url: failedUrl),
      );
      await failedEntry.file.writeAsBytes([3, 4]);
      await failedEntry.partialFile.writeAsBytes([5]);
      await store.writeManifest(
        failedEntry,
        status: Host4DownloadStatus.failed,
      );

      await download.clear(failedTask.taskKey);

      expect(await failedEntry.file.exists(), isFalse);
      expect(await failedEntry.partialFile.exists(), isFalse);
      expect(await failedEntry.manifestFile.exists(), isFalse);

      final canceledUrl = Uri.parse('https://example.com/canceled.bin');
      final canceledTask = await download.download(canceledUrl);
      await starter.last.writePartialBytes([6, 7]);
      canceledTask.cancel();
      await expectLater(canceledTask.result, throwsStateError);
      final canceledEntry = await store.prepare(
        Host4DownloadRequest(url: canceledUrl),
      );
      await canceledEntry.file.writeAsBytes([8, 9]);
      await canceledEntry.partialFile.writeAsBytes([10]);
      await store.writeManifest(
        canceledEntry,
        status: Host4DownloadStatus.canceled,
      );

      await download.clear(canceledTask.taskKey);

      expect(await canceledEntry.file.exists(), isFalse);
      expect(await canceledEntry.partialFile.exists(), isFalse);
      expect(await canceledEntry.manifestFile.exists(), isFalse);
    },
  );

  test(
    'clearCompleted removes only terminal records and keeps active tasks',
    () async {
      final completedUrl = Uri.parse('https://example.com/completed.bin');
      final completedTask = await download.download(completedUrl);
      await starter.last.writeCompleteBytes([1, 2, 3]);
      starter.last.complete();
      await expectLater(completedTask.result, completes);

      final activeTask = await download.download(
        Uri.parse('https://example.com/active.bin'),
      );
      final activeEntry = await store.prepare(
        Host4DownloadRequest(url: activeTask.request.url),
      );
      await activeEntry.partialFile.writeAsBytes([4, 5]);

      final removed = await download.clearCompleted();

      expect(removed, 1);
      expect(await download.list(), hasLength(1));
      expect((await download.list()).single.taskKey, activeTask.taskKey);
      expect(await activeEntry.partialFile.exists(), isTrue);
    },
  );

  test(
    'clearCompleted skips registry active task even when manifest is terminal',
    () async {
      final url = Uri.parse('https://example.com/reused.bin');
      final task = await download.download(url);
      final entry = await store.prepare(Host4DownloadRequest(url: url));
      await entry.partialFile.writeAsBytes([1, 2, 3], flush: true);
      await store.writeManifest(entry, status: Host4DownloadStatus.failed);
      final removed = await download.clearCompleted();

      expect(removed, 0);
      expect(await entry.manifestFile.exists(), isTrue);
      expect((await download.list()).single.taskKey, task.taskKey);
    },
  );

  test('enforceStorageLimit delegates cleanup through public facade', () async {
    final completedUrl = Uri.parse('https://example.com/completed.bin');
    final completedTask = await download.download(completedUrl);
    await starter.last.writeCompleteBytes([1, 2, 3, 4]);
    starter.last.complete();
    await expectLater(completedTask.result, completes);
    final activeTask = await download.download(
      Uri.parse('https://example.com/active.bin'),
    );
    final activeEntry = await store.prepare(
      Host4DownloadRequest(url: activeTask.request.url),
    );
    await activeEntry.partialFile.writeAsBytes([5, 6, 7, 8], flush: true);

    final result = await download.enforceStorageLimit(maxBytes: 1);

    expect(result.limitBytes, 1);
    expect(result.deletedTaskKeys, <String>[completedTask.taskKey]);
    expect(result.deletedCount, 1);
    expect(result.afterBytes, lessThanOrEqualTo(result.beforeBytes));
    expect(await activeEntry.partialFile.exists(), isTrue);
  });

  test(
    'enforceStorageLimit skips registry active task even when manifest is terminal',
    () async {
      final url = Uri.parse('https://example.com/reused.bin');
      final task = await download.download(url);
      final entry = await store.prepare(Host4DownloadRequest(url: url));
      await entry.partialFile.writeAsBytes([1, 2, 3, 4], flush: true);
      await store.writeManifest(entry, status: Host4DownloadStatus.failed);
      final result = await download.enforceStorageLimit(maxBytes: 1);

      expect(result.deletedTaskKeys, isNot(contains(task.taskKey)));
      expect(await entry.manifestFile.exists(), isTrue);
    },
  );

  test('list returns persistent records with active status overlay', () async {
    download = Host4Download.debug(
      store: store,
      driver: driver,
      maxConcurrentDownloads: 1,
    );
    final first = await download.download(
      Uri.parse('https://example.com/a.bin'),
    );
    final second = await download.download(
      Uri.parse('https://example.com/b.bin'),
    );
    starter.last.emitProgress(0.5);
    await Future<void>.delayed(Duration.zero);

    final records = await download.list();

    expect(
      records.map((record) => record.taskKey),
      containsAll(<String>[first.taskKey, second.taskKey]),
    );
    expect(
      records.singleWhere((record) => record.taskKey == first.taskKey).status,
      Host4DownloadStatus.downloading,
    );
    expect(
      records.singleWhere((record) => record.taskKey == second.taskKey).status,
      Host4DownloadStatus.queued,
    );
  });
}

Future<void> _waitFor(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 1),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw StateError('Timed out waiting for condition.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

Future<void> _waitForAsync(
  Future<bool> Function() condition, {
  Duration timeout = const Duration(seconds: 1),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!await condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw StateError('Timed out waiting for async condition.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

class _FakeStarter {
  final started = <_StartedDownload>[];

  _StartedDownload get last => started.last;

  Future<Host4DownloadDriverHandle> start(
    Host4DownloadStoreEntry entry, {
    required bool resumePartial,
  }) async {
    final download = _StartedDownload(entry, resumePartial);
    started.add(download);
    return download;
  }
}

class _StartedDownload implements Host4DownloadDriverHandle {
  _StartedDownload(this.entry, this.resumePartial);

  final Host4DownloadStoreEntry entry;
  final bool resumePartial;
  final _progressController = StreamController<double>.broadcast();
  final _done = Completer<void>();
  var pauseCount = 0;
  var resumeCount = 0;
  var cancelCount = 0;
  var throwOnCancel = false;

  @override
  String get taskKey => entry.taskKey;

  @override
  Stream<double> get progress => _progressController.stream;

  @override
  Future<void> get done => _done.future;

  void emitProgress(double progress) {
    _progressController.add(progress);
  }

  Future<void> writeCompleteBytes(List<int> bytes) async {
    await entry.file.writeAsBytes(bytes);
  }

  Future<void> writePartialBytes(List<int> bytes) async {
    await entry.partialFile.writeAsBytes(bytes);
  }

  void complete() {
    _done.complete();
  }

  void fail(Object error) {
    _done.completeError(error);
  }

  @override
  Future<void> pause() async {
    pauseCount += 1;
  }

  @override
  Future<void> resume() async {
    resumeCount += 1;
  }

  @override
  Future<void> cancel() async {
    cancelCount += 1;
    if (throwOnCancel) {
      throw StateError('cancel failed');
    }
  }
}
