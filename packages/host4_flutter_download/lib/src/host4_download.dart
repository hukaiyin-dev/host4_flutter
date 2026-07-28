part of '../host4_flutter_download.dart';

class Host4Download {
  Host4Download({int maxConcurrentDownloads = 2})
    : this._(
        store: Host4DownloadStore(),
        driver: FlutterDownloadManagerDriver(
          maxConcurrentDownloads: maxConcurrentDownloads,
        ),
        maxConcurrentDownloads: maxConcurrentDownloads,
      );

  Host4Download.debug({
    required Object store,
    required Object driver,
    int maxConcurrentDownloads = 2,
  }) : this._(
         store: store as Host4DownloadStore,
         driver: driver as FlutterDownloadManagerDriver,
         maxConcurrentDownloads: maxConcurrentDownloads,
       );

  Host4Download._({
    required Host4DownloadStore store,
    required FlutterDownloadManagerDriver driver,
    required int maxConcurrentDownloads,
  }) : _store = store,
       _driver = driver,
       _registry = Host4DownloadRegistry(
         maxConcurrentDownloads: maxConcurrentDownloads,
       );

  final Host4DownloadStore _store;
  final FlutterDownloadManagerDriver _driver;
  final Host4DownloadRegistry _registry;

  Future<Host4DownloadTask> download(Uri url) async {
    return downloadRequest(Host4DownloadRequest(url: url));
  }

  Future<Host4DownloadTask> downloadRequest(
    Host4DownloadRequest request,
  ) async {
    final active = _registry.findActive(request.taskKey);
    if (active != null) {
      _ensureCompatibleActiveRequest(active.request, request);
      return active;
    }

    final task = _registry.createQueued(request);
    task._attachControls(onCancel: () => _releaseTask(task));
    await _registry.pumpQueue(_startTask);
    return task;
  }

  Future<void> _startTask(Host4DownloadTask task) async {
    try {
      final entry = await _store.prepare(task.request);
      if (!task.status.isActive) {
        _registry.markTerminal(task.taskKey);
        return;
      }

      if (task.request.forceRefresh) {
        if (await entry.file.exists()) {
          await entry.file.delete();
        }
        if (await entry.partialFile.exists()) {
          await entry.partialFile.delete();
        }
      }

      final decision = await _driver.prepareStart(entry);
      if (!task.status.isActive) {
        _registry.markTerminal(task.taskKey);
        return;
      }

      await _store.writeManifest(entry);
      if (!task.status.isActive) {
        _registry.markTerminal(task.taskKey);
        return;
      }

      if (decision.kind == Host4DownloadStartKind.completedFile) {
        await _completeFromFile(task, entry);
        return;
      }

      final handle = await _driver.start(entry, decision: decision);
      if (!task.status.isActive) {
        await handle.cancel();
        _registry.markTerminal(task.taskKey);
        return;
      }

      _attachHandle(task, handle, entry);
      task._markDownloading();
    } catch (error, stackTrace) {
      if (task.status.isActive) {
        task._fail(error, stackTrace);
      }
      _registry.markTerminal(task.taskKey);
      unawaited(_registry.pumpQueue(_startTask));
    }
  }

  Future<List<Host4DownloadRecord>> list() async {
    final records = <String, Host4DownloadRecord>{
      for (final record in await _store.listRecords()) record.taskKey: record,
    };

    for (final task in _registry.activeTasks) {
      final stored = records[task.taskKey];
      records[task.taskKey] = stored == null
          ? _store.recordForRequest(task.request, status: task.status)
          : Host4DownloadRecord(
              taskKey: stored.taskKey,
              url: stored.url,
              fileName: stored.fileName,
              status: task.status,
              size: stored.size,
              expectedSha256: stored.expectedSha256,
              observedSha256: stored.observedSha256,
              updatedAt: DateTime.now().toUtc(),
              localPath: stored.localPath,
              completedAt: stored.completedAt,
            );
    }

    final sorted = records.values.toList()
      ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    return sorted;
  }

  Future<void> clear(String taskKey) async {
    if (_registry.findActive(taskKey) != null) {
      throw StateError('Cannot clear an active download task.');
    }

    await _store.clearTask(taskKey);
  }

  Future<int> clearCompleted() async {
    return _store.clearTerminalRecords(
      excludedTaskKeys: _registry.activeTaskKeys,
    );
  }

  Future<Host4DownloadCleanupResult> enforceStorageLimit({
    int maxBytes = 1024 * 1024 * 1024,
  }) async {
    return _store.enforceStorageLimit(
      maxBytes: maxBytes,
      excludedTaskKeys: _registry.activeTaskKeys,
    );
  }

  void _attachHandle(
    Host4DownloadTask task,
    Host4DownloadDriverHandle handle,
    Host4DownloadStoreEntry entry,
  ) {
    task._attachControls(
      onPause: handle.pause,
      onResume: handle.resume,
      onCancel: () async {
        try {
          await handle.cancel();
          await _store.writeManifest(
            entry,
            status: Host4DownloadStatus.canceled,
          );
        } catch (error, stackTrace) {
          _reportAsyncControlError(error, stackTrace);
          try {
            await _store.writeManifest(
              entry,
              status: Host4DownloadStatus.canceled,
            );
          } catch (manifestError, manifestStackTrace) {
            _reportAsyncControlError(manifestError, manifestStackTrace);
          }
        } finally {
          _registry.markTerminal(task.taskKey);
          unawaited(_registry.pumpQueue(_startTask));
        }
      },
    );
    handle.progress.listen((progress) {
      if (task.status.isActive) {
        task._updateProgress(progress);
      }
    });
    unawaited(
      handle.done
          .then((_) async {
            if (!task.status.isActive) {
              return;
            }
            await _completeFromFile(task, entry);
          })
          .catchError((Object error, StackTrace stackTrace) async {
            if (task.status == Host4DownloadStatus.canceled) {
              _registry.markTerminal(task.taskKey);
              unawaited(_registry.pumpQueue(_startTask));
              return;
            }
            await _store.writeManifest(
              entry,
              status: Host4DownloadStatus.failed,
            );
            if (task.status.isActive) {
              task._fail(error, stackTrace);
            }
            _registry.markTerminal(task.taskKey);
            unawaited(_registry.pumpQueue(_startTask));
          }),
    );
  }

  Future<void> _releaseTask(Host4DownloadTask task) async {
    _registry.markTerminal(task.taskKey);
    unawaited(_registry.pumpQueue(_startTask));
  }

  Future<void> _completeFromFile(
    Host4DownloadTask task,
    Host4DownloadStoreEntry entry,
  ) async {
    try {
      final file = entry.file;
      if (!await file.exists()) {
        task._fail(StateError('Downloaded file does not exist.'));
        _releaseTask(task);
        return;
      }

      final size = await file.length();
      if (size <= 0) {
        task._fail(StateError('Downloaded file is empty.'));
        _releaseTask(task);
        return;
      }

      await file.openRead(0, 1).drain<void>();
      final observedSha256 = await _sha256ForFile(file);
      final expectedSize = task.request.expectedSize;
      if (expectedSize != null && expectedSize != size) {
        await _store.writeManifest(
          entry,
          status: Host4DownloadStatus.failed,
          observedSha256: observedSha256,
        );
        task._fail(StateError('Downloaded file size mismatch.'));
        _registry.markTerminal(task.taskKey);
        unawaited(_registry.pumpQueue(_startTask));
        return;
      }

      final expectedSha256 = task.request.expectedSha256;
      if (expectedSha256 != null && expectedSha256 != observedSha256) {
        await _store.writeManifest(
          entry,
          status: Host4DownloadStatus.failed,
          observedSha256: observedSha256,
        );
        task._fail(StateError('Downloaded file sha256 mismatch.'));
        _registry.markTerminal(task.taskKey);
        unawaited(_registry.pumpQueue(_startTask));
        return;
      }

      await _store.writeManifest(
        entry,
        status: Host4DownloadStatus.completed,
        observedSha256: observedSha256,
      );
      task._complete(
        Host4DownloadedFile(
          localPath: file.path,
          fileName: entry.fileName,
          size: size,
          expectedSha256: expectedSha256,
          observedSha256: observedSha256,
          verified: expectedSha256 == null || expectedSha256 == observedSha256,
        ),
      );
      _registry.markTerminal(task.taskKey);
      unawaited(_registry.pumpQueue(_startTask));
    } catch (error, stackTrace) {
      await _store.writeManifest(entry, status: Host4DownloadStatus.failed);
      if (task.status.isActive) {
        task._fail(error, stackTrace);
      }
      _registry.markTerminal(task.taskKey);
      unawaited(_registry.pumpQueue(_startTask));
    }
  }

  Future<String> _sha256ForFile(File file) async {
    return (await sha256.bind(file.openRead()).first).toString();
  }

  void _ensureCompatibleActiveRequest(
    Host4DownloadRequest active,
    Host4DownloadRequest incoming,
  ) {
    if (active.expectedSize != incoming.expectedSize ||
        active.expectedSha256 != incoming.expectedSha256) {
      throw StateError(
        'Active download for the same URL has different validation metadata.',
      );
    }
  }

  void _reportAsyncControlError(Object error, StackTrace stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'host4_flutter_download',
        context: ErrorDescription('while running download task controls'),
      ),
    );
  }
}
