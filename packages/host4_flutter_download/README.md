# host4_flutter_download

Task-based HTTP downloads for Host4 Flutter applications. Each download owns
its progress, cancellation token, result future, and task-specific temporary
file.

```dart
final task = await Host4Download().download(
  Uri.parse('https://example.com/controller.bin'),
);
task.addListener(() => print(task.progress));
final file = await task.result;
print(file.localPath);
```
