import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_download_manager/flutter_download_manager.dart' as fdm;

import '../storage/host4_download_store.dart';

typedef Host4RangeProbe = Future<int> Function(Uri url, int partialBytes);

typedef Host4DownloadStarter =
    Future<Host4DownloadDriverHandle> Function(
      Host4DownloadStoreEntry entry, {
      required bool resumePartial,
    });

class FlutterDownloadManagerDriver {
  FlutterDownloadManagerDriver({
    Host4RangeProbe? rangeProbe,
    Host4DownloadStarter? startDownload,
    Dio? dio,
    fdm.DownloadManager? downloadManager,
    int? maxConcurrentDownloads,
  }) : _rangeProbe = rangeProbe ?? _dioRangeProbe(dio ?? Dio()),
       _startDownload =
           startDownload ??
           _flutterDownloadStarter(
             _downloadManager(
               downloadManager: downloadManager,
               dio: dio,
               maxConcurrentDownloads: maxConcurrentDownloads,
             ),
           );

  final Host4RangeProbe _rangeProbe;
  final Host4DownloadStarter _startDownload;

  Future<Host4DownloadStartDecision> prepareStart(
    Host4DownloadStoreEntry entry,
  ) async {
    if (await _isReadableNonEmptyFile(entry.file)) {
      return const Host4DownloadStartDecision(
        kind: Host4DownloadStartKind.completedFile,
        resumePartial: false,
        completeFileReadable: true,
      );
    }

    if (!await entry.partialFile.exists()) {
      return const Host4DownloadStartDecision(
        kind: Host4DownloadStartKind.fresh,
        resumePartial: false,
        completeFileReadable: false,
      );
    }

    final partialBytes = await entry.partialFile.length();
    if (partialBytes <= 0) {
      await entry.partialFile.delete();
      return const Host4DownloadStartDecision(
        kind: Host4DownloadStartKind.fresh,
        resumePartial: false,
        completeFileReadable: false,
      );
    }

    final supportsRange = await _supportsRange(entry.url, partialBytes);
    if (supportsRange) {
      return const Host4DownloadStartDecision(
        kind: Host4DownloadStartKind.resumePartial,
        resumePartial: true,
        completeFileReadable: false,
      );
    }

    await entry.partialFile.delete();
    return const Host4DownloadStartDecision(
      kind: Host4DownloadStartKind.fresh,
      resumePartial: false,
      completeFileReadable: false,
    );
  }

  Future<Host4DownloadDriverHandle> start(
    Host4DownloadStoreEntry entry, {
    required Host4DownloadStartDecision decision,
  }) {
    if (decision.kind == Host4DownloadStartKind.completedFile) {
      throw StateError(
        'Complete file is already readable; download not started.',
      );
    }
    return _startDownload(entry, resumePartial: decision.resumePartial);
  }

  Future<bool> _supportsRange(Uri url, int partialBytes) async {
    try {
      return await _rangeProbe(url, partialBytes) == HttpStatus.partialContent;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _isReadableNonEmptyFile(File file) async {
    if (!await file.exists()) {
      return false;
    }

    try {
      if (await file.length() <= 0) {
        return false;
      }
      await file.openRead(0, 1).drain<void>();
      return true;
    } on FileSystemException {
      return false;
    }
  }

  static Host4RangeProbe _dioRangeProbe(Dio dio) {
    return (Uri url, partialBytes) async {
      final response = await dio.getUri<ResponseBody>(
        url,
        options: Options(
          responseType: ResponseType.stream,
          headers: {HttpHeaders.rangeHeader: 'bytes=$partialBytes-'},
        ),
      );
      await response.data?.stream.drain<void>();
      return response.statusCode ?? 0;
    };
  }

  static Host4DownloadStarter _flutterDownloadStarter(
    fdm.DownloadManager downloadManager,
  ) {
    return (
      Host4DownloadStoreEntry entry, {
      required bool resumePartial,
    }) async {
      final url = entry.url.toString();
      final ownerZone = Zone.current;
      final started = Completer<Host4DownloadDriverHandle>();
      fdm.DownloadTask? task;
      _FlutterDownloadManagerHandle? handle;
      Object? pendingDetachedError;
      StackTrace? pendingDetachedStackTrace;
      void completeStartedError(Object error, StackTrace stackTrace) {
        ownerZone.run(() {
          if (!started.isCompleted) {
            started.completeError(error, stackTrace);
          }
        });
      }

      runZonedGuarded(
        () {
          unawaited(
            Future<void>(() async {
              task = await downloadManager.addDownload(url, entry.file.path);
              final currentTask = task;
              if (currentTask == null) {
                throw StateError('Download manager did not create a task.');
              }
              final currentHandle = ownerZone.run(
                () => _FlutterDownloadManagerHandle(
                  downloadManager,
                  currentTask,
                  entry,
                ),
              );
              handle = currentHandle;
              ownerZone.run(() => started.complete(currentHandle));
              final detachedError = pendingDetachedError;
              if (detachedError != null) {
                ownerZone.run(
                  () => Timer.run(
                    () => currentHandle.completeWithDetachedError(
                      detachedError,
                      pendingDetachedStackTrace,
                    ),
                  ),
                );
              }
            }).catchError((Object error, StackTrace stackTrace) {
              completeStartedError(error, stackTrace);
            }),
          );
        },
        (error, stackTrace) {
          final currentTask = task ?? downloadManager.getDownload(url);
          final currentHandle = handle;
          if (currentHandle != null) {
            ownerZone.run(
              () => currentHandle.completeWithDetachedError(error, stackTrace),
            );
          } else if (currentTask != null) {
            pendingDetachedError = error;
            pendingDetachedStackTrace = stackTrace;
          } else if (!started.isCompleted) {
            completeStartedError(error, stackTrace);
          }
        },
      );

      return started.future;
    };
  }

  static fdm.DownloadManager _downloadManager({
    fdm.DownloadManager? downloadManager,
    Dio? dio,
    required int? maxConcurrentDownloads,
  }) {
    final manager =
        downloadManager ??
        fdm.DownloadManager(
          maxConcurrentTasks: _validateMaxConcurrent(
            maxConcurrentDownloads ?? 2,
          ),
        );
    if (downloadManager != null && maxConcurrentDownloads != null) {
      manager.maxConcurrentTasks = _validateMaxConcurrent(
        maxConcurrentDownloads,
      );
    }
    if (dio != null) {
      manager.dio = dio;
    }
    return manager;
  }

  static int _validateMaxConcurrent(int value) {
    if (value <= 0) {
      throw ArgumentError.value(
        value,
        'maxConcurrentDownloads',
        'Max concurrent downloads must be greater than zero.',
      );
    }
    return value;
  }
}

enum Host4DownloadStartKind { completedFile, resumePartial, fresh }

class Host4DownloadStartDecision {
  const Host4DownloadStartDecision({
    required this.kind,
    required this.resumePartial,
    required this.completeFileReadable,
  });

  final Host4DownloadStartKind kind;
  final bool resumePartial;
  final bool completeFileReadable;
}

abstract class Host4DownloadDriverHandle {
  String get taskKey;
  Stream<double> get progress;
  Future<void> get done;

  Future<void> pause();
  Future<void> resume();
  Future<void> cancel();
}

class _FlutterDownloadManagerHandle implements Host4DownloadDriverHandle {
  _FlutterDownloadManagerHandle(
    this._downloadManager,
    this._task,
    this._entry,
  ) {
    _task.progress.addListener(_emitProgress);
    _task.status.addListener(_emitDone);
    // The third-party task may fail before Host4 attaches its done handler.
    // Keep the Future locally handled while still allowing Host4 to observe it.
    unawaited(_done.future.catchError((_) {}));
    _emitProgress();
    _emitDone();
  }

  final fdm.DownloadManager _downloadManager;
  final fdm.DownloadTask _task;
  final Host4DownloadStoreEntry _entry;
  final StreamController<double> _progress =
      StreamController<double>.broadcast();
  final Completer<void> _done = Completer<void>();

  @override
  String get taskKey => _entry.taskKey;

  @override
  Stream<double> get progress => _progress.stream;

  @override
  Future<void> get done => _done.future;

  @override
  Future<void> pause() => _downloadManager.pauseDownload(_task.request.url);

  @override
  Future<void> resume() => _downloadManager.resumeDownload(_task.request.url);

  @override
  Future<void> cancel() => _downloadManager.cancelDownload(_task.request.url);

  void _emitProgress() {
    if (!_progress.isClosed) {
      _progress.add(_task.progress.value.clamp(0, 1).toDouble());
    }
  }

  void _emitDone() {
    final status = _task.status.value;
    if (status == fdm.DownloadStatus.completed) {
      unawaited(_completeAfterReadableFileCheck());
    } else if (status == fdm.DownloadStatus.failed ||
        status == fdm.DownloadStatus.canceled) {
      _completeDone(StateError('Download finished with $status.'));
    }
  }

  void completeWithDetachedError(Object error, StackTrace? stackTrace) {
    _completeDone(error, stackTrace);
  }

  Future<void> _completeAfterReadableFileCheck() async {
    if (await FlutterDownloadManagerDriver._isReadableNonEmptyFile(
      _entry.file,
    )) {
      _completeDone();
    } else {
      _completeDone(StateError('Download completed without a readable file.'));
    }
  }

  void _completeDone([Object? error, StackTrace? stackTrace]) {
    _task.progress.removeListener(_emitProgress);
    _task.status.removeListener(_emitDone);
    unawaited(_progress.close());
    if (_done.isCompleted) {
      return;
    }
    if (error == null) {
      _done.complete();
    } else {
      _done.completeError(error, stackTrace);
    }
  }
}
