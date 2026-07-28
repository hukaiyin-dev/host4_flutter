part of '../../host4_flutter_download.dart';

typedef Host4DownloadTaskStarter =
    Future<void> Function(Host4DownloadTask task);

class Host4DownloadRegistry {
  Host4DownloadRegistry({required int maxConcurrentDownloads})
    : maxConcurrentDownloads = _validateMaxConcurrent(maxConcurrentDownloads);

  final int maxConcurrentDownloads;
  final Map<String, Host4DownloadTask> _activeTasks = {};
  final List<Host4DownloadTask> _queue = [];
  final Set<String> _runningTaskKeys = {};
  Future<void>? _pump;
  var _needsPump = false;

  Host4DownloadTask? findActive(String taskKey) {
    _pruneTerminal(taskKey);
    return _activeTasks[taskKey];
  }

  void _pruneTerminal(String taskKey) {
    final task = _activeTasks[taskKey];
    if (task != null && !task.status.isActive) {
      markTerminal(taskKey);
    }
  }

  bool get hasActiveTasks => _activeTasks.values.any((task) {
    return task.status.isActive;
  });

  Set<String> get activeTaskKeys {
    return _activeTasks.entries
        .where((entry) => entry.value.status.isActive)
        .map((entry) => entry.key)
        .toSet();
  }

  List<Host4DownloadTask> get activeTasks {
    return _activeTasks.values.where((task) => task.status.isActive).toList();
  }

  Host4DownloadTask createQueued(Host4DownloadRequest request) {
    final active = findActive(request.taskKey);
    if (active != null) {
      return active;
    }

    final task = Host4DownloadTask(taskKey: request.taskKey, request: request);
    _activeTasks[request.taskKey] = task;
    _queue.add(task);
    return task;
  }

  Future<void> pumpQueue(Host4DownloadTaskStarter starter) {
    final inFlight = _pump;
    if (inFlight != null) {
      _needsPump = true;
      return inFlight;
    }

    _pump = _pumpUntilIdle(starter).whenComplete(() {
      _pump = null;
    });
    return _pump!;
  }

  void markTerminal(String taskKey) {
    _activeTasks.remove(taskKey);
    _runningTaskKeys.remove(taskKey);
    _queue.removeWhere((task) => task.taskKey == taskKey);
  }

  Future<void> _pumpQueue(Host4DownloadTaskStarter starter) async {
    while (_runningTaskKeys.length < maxConcurrentDownloads &&
        _queue.isNotEmpty) {
      final task = _queue.removeAt(0);
      if (!task.status.isActive || _runningTaskKeys.contains(task.taskKey)) {
        continue;
      }

      _runningTaskKeys.add(task.taskKey);
      try {
        await starter(task);
      } catch (error, stackTrace) {
        if (task.status.isActive) {
          task._fail(error, stackTrace);
        }
        markTerminal(task.taskKey);
      }
    }
  }

  Future<void> _pumpUntilIdle(Host4DownloadTaskStarter starter) async {
    do {
      _needsPump = false;
      await _pumpQueue(starter);
    } while (_needsPump);
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
