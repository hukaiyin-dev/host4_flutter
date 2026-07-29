import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;

/// Resolves the directory under which a task-specific download directory is
/// created.
typedef Host4DownloadDirectoryProvider = Future<Directory> Function();

/// Starts task-local downloads and retains ownership of their temporary files.
final class Host4Download {
  /// Creates a downloader.
  ///
  /// Supplying [dio] or [directoryProvider] is useful when an application has
  /// custom networking configuration or when a test needs an isolated folder.
  Host4Download({Dio? dio, Host4DownloadDirectoryProvider? directoryProvider})
    : _dio = dio ?? Dio(),
      _directoryProvider =
          directoryProvider ?? _defaultDownloadDirectoryProvider;

  final Dio _dio;
  final Host4DownloadDirectoryProvider _directoryProvider;

  /// Starts downloading [uri] and returns immediately with its task handle.
  ///
  /// Only HTTP and HTTPS URLs are accepted. The completed file remains in a
  /// task-specific temporary directory so callers can consume it after the
  /// task completes.
  Future<Host4DownloadTask> download(Uri uri) async {
    if (!uri.hasScheme ||
        (uri.scheme.toLowerCase() != 'http' &&
            uri.scheme.toLowerCase() != 'https') ||
        uri.host.isEmpty) {
      throw ArgumentError.value(
        uri,
        'uri',
        'Expected an absolute HTTP(S) URL.',
      );
    }

    final parentDirectory = await _directoryProvider();
    await parentDirectory.create(recursive: true);
    final taskDirectory = await parentDirectory.createTemp('host4_download_');
    final fileName = _downloadFileName(uri);
    final task = Host4DownloadTask._(
      dio: _dio,
      uri: uri,
      destination: File(path.join(taskDirectory.path, fileName)),
      taskDirectory: taskDirectory,
    );
    task._start();
    return task;
  }

  static Future<Directory> _defaultDownloadDirectoryProvider() async =>
      Directory.systemTemp;
}

/// Metadata for a successfully downloaded file.
final class Host4DownloadedFile {
  /// Creates immutable downloaded-file metadata.
  const Host4DownloadedFile({
    required this.localPath,
    required this.size,
    required this.fileName,
  });

  /// Absolute local path owned by the Host4 download task.
  final String localPath;

  /// File size in bytes.
  final int size;

  /// File name derived from the final URL path.
  final String fileName;

  @override
  bool operator ==(Object other) =>
      other is Host4DownloadedFile &&
      other.localPath == localPath &&
      other.size == size &&
      other.fileName == fileName;

  @override
  int get hashCode => Object.hash(localPath, size, fileName);

  @override
  String toString() =>
      'Host4DownloadedFile(localPath: $localPath, size: $size, '
      'fileName: $fileName)';
}

/// A cancellable download with task-local progress and result state.
final class Host4DownloadTask {
  Host4DownloadTask._({
    required Dio dio,
    required this.uri,
    required File destination,
    required Directory taskDirectory,
  }) : _dio = dio,
       _destination = destination,
       _taskDirectory = taskDirectory {
    // A caller normally observes result immediately after receiving the task.
    // Keep a private error observer as well so an unusually early network
    // failure never becomes an unhandled asynchronous error.
    unawaited(_resultCompleter.future.then<void>((_) {}, onError: (_, _) {}));
  }

  final Dio _dio;
  final File _destination;
  final Directory _taskDirectory;
  final CancelToken _cancelToken = CancelToken();
  final Completer<Host4DownloadedFile> _resultCompleter =
      Completer<Host4DownloadedFile>();
  final Set<void Function()> _listeners = <void Function()>{};

  /// Source URL for this task.
  final Uri uri;

  double _progress = 0;
  bool _started = false;
  bool _settled = false;
  bool _cancelRequested = false;

  /// Current progress in the inclusive range 0–1.
  double get progress => _progress;

  /// Completes with file metadata or with the download/cancellation error.
  Future<Host4DownloadedFile> get result => _resultCompleter.future;

  /// Registers a callback invoked whenever [progress] changes.
  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  /// Removes a callback previously registered with [addListener].
  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  /// Cancels this task without affecting any other download.
  ///
  /// Calling this method after cancellation or settlement throws [StateError].
  void cancel() {
    if (_settled || _cancelRequested) {
      throw StateError('Host4 download task is already settled.');
    }
    _cancelRequested = true;
    _cancelToken.cancel(Host4DownloadCanceledException(uri));
  }

  void _start() {
    if (_started) return;
    _started = true;
    unawaited(_run());
  }

  Future<void> _run() async {
    try {
      await _dio.download(
        uri.toString(),
        _destination.path,
        cancelToken: _cancelToken,
        deleteOnError: true,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            _updateProgress(received / total);
          }
        },
      );
      if (_cancelRequested) {
        throw Host4DownloadCanceledException(uri);
      }

      final size = await _destination.length();
      _updateProgress(1);
      _settled = true;
      _resultCompleter.complete(
        Host4DownloadedFile(
          localPath: _destination.absolute.path,
          size: size,
          fileName: path.basename(_destination.path),
        ),
      );
    } catch (error, stackTrace) {
      final resolvedError = error is DioException && CancelToken.isCancel(error)
          ? Host4DownloadCanceledException(uri)
          : error;
      await _deleteFailedTaskDirectory();
      _settled = true;
      if (!_resultCompleter.isCompleted) {
        _resultCompleter.completeError(resolvedError, stackTrace);
      }
    }
  }

  void _updateProgress(double value) {
    if (_settled || _cancelRequested) return;
    final normalized = value.clamp(0, 1).toDouble();
    if (_progress == normalized) return;
    _progress = normalized;
    for (final listener in List<void Function()>.of(_listeners)) {
      listener();
    }
  }

  Future<void> _deleteFailedTaskDirectory() async {
    try {
      if (await _taskDirectory.exists()) {
        await _taskDirectory.delete(recursive: true);
      }
    } on FileSystemException {
      // Preserve the original download error when temporary cleanup fails.
    }
  }
}

/// Error delivered by [Host4DownloadTask.result] after task cancellation.
final class Host4DownloadCanceledException implements Exception {
  /// Creates a task-local cancellation error for [uri].
  const Host4DownloadCanceledException(this.uri);

  /// URL whose download was cancelled.
  final Uri uri;

  @override
  String toString() => 'Host4 download cancelled: $uri';
}

String _downloadFileName(Uri uri) {
  final lastSegment = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
  final withoutControls = lastSegment.replaceAll(
    RegExp(r'[\x00-\x1f\x7f]'),
    '_',
  );
  final candidate = path.basename(withoutControls).trim();
  if (candidate.isEmpty || candidate == '.' || candidate == '..') {
    return 'download.bin';
  }
  return candidate;
}
