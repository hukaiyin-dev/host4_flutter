import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_download/host4_flutter_download.dart';
import 'package:host4_flutter_download/src/storage/host4_download_manifest.dart';
import 'package:host4_flutter_download/src/storage/host4_download_store.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempRoot;
  late Host4DownloadStore store;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('host4_download_store_');
    store = Host4DownloadStore(rootDirectoryProvider: () async => tempRoot);
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  test(
    'prepares private task paths and writes R002 index and manifest',
    () async {
      final request = Host4DownloadRequest(
        url: Uri.parse('https://example.com/firmware/OTA GDF-G911405.bin'),
        expectedSize: 42,
        expectedSha256: 'a' * 64,
      );

      final entry = await store.prepare(request);

      final downloadsPath = p.join(tempRoot.path, 'host4', 'downloads');
      final taskPath = p.join(downloadsPath, 'tasks', request.taskKey);
      expect(entry.directory.path, taskPath);
      expect(entry.fileName, 'OTA_GDF-G911405.bin');
      expect(entry.file.path, p.join(taskPath, entry.fileName));
      expect(entry.partialFile.path, '${entry.file.path}.partial');
      expect(entry.manifestFile.path, p.join(taskPath, 'manifest.json'));
      expect(
        await File(p.join(downloadsPath, 'downloads.json')).exists(),
        isTrue,
      );
      expect(await entry.manifestFile.exists(), isTrue);

      final manifest = Host4DownloadManifest.fromJson(
        jsonDecode(await entry.manifestFile.readAsString())
            as Map<String, Object?>,
      );
      expect(manifest.schemaVersion, 2);
      expect(manifest.taskKey, request.taskKey);
      expect(manifest.url, request.url.toString());
      expect(manifest.fileName, 'OTA_GDF-G911405.bin');
      expect(manifest.status, Host4DownloadStatus.queued);
      expect(manifest.expectedSize, 42);
      expect(manifest.expectedSha256, 'a' * 64);
      expect(manifest.observedSha256, isNull);
      expect(manifest.completedAt, isNull);
      expect(manifest.updatedAt, isNotNull);
    },
  );

  test('manifest JSON round trips all contract fields', () {
    final updatedAt = DateTime.utc(2026, 7, 23, 8, 0);
    final completedAt = DateTime.utc(2026, 7, 23, 8, 1);
    final manifest = Host4DownloadManifest(
      schemaVersion: 2,
      taskKey: 'b' * 64,
      url: 'https://example.com/a.bin',
      fileName: 'a.bin',
      status: Host4DownloadStatus.completed,
      expectedSize: 12,
      expectedSha256: 'c' * 64,
      observedSha256: 'd' * 64,
      completedAt: completedAt,
      updatedAt: updatedAt,
    );

    final roundTrip = Host4DownloadManifest.fromJson(manifest.toJson());

    expect(roundTrip.schemaVersion, 2);
    expect(roundTrip.taskKey, 'b' * 64);
    expect(roundTrip.url, 'https://example.com/a.bin');
    expect(roundTrip.fileName, 'a.bin');
    expect(roundTrip.status, Host4DownloadStatus.completed);
    expect(roundTrip.expectedSize, 12);
    expect(roundTrip.expectedSha256, 'c' * 64);
    expect(roundTrip.observedSha256, 'd' * 64);
    expect(roundTrip.completedAt, completedAt);
    expect(roundTrip.updatedAt, updatedAt);
  });

  test(
    'listRecords returns Host4 records without exposing storage paths',
    () async {
      final request = Host4DownloadRequest(
        url: Uri.parse('https://example.com/a.bin'),
      );
      final entry = await store.prepare(request);
      await entry.file.writeAsBytes([1, 2, 3]);
      await store.writeManifest(entry, status: Host4DownloadStatus.completed);

      final records = await store.listRecords();

      expect(records, hasLength(1));
      expect(records.single, isA<Host4DownloadRecord>());
      expect(records.single.taskKey, request.taskKey);
      expect(records.single.url, request.url);
      expect(records.single.fileName, 'a.bin');
      expect(records.single.status, Host4DownloadStatus.completed);
      expect(records.single.size, 3);
      expect(records.single.localPath, entry.file.path);
    },
  );

  test(
    'migrates R001 current.json into R002 index and task manifest',
    () async {
      final downloads = Directory(p.join(tempRoot.path, 'host4', 'downloads'));
      await downloads.create(recursive: true);
      await File(p.join(downloads.path, 'current.json')).writeAsString(
        jsonEncode(<String, String>{
          'url': 'https://example.com/legacy.bin',
          'fileName': 'legacy.bin',
        }),
      );
      final legacyFile = File(p.join(downloads.path, 'legacy.bin'));
      await legacyFile.writeAsBytes([7, 8, 9]);

      final records = await store.listRecords();

      final request = Host4DownloadRequest(
        url: Uri.parse('https://example.com/legacy.bin'),
      );
      final taskManifest = File(
        p.join(downloads.path, 'tasks', request.taskKey, 'manifest.json'),
      );
      final migratedFile = File(
        p.join(downloads.path, 'tasks', request.taskKey, 'legacy.bin'),
      );

      expect(records, hasLength(1));
      expect(records.single.taskKey, request.taskKey);
      expect(records.single.fileName, 'legacy.bin');
      expect(records.single.status, Host4DownloadStatus.completed);
      expect(
        await File(p.join(downloads.path, 'downloads.json')).exists(),
        isTrue,
      );
      expect(await taskManifest.exists(), isTrue);
      expect(await migratedFile.exists(), isTrue);
      expect(await migratedFile.readAsBytes(), [7, 8, 9]);
    },
  );

  test(
    'migration failure cleans only managed files inside downloads',
    () async {
      final downloads = Directory(p.join(tempRoot.path, 'host4', 'downloads'));
      await downloads.create(recursive: true);
      final outside = File(p.join(tempRoot.path, 'host4', 'outside.bin'));
      await outside.create(recursive: true);
      await outside.writeAsBytes([1]);
      await File(p.join(downloads.path, 'current.json')).writeAsString('{bad');
      await File(
        p.join(downloads.path, 'downloads.json'),
      ).writeAsString('{bad');
      await File(p.join(downloads.path, 'legacy.bin')).writeAsBytes([3]);
      await File(p.join(downloads.path, 'orphan.partial')).writeAsBytes([2]);
      final existing = await store.prepare(
        Host4DownloadRequest(url: Uri.parse('https://example.com/kept.bin')),
      );
      await store.writeManifest(
        existing,
        status: Host4DownloadStatus.completed,
      );
      await File(p.join(downloads.path, 'current.json')).writeAsString('{bad');

      final records = await store.listRecords();

      expect(records.map((record) => record.fileName), ['kept.bin']);
      expect(await outside.exists(), isTrue);
      expect(
        await File(p.join(downloads.path, 'current.json')).exists(),
        isFalse,
      );
      expect(
        await File(p.join(downloads.path, 'legacy.bin')).exists(),
        isFalse,
      );
      expect(
        await File(p.join(downloads.path, 'orphan.partial')).exists(),
        isFalse,
      );
      expect(await existing.manifestFile.exists(), isTrue);
      expect(
        await File(p.join(downloads.path, 'downloads.json')).exists(),
        isTrue,
      );
    },
  );

  test('corrupt index is rebuilt from valid task manifests', () async {
    final good = await store.prepare(
      Host4DownloadRequest(url: Uri.parse('https://example.com/good.bin')),
    );
    await good.file.writeAsBytes([1, 2, 3]);
    await store.writeManifest(good, status: Host4DownloadStatus.completed);
    await File(
      p.join(tempRoot.path, 'host4', 'downloads', 'downloads.json'),
    ).writeAsString('{bad');

    final records = await store.listRecords();

    expect(records.map((record) => record.fileName), ['good.bin']);
    expect(records.single.status, Host4DownloadStatus.completed);
    expect(await good.manifestFile.exists(), isTrue);
  });

  test('corrupt task manifest removes only that task from records', () async {
    final good = await store.prepare(
      Host4DownloadRequest(url: Uri.parse('https://example.com/good.bin')),
    );
    await store.writeManifest(good);
    final bad = await store.prepare(
      Host4DownloadRequest(url: Uri.parse('https://example.com/bad.bin')),
    );
    await bad.manifestFile.writeAsString('{bad');
    await bad.file.writeAsBytes([1]);

    final records = await store.listRecords();

    expect(records.map((record) => record.fileName), ['good.bin']);
    expect(await good.manifestFile.exists(), isTrue);
    expect(await bad.manifestFile.exists(), isFalse);
    expect(await bad.file.exists(), isFalse);
  });

  test(
    'clearTask deletes terminal task files, manifest, and index record',
    () async {
      final request = Host4DownloadRequest(
        url: Uri.parse('https://example.com/a.bin'),
      );
      final entry = await store.prepare(request);
      await entry.file.writeAsBytes([1]);
      await entry.partialFile.writeAsBytes([2]);
      await store.writeManifest(entry, status: Host4DownloadStatus.completed);

      await store.clearTask(request.taskKey);

      expect(await entry.file.exists(), isFalse);
      expect(await entry.partialFile.exists(), isFalse);
      expect(await entry.manifestFile.exists(), isFalse);
      expect(await store.listRecords(), isEmpty);
    },
  );

  test('clearTask rejects non-terminal task without deleting files', () async {
    for (final status in <Host4DownloadStatus>[
      Host4DownloadStatus.queued,
      Host4DownloadStatus.downloading,
      Host4DownloadStatus.paused,
    ]) {
      final request = Host4DownloadRequest(
        url: Uri.parse('https://example.com/$status.bin'),
      );
      final entry = await store.prepare(request);
      await entry.file.writeAsBytes([1]);
      await entry.partialFile.writeAsBytes([2]);
      await store.writeManifest(entry, status: status);

      await expectLater(
        () => store.clearTask(request.taskKey),
        throwsStateError,
      );

      expect(await entry.file.exists(), isTrue);
      expect(await entry.partialFile.exists(), isTrue);
      expect(await entry.manifestFile.exists(), isTrue);
    }
  });

  test('clearTask rejects invalid taskKey without touching storage', () async {
    final request = Host4DownloadRequest(
      url: Uri.parse('https://example.com/a.bin'),
    );
    final entry = await store.prepare(request);
    await entry.file.writeAsBytes([1]);
    await store.writeManifest(entry, status: Host4DownloadStatus.completed);

    await expectLater(() => store.clearTask('../a.bin'), throwsArgumentError);

    expect(await entry.file.exists(), isTrue);
    expect(await entry.manifestFile.exists(), isTrue);
    expect((await store.listRecords()).single.taskKey, request.taskKey);
  });

  test('clearTerminalRecords removes only terminal records', () async {
    final completed = await store.prepare(
      Host4DownloadRequest(url: Uri.parse('https://example.com/completed.bin')),
    );
    await completed.file.writeAsBytes([1]);
    await store.writeManifest(completed, status: Host4DownloadStatus.completed);
    final failed = await store.prepare(
      Host4DownloadRequest(url: Uri.parse('https://example.com/failed.bin')),
    );
    await failed.partialFile.writeAsBytes([2]);
    await store.writeManifest(failed, status: Host4DownloadStatus.failed);
    final active = await store.prepare(
      Host4DownloadRequest(url: Uri.parse('https://example.com/active.bin')),
    );
    await active.partialFile.writeAsBytes([3]);
    await store.writeManifest(active, status: Host4DownloadStatus.downloading);
    final canceled = await store.prepare(
      Host4DownloadRequest(url: Uri.parse('https://example.com/canceled.bin')),
    );
    await canceled.partialFile.writeAsBytes([4]);
    await store.writeManifest(canceled, status: Host4DownloadStatus.canceled);
    final paused = await store.prepare(
      Host4DownloadRequest(url: Uri.parse('https://example.com/paused.bin')),
    );
    await paused.partialFile.writeAsBytes([5]);
    await store.writeManifest(paused, status: Host4DownloadStatus.paused);

    final removed = await store.clearTerminalRecords();

    expect(removed, 3);
    expect(await completed.manifestFile.exists(), isFalse);
    expect(await failed.manifestFile.exists(), isFalse);
    expect(await canceled.manifestFile.exists(), isFalse);
    expect(await active.manifestFile.exists(), isTrue);
    expect(await active.partialFile.exists(), isTrue);
    expect(await paused.manifestFile.exists(), isTrue);
    expect(await paused.partialFile.exists(), isTrue);
    expect(
      (await store.listRecords()).map((record) => record.taskKey),
      containsAll(<String>[active.taskKey, paused.taskKey]),
    );
  });

  test(
    'enforceStorageLimit deletes oldest terminal records until under limit',
    () async {
      final oldest = await _completedEntry(
        store,
        Uri.parse('https://example.com/oldest.bin'),
        fileBytes: 1024,
      );
      await _writeManifestJson(
        oldest,
        status: Host4DownloadStatus.completed,
        completedAt: DateTime.utc(2026, 7, 20),
        updatedAt: DateTime.utc(2026, 7, 21),
      );
      final noCompletedAt = await _completedEntry(
        store,
        Uri.parse('https://example.com/no_completed_at.bin'),
        fileBytes: 1024,
      );
      await _writeManifestJson(
        noCompletedAt,
        status: Host4DownloadStatus.failed,
        completedAt: null,
        updatedAt: DateTime.utc(2026, 7, 22),
      );
      final newest = await _completedEntry(
        store,
        Uri.parse('https://example.com/newest.bin'),
        fileBytes: 1,
      );
      await _writeManifestJson(
        newest,
        status: Host4DownloadStatus.completed,
        completedAt: DateTime.utc(2026, 7, 23),
        updatedAt: DateTime.utc(2026, 7, 23, 1),
      );

      final result = await store.enforceStorageLimit(maxBytes: 1500);

      expect(result.limitBytes, 1500);
      expect(result.beforeBytes, greaterThanOrEqualTo(2049));
      expect(result.afterBytes, lessThanOrEqualTo(1500));
      expect(result.deletedTaskKeys, <String>[
        oldest.taskKey,
        noCompletedAt.taskKey,
      ]);
      expect(result.deletedCount, 2);
      expect(await oldest.manifestFile.exists(), isFalse);
      expect(await noCompletedAt.manifestFile.exists(), isFalse);
      expect(await newest.manifestFile.exists(), isTrue);
      expect(await newest.file.exists(), isTrue);
    },
  );

  test(
    'enforceStorageLimit sorts same timestamp terminal records by task key',
    () async {
      final sameTimestamp = DateTime.utc(2026, 7, 23);
      final first = await _completedEntry(
        store,
        Uri.parse('https://example.com/a.bin'),
        fileBytes: 1024,
      );
      await _writeManifestJson(
        first,
        status: Host4DownloadStatus.completed,
        completedAt: sameTimestamp,
        updatedAt: sameTimestamp,
      );
      final second = await _completedEntry(
        store,
        Uri.parse('https://example.com/b.bin'),
        fileBytes: 1024,
      );
      await _writeManifestJson(
        second,
        status: Host4DownloadStatus.completed,
        completedAt: sameTimestamp,
        updatedAt: sameTimestamp,
      );
      final expectedOrder = <String>[first.taskKey, second.taskKey]..sort();

      final result = await store.enforceStorageLimit(maxBytes: 1);

      expect(result.deletedTaskKeys, expectedOrder);
    },
  );

  test(
    'enforceStorageLimit rejects non-positive limits without side effects',
    () async {
      final entry = await _completedEntry(
        store,
        Uri.parse('https://example.com/keep.bin'),
        fileBytes: 2,
      );

      await expectLater(
        store.enforceStorageLimit(maxBytes: 0),
        throwsArgumentError,
      );

      expect(await entry.manifestFile.exists(), isTrue);
      expect(await entry.file.exists(), isTrue);
    },
  );

  test(
    'enforceStorageLimit skips active and paused records without deleting external files',
    () async {
      final downloads = Directory(p.join(tempRoot.path, 'host4', 'downloads'));
      final external = File(p.join(tempRoot.path, 'business.bin'));
      await external.writeAsBytes([9, 9, 9, 9, 9], flush: true);
      final active = await store.prepare(
        Host4DownloadRequest(url: Uri.parse('https://example.com/active.bin')),
      );
      await active.partialFile.writeAsBytes([1, 2, 3, 4], flush: true);
      await store.writeManifest(
        active,
        status: Host4DownloadStatus.downloading,
      );
      final paused = await store.prepare(
        Host4DownloadRequest(url: Uri.parse('https://example.com/paused.bin')),
      );
      await paused.partialFile.writeAsBytes([5, 6, 7, 8], flush: true);
      await store.writeManifest(paused, status: Host4DownloadStatus.paused);

      final result = await store.enforceStorageLimit(maxBytes: 1);

      expect(result.beforeBytes, await _directorySize(downloads));
      expect(result.afterBytes, result.beforeBytes);
      expect(result.deletedCount, 0);
      expect(result.deletedTaskKeys, isEmpty);
      expect(await active.partialFile.exists(), isTrue);
      expect(await paused.partialFile.exists(), isTrue);
      expect(await external.exists(), isTrue);
    },
  );

  test('enforceStorageLimit returns no-op result below limit', () async {
    final entry = await _completedEntry(
      store,
      Uri.parse('https://example.com/small.bin'),
      fileBytes: 2,
    );

    final result = await store.enforceStorageLimit(maxBytes: 1024);

    expect(result.limitBytes, 1024);
    expect(result.beforeBytes, result.afterBytes);
    expect(result.deletedCount, 0);
    expect(result.deletedTaskKeys, isEmpty);
    expect(await entry.manifestFile.exists(), isTrue);
  });

  test('uses a safe fallback name for empty or dangerous URL paths', () async {
    final entry = await store.prepare(
      Host4DownloadRequest(url: Uri.parse('https://example.com/')),
    );
    final dangerous = await store.prepare(
      Host4DownloadRequest(
        url: Uri.parse('https://example.com/a/b/../..//?#fragment'),
      ),
    );

    expect(entry.fileName, 'firmware.bin');
    expect(dangerous.fileName, 'firmware.bin');
  });
}

Future<Host4DownloadStoreEntry> _completedEntry(
  Host4DownloadStore store,
  Uri url, {
  required int fileBytes,
}) async {
  final entry = await store.prepare(Host4DownloadRequest(url: url));
  await entry.file.writeAsBytes(List<int>.filled(fileBytes, 1), flush: true);
  await store.writeManifest(entry, status: Host4DownloadStatus.completed);
  return entry;
}

Future<void> _writeManifestJson(
  Host4DownloadStoreEntry entry, {
  required Host4DownloadStatus status,
  required DateTime? completedAt,
  required DateTime updatedAt,
}) async {
  await entry.manifestFile.writeAsString(
    jsonEncode(<String, Object?>{
      'schemaVersion': 2,
      'taskKey': entry.taskKey,
      'url': entry.url.toString(),
      'fileName': entry.fileName,
      'status': status.name,
      'expectedSize': null,
      'expectedSha256': null,
      'observedSha256': null,
      'completedAt': completedAt?.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    }),
  );
}

Future<int> _directorySize(Directory directory) async {
  var total = 0;
  if (!await directory.exists()) {
    return 0;
  }
  await for (final entity in directory.list(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is File) {
      total += await entity.length();
    }
  }
  return total;
}
