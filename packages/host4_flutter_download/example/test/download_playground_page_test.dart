import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_download/host4_flutter_download.dart';
import 'package:host4_flutter_download_example/download_playground_page.dart';

import 'fake_download_task.dart';

void main() {
  testWidgets('FF008 exposes multi-task stable identifiers', (tester) async {
    final controller = FakeDownloadPlaygroundController();
    await tester.pumpWidget(_app(controller));

    expect(
      find.byKey(const ValueKey<String>(DownloadPlaygroundIds.urlInput)),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>(DownloadPlaygroundIds.addButton)),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>(DownloadPlaygroundIds.taskList)),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>(DownloadPlaygroundIds.clearCompletedButton),
      ),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('download_playground.url_input')),
      'https://example.com/firmware.bin',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('download_playground.add_button')),
    );
    await tester.pump();

    expect(controller.downloadedUrls, [
      Uri.parse('https://example.com/firmware.bin'),
    ]);
    final taskKey = controller.lastTask!.taskKey;
    expect(
      find.byKey(ValueKey<String>('download_playground.task_item.$taskKey')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey<String>('download_playground.task_status.$taskKey')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        ValueKey<String>('download_playground.task_progress.$taskKey'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        ValueKey<String>('download_playground.task_pause_button.$taskKey'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        ValueKey<String>('download_playground.task_resume_button.$taskKey'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        ValueKey<String>('download_playground.task_cancel_button.$taskKey'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        ValueKey<String>('download_playground.task_clear_button.$taskKey'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey<String>('download_playground.file_path.$taskKey')),
      findsOneWidget,
    );
    expect(find.textContaining('downloading'), findsOneWidget);
  });

  testWidgets('FF008 adds two different URLs and reuses same active URL', (
    tester,
  ) async {
    final controller = FakeDownloadPlaygroundController();
    await tester.pumpWidget(_app(controller));
    await _add(tester, 'https://example.com/firmware-a.bin');
    await _add(tester, 'https://example.com/firmware-b.bin');
    await _add(tester, 'https://example.com/firmware-a.bin');

    expect(controller.downloadedUrls, <Uri>[
      Uri.parse('https://example.com/firmware-a.bin'),
      Uri.parse('https://example.com/firmware-b.bin'),
      Uri.parse('https://example.com/firmware-a.bin'),
    ]);
    expect(
      find.byKey(const ValueKey<String>(DownloadPlaygroundIds.taskItem)),
      findsNWidgets(2),
    );
    expect(
      find.descendant(
        of: find.byKey(
          ValueKey<String>(
            'download_playground.task_item.${controller.tasks[0].taskKey}',
          ),
        ),
        matching: find.textContaining('firmware-a.bin'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('firmware-b.bin'), findsOneWidget);
  });

  testWidgets('FF009 same URL after terminal task replaces old item', (
    tester,
  ) async {
    final controller = FakeDownloadPlaygroundController();
    await tester.pumpWidget(_app(controller));
    await _add(tester, 'https://example.com/firmware-a.bin');
    final first = controller.lastTask!;
    first.cancel();
    await tester.pump();

    await _add(tester, 'https://example.com/firmware-a.bin');
    final second = controller.lastTask!;

    expect(second, isNot(same(first)));
    expect(second.taskKey, first.taskKey);
    expect(
      find.byKey(const ValueKey<String>(DownloadPlaygroundIds.taskItem)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(
          ValueKey<String>('download_playground.task_item.${second.taskKey}'),
        ),
        matching: find.textContaining('downloading'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('FF008 item controls affect only selected task', (tester) async {
    final controller = FakeDownloadPlaygroundController();
    await tester.pumpWidget(_app(controller));
    await _add(tester, 'https://example.com/firmware-a.bin');
    await _add(tester, 'https://example.com/firmware-b.bin');
    final first = controller.tasks[0];
    final second = controller.tasks[1];

    expect(
      _button(
        tester,
        'download_playground.task_pause_button.${first.taskKey}',
      ).enabled,
      isTrue,
    );
    expect(
      _button(
        tester,
        'download_playground.task_resume_button.${first.taskKey}',
      ).enabled,
      isFalse,
    );
    expect(
      _button(
        tester,
        'download_playground.task_cancel_button.${first.taskKey}',
      ).enabled,
      isTrue,
    );
    expect(
      _button(
        tester,
        'download_playground.task_clear_button.${first.taskKey}',
      ).enabled,
      isTrue,
    );

    await tester.tap(
      find.byKey(
        ValueKey<String>(
          'download_playground.task_pause_button.${first.taskKey}',
        ),
      ),
    );
    await tester.pump();

    expect(first.status, Host4DownloadStatus.paused);
    expect(second.status, Host4DownloadStatus.downloading);
    expect(
      find.descendant(
        of: find.byKey(
          ValueKey<String>('download_playground.task_item.${first.taskKey}'),
        ),
        matching: find.textContaining('paused'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(
          ValueKey<String>('download_playground.task_item.${second.taskKey}'),
        ),
        matching: find.textContaining('downloading'),
      ),
      findsOneWidget,
    );
    expect(
      _button(
        tester,
        'download_playground.task_pause_button.${first.taskKey}',
      ).enabled,
      isFalse,
    );
    expect(
      _button(
        tester,
        'download_playground.task_resume_button.${first.taskKey}',
      ).enabled,
      isTrue,
    );
  });

  testWidgets('FF008 clear error keeps selected active item visible', (
    tester,
  ) async {
    final controller = FakeDownloadPlaygroundController();
    await tester.pumpWidget(_app(controller));
    await _add(tester, 'https://example.com/firmware.bin');
    final task = controller.lastTask!;

    await tester.tap(
      find.byKey(
        ValueKey<String>(
          'download_playground.task_clear_button.${task.taskKey}',
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Cannot clear active download'), findsOneWidget);
    expect(
      find.byKey(
        ValueKey<String>('download_playground.task_progress.${task.taskKey}'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('downloading'), findsOneWidget);
  });

  testWidgets('progress refreshes while download is active', (tester) async {
    final controller = FakeDownloadPlaygroundController();
    await tester.pumpWidget(_app(controller));
    await _add(tester, 'https://example.com/firmware.bin');
    final task = controller.lastTask!;

    (task as FakeHost4DownloadTask).setProgress(0.75);
    await tester.pump();

    final progress = tester.widget<LinearProgressIndicator>(
      find.descendant(
        of: find.byKey(
          ValueKey<String>('download_playground.task_progress.${task.taskKey}'),
        ),
        matching: find.byType(LinearProgressIndicator),
      ),
    );
    expect(progress.value, 0.75);
  });

  testWidgets('completed task displays file information', (tester) async {
    final controller = FakeDownloadPlaygroundController();
    await tester.pumpWidget(_app(controller));
    await _add(tester, 'https://example.com/firmware.bin');
    final task = controller.lastTask!;

    controller.completeLast(
      const Host4DownloadedFile(
        localPath: '/app/support/host4/downloads/tasks/abc/firmware.bin',
        fileName: 'firmware-super-long-name.bin',
        size: 4096,
        expectedSha256: 'expected-sha256',
        observedSha256: 'observed-sha256',
        verified: true,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('File: firmware-super-long-name.bin'), findsOneWidget);
    expect(find.textContaining('observed-sha256'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(
          ValueKey<String>('download_playground.file_path.${task.taskKey}'),
        ),
        matching: find.textContaining(
          '/app/support/host4/downloads/tasks/abc/firmware.bin',
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('Size: 4096 bytes'), findsOneWidget);
  });

  testWidgets('FF008 long text wraps without overlapping controls', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    final controller = FakeDownloadPlaygroundController();
    await tester.pumpWidget(_app(controller));
    await _add(
      tester,
      'https://example.com/releases/very/long/path/OTA_GDF-G911405_3C03_V1.0_260716A_with_extra_query_payload.bin?sha256=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
    );
    final task = controller.lastTask!;
    controller.completeLast(
      const Host4DownloadedFile(
        localPath:
            '/app/support/host4/downloads/tasks/0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef/OTA_GDF-G911405_3C03_V1.0_260716A.bin',
        fileName: 'OTA_GDF-G911405_3C03_V1.0_260716A.bin',
        size: 1024,
        expectedSha256:
            '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
        observedSha256:
            'fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210',
        verified: true,
      ),
    );
    await tester.pump();
    await tester.pump();

    final item = tester.getRect(
      find.byKey(
        ValueKey<String>('download_playground.task_item.${task.taskKey}'),
      ),
    );
    final controls = tester
        .getRect(
          find.byKey(
            ValueKey<String>(
              'download_playground.task_cancel_button.${task.taskKey}',
            ),
          ),
        )
        .expandToInclude(
          tester.getRect(
            find.byKey(
              ValueKey<String>(
                'download_playground.task_clear_button.${task.taskKey}',
              ),
            ),
          ),
        );
    final filePath = tester.getRect(
      find.byKey(
        ValueKey<String>('download_playground.file_path.${task.taskKey}'),
      ),
    );

    expect(item.right, lessThanOrEqualTo(393));
    expect(filePath.overlaps(controls), isFalse);
  });
}

Widget _app(FakeDownloadPlaygroundController controller) {
  return MaterialApp(home: DownloadPlaygroundPage(controller: controller));
}

Future<void> _add(WidgetTester tester, String url) async {
  await tester.enterText(
    find.byKey(const ValueKey<String>('download_playground.url_input')),
    url,
  );
  await tester.tap(
    find.byKey(const ValueKey<String>('download_playground.add_button')),
  );
  await tester.pump();
}

ButtonStyleButton _button(WidgetTester tester, String key) {
  return tester.widget<ButtonStyleButton>(find.byKey(ValueKey<String>(key)));
}

class FakeDownloadPlaygroundController implements DownloadPlaygroundController {
  final downloadedUrls = <Uri>[];
  final tasks = <Host4DownloadTask>[];
  Host4DownloadTask? lastTask;

  @override
  Future<Host4DownloadTask> download(Uri url) async {
    downloadedUrls.add(url);
    final request = Host4DownloadRequest(url: url);
    final existing = tasks
        .where(
          (task) =>
              task.request.taskKey == request.taskKey && task.status.isActive,
        )
        .firstOrNull;
    if (existing != null) {
      lastTask = existing;
      return existing;
    }
    final task = FakeHost4DownloadTask(request: request, progress: 0.25);
    tasks.add(task);
    lastTask = task;
    return task;
  }

  @override
  Future<void> clear(String taskKey) async {
    final task = tasks.where((item) => item.taskKey == taskKey).firstOrNull;
    if (task == null) {
      throw StateError('Unknown task.');
    }
    if (task.status.isActive) {
      throw StateError('Cannot clear active download.');
    }
    tasks.remove(task);
  }

  @override
  Future<int> clearCompleted() async {
    final before = tasks.length;
    tasks.removeWhere((task) => !task.status.isActive);
    return before - tasks.length;
  }

  void completeLast(Host4DownloadedFile file) {
    (lastTask! as FakeHost4DownloadTask).completeWith(file);
  }
}
