import 'package:flutter/material.dart';
import 'package:host4_flutter_download/host4_flutter_download.dart';

class DownloadPlaygroundIds {
  static const urlInput = 'download_playground.url_input';
  static const addButton = 'download_playground.add_button';
  static const taskList = 'download_playground.task_list';
  static const taskItem = 'download_playground.task_item';
  static const taskStatus = 'download_playground.task_status';
  static const taskProgress = 'download_playground.task_progress';
  static const taskPauseButton = 'download_playground.task_pause_button';
  static const taskResumeButton = 'download_playground.task_resume_button';
  static const taskCancelButton = 'download_playground.task_cancel_button';
  static const taskClearButton = 'download_playground.task_clear_button';
  static const filePath = 'download_playground.file_path';
  static const clearCompletedButton =
      'download_playground.clear_completed_button';

  static const values = <String>[
    urlInput,
    addButton,
    taskList,
    taskItem,
    taskStatus,
    taskProgress,
    taskPauseButton,
    taskResumeButton,
    taskCancelButton,
    taskClearButton,
    filePath,
    clearCompletedButton,
  ];

  static String scoped(String base, String taskKey) => '$base.$taskKey';

  @Deprecated('Use addButton.')
  static const startButton = addButton;
  @Deprecated('Use taskPauseButton with a task-scoped key.')
  static const pauseButton = taskPauseButton;
  @Deprecated('Use taskResumeButton with a task-scoped key.')
  static const resumeButton = taskResumeButton;
  @Deprecated('Use taskCancelButton with a task-scoped key.')
  static const cancelButton = taskCancelButton;
  @Deprecated('Use taskClearButton with a task-scoped key.')
  static const clearButton = taskClearButton;
  @Deprecated('Use taskProgress with a task-scoped key.')
  static const progress = taskProgress;
  @Deprecated('Use taskStatus with a task-scoped key.')
  static const status = taskStatus;
}

abstract class DownloadPlaygroundController {
  Future<Host4DownloadTask> download(Uri url);
  Future<void> clear(String taskKey);
  Future<int> clearCompleted();
}

class Host4DownloadPlaygroundController
    implements DownloadPlaygroundController {
  Host4DownloadPlaygroundController([Host4Download? download])
    : _download = download ?? Host4Download();

  final Host4Download _download;

  @override
  Future<Host4DownloadTask> download(Uri url) {
    return _download.download(url);
  }

  @override
  Future<void> clear(String taskKey) {
    return _download.clear(taskKey);
  }

  @override
  Future<int> clearCompleted() {
    return _download.clearCompleted();
  }
}

class DownloadPlaygroundTaskItem {
  DownloadPlaygroundTaskItem({required this.task});

  Host4DownloadTask task;
  Host4DownloadedFile? file;
  String? message;

  String get taskKey => task.taskKey;
  Uri get url => task.request.url;
}

class DownloadPlaygroundPage extends StatefulWidget {
  const DownloadPlaygroundPage({
    super.key,
    DownloadPlaygroundController? controller,
  }) : controller = controller ?? const _DefaultController();

  final DownloadPlaygroundController controller;

  @override
  State<DownloadPlaygroundPage> createState() => _DownloadPlaygroundPageState();
}

class _DownloadPlaygroundPageState extends State<DownloadPlaygroundPage> {
  final TextEditingController _urlController = TextEditingController();
  final List<DownloadPlaygroundTaskItem> _items = [];
  final Map<Host4DownloadTask, VoidCallback> _taskListeners = {};
  final Set<Host4DownloadTask> _resultWatchers = {};
  String? _globalMessage;

  @override
  void dispose() {
    for (final entry in _taskListeners.entries) {
      entry.key.removeListener(entry.value);
    }
    _taskListeners.clear();
    _resultWatchers.clear();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Download Playground')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              key: const ValueKey<String>(DownloadPlaygroundIds.urlInput),
              controller: _urlController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Firmware URL',
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addDownload(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    key: const ValueKey<String>(
                      DownloadPlaygroundIds.addButton,
                    ),
                    onPressed: _addDownload,
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey<String>(
                      DownloadPlaygroundIds.clearCompletedButton,
                    ),
                    onPressed: _items.isEmpty ? null : _clearCompleted,
                    icon: const Icon(Icons.cleaning_services_outlined),
                    label: const Text('Clear Done'),
                  ),
                ),
              ],
            ),
            if (_globalMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _globalMessage!,
                style: TextStyle(color: _messageColor(context, _globalMessage)),
              ),
            ],
            const SizedBox(height: 16),
            _TaskList(
              items: _items,
              onPause: _pause,
              onResume: _resume,
              onCancel: _cancel,
              onClear: _clear,
            ),
          ],
        ),
      ),
    );
  }

  Color _messageColor(BuildContext context, String? message) {
    final value = message ?? '';
    if (value.contains('failed') ||
        value.contains('Cannot') ||
        value.contains('Invalid')) {
      return Theme.of(context).colorScheme.error;
    }
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  Future<void> _addDownload() async {
    final raw = _urlController.text.trim();
    try {
      final uri = Uri.parse(raw);
      final task = await widget.controller.download(uri);
      if (!mounted) {
        return;
      }

      final existing = _findItem(task.taskKey);
      setState(() {
        _globalMessage = null;
        if (existing == null) {
          final item = DownloadPlaygroundTaskItem(task: task);
          _items.add(item);
          _watchTask(item);
        } else if (existing.task != task && !existing.task.status.isActive) {
          _unwatchTask(existing.task);
          existing.task = task;
          existing.file = null;
          existing.message = null;
          _watchTask(existing);
        }
      });
    } catch (error) {
      _showGlobalError(error);
    }
  }

  void _watchTask(DownloadPlaygroundTaskItem item) {
    final task = item.task;
    if (_taskListeners.containsKey(task)) {
      _watchResult(item);
      return;
    }

    void listener() {
      if (!mounted) {
        return;
      }
      setState(() {});
    }

    _taskListeners[task] = listener;
    task.addListener(listener);
    _watchResult(item);
  }

  void _unwatchTask(Host4DownloadTask task) {
    final listener = _taskListeners.remove(task);
    if (listener != null) {
      task.removeListener(listener);
    }
    _resultWatchers.remove(task);
  }

  void _watchResult(DownloadPlaygroundTaskItem item) {
    if (!_resultWatchers.add(item.task)) {
      return;
    }
    item.task.result
        .then((file) {
          if (!mounted) {
            return;
          }
          setState(() {
            item.file = file;
            item.message = 'Completed ${file.fileName} (${file.size} bytes)';
          });
        })
        .catchError((Object error) {
          if (!mounted) {
            return;
          }
          setState(() {
            item.file = null;
            item.message = error.toString();
          });
        });
  }

  void _pause(DownloadPlaygroundTaskItem item) {
    _control(item, item.task.pause);
  }

  void _resume(DownloadPlaygroundTaskItem item) {
    _control(item, item.task.resume);
  }

  void _cancel(DownloadPlaygroundTaskItem item) {
    _control(item, item.task.cancel);
  }

  Future<void> _clear(DownloadPlaygroundTaskItem item) async {
    try {
      await widget.controller.clear(item.taskKey);
      if (!mounted) {
        return;
      }
      setState(() {
        _items.removeWhere((candidate) => candidate.taskKey == item.taskKey);
        _unwatchTask(item.task);
        _globalMessage = 'Cleared ${_shortTaskKey(item.taskKey)}';
      });
    } catch (error) {
      _showItemError(item, error);
    }
  }

  Future<void> _clearCompleted() async {
    try {
      final removed = await widget.controller.clearCompleted();
      if (!mounted) {
        return;
      }
      setState(() {
        final terminalItems = _items
            .where((item) => !item.task.status.isActive)
            .toList();
        for (final item in terminalItems) {
          _unwatchTask(item.task);
        }
        _items.removeWhere((item) => !item.task.status.isActive);
        _globalMessage = 'Cleared $removed terminal task(s)';
      });
    } catch (error) {
      _showGlobalError(error);
    }
  }

  void _control(DownloadPlaygroundTaskItem item, VoidCallback action) {
    try {
      action();
      setState(() {
        item.message = null;
      });
    } catch (error) {
      _showItemError(item, error);
    }
  }

  void _showItemError(DownloadPlaygroundTaskItem item, Object error) {
    if (!mounted) {
      return;
    }
    setState(() {
      item.message = error.toString();
    });
  }

  void _showGlobalError(Object error) {
    if (!mounted) {
      return;
    }
    setState(() {
      _globalMessage = error.toString();
    });
  }

  DownloadPlaygroundTaskItem? _findItem(String taskKey) {
    for (final item in _items) {
      if (item.taskKey == taskKey) {
        return item;
      }
    }
    return null;
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList({
    required this.items,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
    required this.onClear,
  });

  final List<DownloadPlaygroundTaskItem> items;
  final ValueChanged<DownloadPlaygroundTaskItem> onPause;
  final ValueChanged<DownloadPlaygroundTaskItem> onResume;
  final ValueChanged<DownloadPlaygroundTaskItem> onCancel;
  final ValueChanged<DownloadPlaygroundTaskItem> onClear;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Column(
        key: ValueKey<String>(DownloadPlaygroundIds.taskList),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text('No download tasks')],
      );
    }

    return Column(
      key: const ValueKey<String>(DownloadPlaygroundIds.taskList),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in items) ...[
          _TaskItem(
            item: item,
            onPause: onPause,
            onResume: onResume,
            onCancel: onCancel,
            onClear: onClear,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _TaskItem extends StatelessWidget {
  const _TaskItem({
    required this.item,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
    required this.onClear,
  });

  final DownloadPlaygroundTaskItem item;
  final ValueChanged<DownloadPlaygroundTaskItem> onPause;
  final ValueChanged<DownloadPlaygroundTaskItem> onResume;
  final ValueChanged<DownloadPlaygroundTaskItem> onCancel;
  final ValueChanged<DownloadPlaygroundTaskItem> onClear;

  @override
  Widget build(BuildContext context) {
    final task = item.task;
    final status = task.status;
    final taskKey = task.taskKey;
    final theme = Theme.of(context);

    return Card(
      key: const ValueKey<String>(DownloadPlaygroundIds.taskItem),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: KeyedSubtree(
        key: ValueKey<String>(
          DownloadPlaygroundIds.scoped(DownloadPlaygroundIds.taskItem, taskKey),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.url.toString(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              KeyedSubtree(
                key: ValueKey<String>(
                  DownloadPlaygroundIds.scoped(
                    DownloadPlaygroundIds.taskStatus,
                    taskKey,
                  ),
                ),
                child: Text(
                  'Status: ${status.name}',
                  key: const ValueKey<String>(DownloadPlaygroundIds.taskStatus),
                  style: theme.textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: 6),
              KeyedSubtree(
                key: ValueKey<String>(
                  DownloadPlaygroundIds.scoped(
                    DownloadPlaygroundIds.taskProgress,
                    taskKey,
                  ),
                ),
                child: LinearProgressIndicator(
                  key: const ValueKey<String>(
                    DownloadPlaygroundIds.taskProgress,
                  ),
                  value: task.progress,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    key: const ValueKey<String>(
                      DownloadPlaygroundIds.taskPauseButton,
                    ),
                    child: OutlinedButton.icon(
                      key: ValueKey<String>(
                        DownloadPlaygroundIds.scoped(
                          DownloadPlaygroundIds.taskPauseButton,
                          taskKey,
                        ),
                      ),
                      onPressed: status == Host4DownloadStatus.downloading
                          ? () => onPause(item)
                          : null,
                      icon: const Icon(Icons.pause),
                      label: const Text('Pause'),
                    ),
                  ),
                  SizedBox(
                    key: const ValueKey<String>(
                      DownloadPlaygroundIds.taskResumeButton,
                    ),
                    child: OutlinedButton.icon(
                      key: ValueKey<String>(
                        DownloadPlaygroundIds.scoped(
                          DownloadPlaygroundIds.taskResumeButton,
                          taskKey,
                        ),
                      ),
                      onPressed: status == Host4DownloadStatus.paused
                          ? () => onResume(item)
                          : null,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Resume'),
                    ),
                  ),
                  SizedBox(
                    key: const ValueKey<String>(
                      DownloadPlaygroundIds.taskCancelButton,
                    ),
                    child: OutlinedButton.icon(
                      key: ValueKey<String>(
                        DownloadPlaygroundIds.scoped(
                          DownloadPlaygroundIds.taskCancelButton,
                          taskKey,
                        ),
                      ),
                      onPressed: status.isActive ? () => onCancel(item) : null,
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                    ),
                  ),
                  SizedBox(
                    key: const ValueKey<String>(
                      DownloadPlaygroundIds.taskClearButton,
                    ),
                    child: OutlinedButton.icon(
                      key: ValueKey<String>(
                        DownloadPlaygroundIds.scoped(
                          DownloadPlaygroundIds.taskClearButton,
                          taskKey,
                        ),
                      ),
                      onPressed: () => onClear(item),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Clear'),
                    ),
                  ),
                ],
              ),
              if (item.message != null) ...[
                const SizedBox(height: 8),
                Text(
                  item.message!,
                  style: TextStyle(color: _messageColor(context, item.message)),
                ),
              ],
              const SizedBox(height: 8),
              KeyedSubtree(
                key: ValueKey<String>(
                  DownloadPlaygroundIds.scoped(
                    DownloadPlaygroundIds.filePath,
                    taskKey,
                  ),
                ),
                child: _FileInfo(file: item.file),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileInfo extends StatelessWidget {
  const _FileInfo({required this.file});

  final Host4DownloadedFile? file;

  @override
  Widget build(BuildContext context) {
    final file = this.file;
    if (file == null) {
      return SelectableText(
        'No completed file',
        key: const ValueKey<String>(DownloadPlaygroundIds.filePath),
      );
    }

    return Column(
      key: const ValueKey<String>(DownloadPlaygroundIds.filePath),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('File: ${file.fileName}', softWrap: true),
        Text('Size: ${file.size} bytes'),
        if (file.observedSha256.isNotEmpty)
          SelectableText('SHA256: ${file.observedSha256}'),
        SelectableText(file.localPath),
      ],
    );
  }
}

String _shortTaskKey(String taskKey) {
  if (taskKey.length <= 8) {
    return taskKey;
  }
  return taskKey.substring(0, 8);
}

Color _messageColor(BuildContext context, String? message) {
  final value = message ?? '';
  if (value.contains('failed') ||
      value.contains('Cannot') ||
      value.contains('canceled')) {
    return Theme.of(context).colorScheme.error;
  }
  return Theme.of(context).colorScheme.onSurfaceVariant;
}

class _DefaultController implements DownloadPlaygroundController {
  const _DefaultController();

  static final Host4Download _download = Host4Download();

  @override
  Future<Host4DownloadTask> download(Uri url) {
    return _download.download(url);
  }

  @override
  Future<void> clear(String taskKey) {
    return _download.clear(taskKey);
  }

  @override
  Future<int> clearCompleted() {
    return _download.clearCompleted();
  }
}
