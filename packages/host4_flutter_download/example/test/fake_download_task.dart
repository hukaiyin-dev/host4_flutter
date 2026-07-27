import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:host4_flutter_download/host4_flutter_download.dart';

class FakeHost4DownloadTask extends Host4DownloadTask {
  FakeHost4DownloadTask({
    required super.request,
    double progress = 0,
  }) : _progress = progress,
       super(taskKey: request.taskKey) {
    unawaited(_result.future.then<void>((_) {}, onError: (_, _) {}));
  }

  final _listeners = <VoidCallback>[];
  final _result = Completer<Host4DownloadedFile>();
  Host4DownloadStatus _status = Host4DownloadStatus.downloading;
  double _progress;

  @override
  Host4DownloadStatus get status => _status;

  @override
  double get progress => _progress;

  @override
  Future<Host4DownloadedFile> get result => _result.future;

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  @override
  void pause() {
    if (_status != Host4DownloadStatus.downloading) {
      throw StateError('Cannot pause a $_status download task.');
    }
    _status = Host4DownloadStatus.paused;
    _notify();
  }

  @override
  void resume() {
    if (_status != Host4DownloadStatus.paused) {
      throw StateError('Cannot resume a $_status download task.');
    }
    _status = Host4DownloadStatus.downloading;
    _notify();
  }

  @override
  void cancel() {
    if (!_status.isActive) {
      throw StateError('Cannot cancel a $_status download task.');
    }
    _status = Host4DownloadStatus.canceled;
    _notify();
    if (!_result.isCompleted) {
      _result.completeError(StateError('Download task canceled.'));
    }
  }

  void setProgress(double value) {
    _progress = value.clamp(0, 1).toDouble();
    _notify();
  }

  void completeWith(Host4DownloadedFile file) {
    _status = Host4DownloadStatus.completed;
    _progress = 1;
    _notify();
    if (!_result.isCompleted) {
      _result.complete(file);
    }
  }

  void _notify() {
    for (final listener in List<VoidCallback>.of(_listeners)) {
      listener();
    }
  }
}
