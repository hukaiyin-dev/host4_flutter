part of '../../host4_flutter_download.dart';

enum Host4DownloadStatus {
  queued,
  downloading,
  paused,
  completed,
  failed,
  canceled,
}

extension Host4DownloadStatusX on Host4DownloadStatus {
  bool get isActive {
    return switch (this) {
      Host4DownloadStatus.queued ||
      Host4DownloadStatus.downloading ||
      Host4DownloadStatus.paused => true,
      Host4DownloadStatus.completed ||
      Host4DownloadStatus.failed ||
      Host4DownloadStatus.canceled => false,
    };
  }
}

class Host4DownloadTask implements Listenable {
  Host4DownloadTask({
    required this.taskKey,
    required this.request,
    FutureOr<void> Function()? onPause,
    FutureOr<void> Function()? onResume,
    FutureOr<void> Function()? onCancel,
  }) : _onPause = onPause,
       _onResume = onResume,
       _onCancel = onCancel,
       _resultCompleter = Completer<Host4DownloadedFile>() {
    if (taskKey.length != 64 || !RegExp(r'^[0-9a-f]{64}$').hasMatch(taskKey)) {
      throw ArgumentError.value(
        taskKey,
        'taskKey',
        'Task key must be a 64 character lowercase hex string.',
      );
    }
  }

  final String taskKey;
  final Host4DownloadRequest request;
  FutureOr<void> Function()? _onPause;
  FutureOr<void> Function()? _onResume;
  FutureOr<void> Function()? _onCancel;
  final Completer<Host4DownloadedFile> _resultCompleter;
  final List<VoidCallback> _listeners = [];

  Host4DownloadStatus _status = Host4DownloadStatus.queued;
  double _progress = 0;

  Host4DownloadStatus get status => _status;
  double get progress => _progress;
  Future<Host4DownloadedFile> get result => _resultCompleter.future;

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _attachControls({
    FutureOr<void> Function()? onPause,
    FutureOr<void> Function()? onResume,
    FutureOr<void> Function()? onCancel,
  }) {
    _onPause = onPause;
    _onResume = onResume;
    _onCancel = onCancel;
  }

  void _markDownloading() {
    _ensureActive('mark downloading');
    _status = Host4DownloadStatus.downloading;
    _notifyListeners();
  }

  void _updateProgress(double value) {
    _ensureActive('update progress');
    final nextProgress = value.clamp(0, 1).toDouble();
    if (_progress == nextProgress) {
      return;
    }
    _progress = nextProgress;
    _notifyListeners();
  }

  void _complete(Host4DownloadedFile file) {
    _ensureActive('complete');
    _progress = 1;
    _status = Host4DownloadStatus.completed;
    _notifyListeners();
    if (!_resultCompleter.isCompleted) {
      _resultCompleter.complete(file);
    }
  }

  void _fail(Object error, [StackTrace? stackTrace]) {
    _ensureActive('fail');
    _status = Host4DownloadStatus.failed;
    _notifyListeners();
    if (!_resultCompleter.isCompleted) {
      _resultCompleter.completeError(error, stackTrace);
    }
  }

  void pause() {
    if (_status != Host4DownloadStatus.downloading) {
      throw StateError('Cannot pause a $_status download task.');
    }
    _status = Host4DownloadStatus.paused;
    _notifyListeners();
    _runControl(_onPause);
  }

  void resume() {
    if (_status != Host4DownloadStatus.paused) {
      throw StateError('Cannot resume a $_status download task.');
    }
    _status = Host4DownloadStatus.downloading;
    _notifyListeners();
    _runControl(_onResume);
  }

  void cancel() {
    if (!_status.isActive) {
      throw StateError('Cannot cancel a $_status download task.');
    }
    _status = Host4DownloadStatus.canceled;
    _notifyListeners();
    _runControl(_onCancel);
    if (!_resultCompleter.isCompleted) {
      _resultCompleter.completeError(StateError('Download task canceled.'));
    }
  }

  void _ensureActive(String action) {
    if (!_status.isActive) {
      throw StateError('Cannot $action for a $_status download task.');
    }
  }

  void _notifyListeners() {
    for (final listener in List<VoidCallback>.of(_listeners)) {
      try {
        listener();
      } catch (error, stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'host4_flutter_download',
            context: ErrorDescription(
              'while notifying download task listeners',
            ),
          ),
        );
      }
    }
  }

  void _runControl(FutureOr<void> Function()? control) {
    if (control == null) {
      return;
    }
    unawaited(Future<void>.sync(control).catchError((_) {}));
  }
}
