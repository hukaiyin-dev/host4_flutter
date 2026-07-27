import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:host4_flutter_download/host4_flutter_download.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'host4_download_manifest.dart';

typedef Host4DownloadRootDirectoryProvider = Future<Directory> Function();

class Host4DownloadStore {
  Host4DownloadStore({
    Host4DownloadRootDirectoryProvider? rootDirectoryProvider,
  }) : _rootDirectoryProvider =
           rootDirectoryProvider ?? getApplicationSupportDirectory;

  final Host4DownloadRootDirectoryProvider _rootDirectoryProvider;

  Future<Host4DownloadStoreEntry> prepare(Host4DownloadRequest request) async {
    final downloads = await _downloadsDirectory();
    await downloads.create(recursive: true);
    await migrateCurrentIfNeeded();

    final index = await _readIndex(downloads);
    final taskDirectory = Directory(
      p.join(downloads.path, 'tasks', request.taskKey),
    );
    await taskDirectory.create(recursive: true);

    final manifest = await _readManifest(_manifestFile(taskDirectory));
    final fileName = manifest?.fileName ?? _safeFileName(request.url);
    final entry = Host4DownloadStoreEntry(
      request: request,
      directory: taskDirectory,
      fileName: fileName,
      file: File(p.join(taskDirectory.path, fileName)),
      partialFile: File(p.join(taskDirectory.path, '$fileName.partial')),
      manifestFile: _manifestFile(taskDirectory),
    );

    await _writeIndex(downloads, {
      ...index,
      request.taskKey: _IndexRecord(
        taskKey: request.taskKey,
        url: request.url.toString(),
        fileName: fileName,
        updatedAt: DateTime.now().toUtc(),
      ),
    });

    if (manifest == null) {
      await writeManifest(entry);
    }
    return entry;
  }

  Future<List<Host4DownloadRecord>> listRecords() async {
    final downloads = await _downloadsDirectory();
    if (!await downloads.exists()) {
      return const <Host4DownloadRecord>[];
    }
    await migrateCurrentIfNeeded();

    final index = await _readIndex(downloads);
    final records = <Host4DownloadRecord>[];
    final repaired = Map<String, _IndexRecord>.of(index);

    for (final taskKey in index.keys) {
      final taskDirectory = Directory(p.join(downloads.path, 'tasks', taskKey));
      final manifestFile = _manifestFile(taskDirectory);
      final manifest = await _readManifest(manifestFile);
      if (manifest == null || manifest.taskKey != taskKey) {
        await _deleteTaskDirectory(taskDirectory);
        repaired.remove(taskKey);
        continue;
      }

      final file = File(p.join(taskDirectory.path, manifest.fileName));
      records.add(
        Host4DownloadRecord(
          taskKey: manifest.taskKey,
          url: Uri.parse(manifest.url),
          fileName: manifest.fileName,
          status: manifest.status,
          size: await file.exists() ? await file.length() : null,
          expectedSha256: manifest.expectedSha256,
          observedSha256: manifest.observedSha256,
          updatedAt: manifest.updatedAt,
          localPath: await file.exists() ? file.path : null,
          completedAt: manifest.completedAt,
        ),
      );
    }

    if (repaired.length != index.length) {
      await _writeIndex(downloads, repaired);
    }
    return records;
  }

  Future<void> writeManifest(
    Host4DownloadStoreEntry entry, {
    Host4DownloadStatus status = Host4DownloadStatus.queued,
    String? observedSha256,
  }) async {
    final now = DateTime.now().toUtc();
    final manifest = Host4DownloadManifest(
      schemaVersion: 2,
      taskKey: entry.taskKey,
      url: entry.url.toString(),
      fileName: entry.fileName,
      status: status,
      expectedSize: entry.request.expectedSize,
      expectedSha256: entry.request.expectedSha256,
      observedSha256: observedSha256,
      completedAt: status == Host4DownloadStatus.completed ? now : null,
      updatedAt: now,
    );
    await entry.directory.create(recursive: true);
    await entry.manifestFile.writeAsString(jsonEncode(manifest.toJson()));

    final downloads = await _downloadsDirectory();
    final index = await _readIndex(downloads);
    await _writeIndex(downloads, {
      ...index,
      entry.taskKey: _IndexRecord(
        taskKey: entry.taskKey,
        url: entry.url.toString(),
        fileName: entry.fileName,
        updatedAt: now,
      ),
    });
  }

  Future<void> clearTask(String taskKey) async {
    if (!_isTaskKey(taskKey)) {
      throw ArgumentError.value(
        taskKey,
        'taskKey',
        'Task key must be a 64 character lowercase hex string.',
      );
    }

    final downloads = await _downloadsDirectory();
    if (!await downloads.exists()) {
      return;
    }
    await migrateCurrentIfNeeded();

    final index = await _readIndex(downloads);
    if (!index.containsKey(taskKey)) {
      return;
    }

    final taskDirectory = Directory(p.join(downloads.path, 'tasks', taskKey));
    final manifest = await _readManifest(_manifestFile(taskDirectory));
    if (manifest != null && manifest.status.isActive) {
      throw StateError('Cannot clear an active download task.');
    }

    await _deleteTaskDirectory(taskDirectory);
    final repaired = Map<String, _IndexRecord>.of(index)..remove(taskKey);
    await _writeOrDeleteIndex(downloads, repaired);
  }

  Future<int> clearTerminalRecords({
    Set<String> excludedTaskKeys = const <String>{},
  }) async {
    final downloads = await _downloadsDirectory();
    if (!await downloads.exists()) {
      return 0;
    }
    await migrateCurrentIfNeeded();

    final index = await _readIndex(downloads);
    final repaired = Map<String, _IndexRecord>.of(index);
    var removed = 0;

    for (final taskKey in index.keys) {
      if (excludedTaskKeys.contains(taskKey)) {
        continue;
      }
      final taskDirectory = Directory(p.join(downloads.path, 'tasks', taskKey));
      final manifest = await _readManifest(_manifestFile(taskDirectory));
      if (manifest == null) {
        repaired.remove(taskKey);
        continue;
      }
      if (manifest.status.isActive) {
        continue;
      }

      await _deleteTaskDirectory(taskDirectory);
      repaired.remove(taskKey);
      removed += 1;
    }

    await _writeOrDeleteIndex(downloads, repaired);
    return removed;
  }

  Future<Host4DownloadCleanupResult> enforceStorageLimit({
    int maxBytes = 1024 * 1024 * 1024,
    Set<String> excludedTaskKeys = const <String>{},
  }) async {
    if (maxBytes <= 0) {
      throw ArgumentError.value(
        maxBytes,
        'maxBytes',
        'Storage limit must be greater than zero.',
      );
    }

    final downloads = await _downloadsDirectory();
    if (!await downloads.exists()) {
      return Host4DownloadCleanupResult(
        limitBytes: maxBytes,
        beforeBytes: 0,
        afterBytes: 0,
        deletedCount: 0,
        deletedTaskKeys: const <String>[],
      );
    }
    await migrateCurrentIfNeeded();

    final beforeBytes = await _directorySize(downloads);
    if (beforeBytes <= maxBytes) {
      return Host4DownloadCleanupResult(
        limitBytes: maxBytes,
        beforeBytes: beforeBytes,
        afterBytes: beforeBytes,
        deletedCount: 0,
        deletedTaskKeys: const <String>[],
      );
    }

    final index = await _readIndex(downloads);
    final candidates = <_CleanupCandidate>[];
    for (final taskKey in index.keys) {
      if (excludedTaskKeys.contains(taskKey)) {
        continue;
      }
      final taskDirectory = Directory(p.join(downloads.path, 'tasks', taskKey));
      final manifest = await _readManifest(_manifestFile(taskDirectory));
      if (manifest == null || manifest.status.isActive) {
        continue;
      }
      candidates.add(
        _CleanupCandidate(
          taskKey: taskKey,
          directory: taskDirectory,
          sortAt: manifest.completedAt ?? manifest.updatedAt,
        ),
      );
    }
    candidates.sort((left, right) {
      final timeOrder = left.sortAt.compareTo(right.sortAt);
      if (timeOrder != 0) {
        return timeOrder;
      }
      return left.taskKey.compareTo(right.taskKey);
    });

    final repaired = Map<String, _IndexRecord>.of(index);
    final deletedTaskKeys = <String>[];
    var currentBytes = beforeBytes;

    for (final candidate in candidates) {
      if (currentBytes <= maxBytes) {
        break;
      }
      final taskBytes = await _directorySize(candidate.directory);
      await _deleteTaskDirectory(candidate.directory);
      repaired.remove(candidate.taskKey);
      deletedTaskKeys.add(candidate.taskKey);
      currentBytes -= taskBytes;
      if (currentBytes < 0) {
        currentBytes = 0;
      }
    }

    await _writeOrDeleteIndex(downloads, repaired);
    final afterBytes = await _directorySize(downloads);
    return Host4DownloadCleanupResult(
      limitBytes: maxBytes,
      beforeBytes: beforeBytes,
      afterBytes: afterBytes,
      deletedCount: deletedTaskKeys.length,
      deletedTaskKeys: List<String>.unmodifiable(deletedTaskKeys),
    );
  }

  Host4DownloadRecord recordForRequest(
    Host4DownloadRequest request, {
    required Host4DownloadStatus status,
  }) {
    return Host4DownloadRecord(
      taskKey: request.taskKey,
      url: request.url,
      fileName: _safeFileName(request.url),
      status: status,
      size: null,
      expectedSha256: request.expectedSha256,
      observedSha256: null,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  Future<void> migrateCurrentIfNeeded() async {
    final downloads = await _downloadsDirectory();
    final legacy = File(p.join(downloads.path, 'current.json'));
    if (!await legacy.exists()) {
      return;
    }

    try {
      final decoded = jsonDecode(await legacy.readAsString());
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('Invalid current.json.');
      }
      final urlValue = decoded['url'];
      final fileNameValue = decoded['fileName'];
      if (urlValue is! String || fileNameValue is! String) {
        throw const FormatException('Invalid current.json fields.');
      }
      if (!_isValidManagedFileName(fileNameValue)) {
        throw const FormatException('Invalid current.json fileName.');
      }

      final request = Host4DownloadRequest(url: Uri.parse(urlValue));
      final legacyFile = File(p.join(downloads.path, fileNameValue));
      final legacyPartial = File(
        p.join(downloads.path, '$fileNameValue.partial'),
      );
      if (!await legacyFile.exists() && !await legacyPartial.exists()) {
        throw const FileSystemException('Missing legacy download file.');
      }

      final taskDirectory = Directory(
        p.join(downloads.path, 'tasks', request.taskKey),
      );
      await taskDirectory.create(recursive: true);
      final completeFile = File(p.join(taskDirectory.path, fileNameValue));
      final partialFile = File(
        p.join(taskDirectory.path, '$fileNameValue.partial'),
      );
      if (await legacyFile.exists() && !await completeFile.exists()) {
        await legacyFile.rename(completeFile.path);
      }
      if (await legacyPartial.exists() && !await partialFile.exists()) {
        await legacyPartial.rename(partialFile.path);
      }

      final now = DateTime.now().toUtc();
      final status = await completeFile.exists()
          ? Host4DownloadStatus.completed
          : Host4DownloadStatus.queued;
      await _manifestFile(taskDirectory).writeAsString(
        jsonEncode(
          Host4DownloadManifest(
            schemaVersion: 2,
            taskKey: request.taskKey,
            url: request.url.toString(),
            fileName: fileNameValue,
            status: status,
            expectedSize: null,
            expectedSha256: null,
            observedSha256: null,
            completedAt: status == Host4DownloadStatus.completed ? now : null,
            updatedAt: now,
          ).toJson(),
        ),
      );
      await _writeIndex(downloads, {
        ...await _readIndex(downloads),
        request.taskKey: _IndexRecord(
          taskKey: request.taskKey,
          url: request.url.toString(),
          fileName: fileNameValue,
          updatedAt: now,
        ),
      });
      await _deleteIfExists(legacy);
    } catch (_) {
      await _cleanManagedRootFiles(downloads);
      await _repairTaskDirectories(downloads);
    }
  }

  Future<Directory> _downloadsDirectory() async {
    final root = await _rootDirectoryProvider();
    return Directory(p.join(root.path, 'host4', 'downloads'));
  }

  Future<Map<String, _IndexRecord>> _readIndex(Directory downloads) async {
    final file = _indexFile(downloads);
    if (!await file.exists()) {
      final rebuilt = await _rebuildIndexFromTaskManifests(downloads);
      if (rebuilt.isNotEmpty) {
        await _writeIndex(downloads, rebuilt);
      }
      return rebuilt;
    }

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('Invalid index.');
      }
      final tasks = decoded['tasks'];
      if (tasks is! Map<String, Object?>) {
        throw const FormatException('Invalid index tasks.');
      }
      return tasks.map((key, value) {
        if (!_isTaskKey(key) || value is! Map<String, Object?>) {
          throw const FormatException('Invalid index task.');
        }
        return MapEntry(key, _IndexRecord.fromJson(key, value));
      });
    } catch (_) {
      await _deleteIfExists(file);
      final rebuilt = await _rebuildIndexFromTaskManifests(downloads);
      if (rebuilt.isNotEmpty) {
        await _writeIndex(downloads, rebuilt);
      }
      return rebuilt;
    }
  }

  Future<void> _writeIndex(
    Directory downloads,
    Map<String, _IndexRecord> index,
  ) async {
    await downloads.create(recursive: true);
    await _indexFile(downloads).writeAsString(
      jsonEncode(<String, Object?>{
        'schemaVersion': 2,
        'tasks': index.map((key, value) => MapEntry(key, value.toJson())),
      }),
    );
  }

  Future<void> _writeOrDeleteIndex(
    Directory downloads,
    Map<String, _IndexRecord> index,
  ) async {
    if (index.isEmpty) {
      await _deleteIfExists(_indexFile(downloads));
      return;
    }
    await _writeIndex(downloads, index);
  }

  Future<Host4DownloadManifest?> _readManifest(File file) async {
    if (!await file.exists()) {
      return null;
    }
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('Invalid manifest.');
      }
      final manifest = Host4DownloadManifest.fromJson(decoded);
      if (!_isTaskKey(manifest.taskKey) ||
          !_isValidManagedFileName(manifest.fileName)) {
        throw const FormatException('Invalid manifest path fields.');
      }
      return manifest;
    } catch (_) {
      await _deleteTaskDirectory(file.parent);
      return null;
    }
  }

  Future<Map<String, _IndexRecord>> _rebuildIndexFromTaskManifests(
    Directory downloads,
  ) async {
    final tasks = Directory(p.join(downloads.path, 'tasks'));
    if (!await tasks.exists()) {
      return const <String, _IndexRecord>{};
    }

    final index = <String, _IndexRecord>{};
    await for (final entity in tasks.list(followLinks: false)) {
      if (entity is! Directory) {
        continue;
      }

      final taskKey = p.basename(entity.path);
      if (!_isTaskKey(taskKey)) {
        await _deleteTaskDirectory(entity);
        continue;
      }

      final manifest = await _readManifest(_manifestFile(entity));
      if (manifest == null || manifest.taskKey != taskKey) {
        await _deleteTaskDirectory(entity);
        continue;
      }

      index[taskKey] = _IndexRecord(
        taskKey: taskKey,
        url: manifest.url,
        fileName: manifest.fileName,
        updatedAt: manifest.updatedAt,
      );
    }
    return index;
  }

  Future<void> _repairTaskDirectories(Directory downloads) async {
    final rebuilt = await _rebuildIndexFromTaskManifests(downloads);
    if (rebuilt.isNotEmpty) {
      await _writeIndex(downloads, rebuilt);
    }
  }

  Future<void> _cleanManagedRootFiles(Directory downloads) async {
    if (await downloads.exists()) {
      await for (final entity in downloads.list(followLinks: false)) {
        if (entity is! File) {
          continue;
        }
        final name = p.basename(entity.path);
        final partialBase = name.endsWith('.partial')
            ? name.substring(0, name.length - '.partial'.length)
            : null;
        if (name == 'current.json' ||
            name == 'downloads.json' ||
            _isValidManagedFileName(name) ||
            (partialBase != null && _isValidManagedFileName(partialBase))) {
          await entity.delete();
        }
      }
    }
  }

  Future<void> _deleteTaskDirectory(Directory directory) async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  Future<void> _deleteIfExists(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<int> _directorySize(Directory directory) async {
    if (!await directory.exists()) {
      return 0;
    }

    var total = 0;
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

  File _indexFile(Directory downloads) {
    return File(p.join(downloads.path, 'downloads.json'));
  }

  File _manifestFile(Directory taskDirectory) {
    return File(p.join(taskDirectory.path, 'manifest.json'));
  }

  bool _isTaskKey(String taskKey) {
    return taskKey.length == 64 && RegExp(r'^[0-9a-f]{64}$').hasMatch(taskKey);
  }

  bool _isValidManagedFileName(String fileName) {
    if (fileName.isEmpty || fileName.length > 120) {
      return false;
    }
    if (fileName == '.' ||
        fileName == '..' ||
        p.basename(fileName) != fileName) {
      return false;
    }
    return RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(fileName);
  }

  String _safeFileName(Uri url) {
    final lastSegment = url.pathSegments
        .where((segment) => segment.isNotEmpty)
        .lastOrNull;
    final decoded = lastSegment == null ? '' : Uri.decodeComponent(lastSegment);
    final baseName = p.basename(decoded);
    final safe = baseName.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
    final trimmed = safe.replaceAll(RegExp(r'^_+|_+$'), '');
    final fileName = trimmed.isEmpty || trimmed == '.' || trimmed == '..'
        ? 'firmware.bin'
        : trimmed;

    return fileName.substring(0, math.min(fileName.length, 120));
  }
}

class _CleanupCandidate {
  const _CleanupCandidate({
    required this.taskKey,
    required this.directory,
    required this.sortAt,
  });

  final String taskKey;
  final Directory directory;
  final DateTime sortAt;
}

class Host4DownloadStoreEntry {
  const Host4DownloadStoreEntry({
    required this.request,
    required this.directory,
    required this.fileName,
    required this.file,
    required this.partialFile,
    required this.manifestFile,
  });

  final Host4DownloadRequest request;
  final Directory directory;
  final String fileName;
  final File file;
  final File partialFile;
  final File manifestFile;

  String get taskKey => request.taskKey;
  Uri get url => request.url;
}

class _IndexRecord {
  const _IndexRecord({
    required this.taskKey,
    required this.url,
    required this.fileName,
    required this.updatedAt,
  });

  final String taskKey;
  final String url;
  final String fileName;
  final DateTime updatedAt;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'taskKey': taskKey,
      'url': url,
      'fileName': fileName,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory _IndexRecord.fromJson(String taskKey, Map<String, Object?> json) {
    final url = json['url'];
    final fileName = json['fileName'];
    final updatedAt = json['updatedAt'];
    if (url is! String || fileName is! String || updatedAt is! String) {
      throw const FormatException('Invalid index record.');
    }
    return _IndexRecord(
      taskKey: taskKey,
      url: url,
      fileName: fileName,
      updatedAt: DateTime.parse(updatedAt),
    );
  }
}
