import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_download/host4_flutter_download.dart';
import 'package:host4_flutter_download_example/download_playground_page.dart';

import 'fake_download_task.dart';

void main() {
  testWidgets('FF008 portrait multi-task state matches golden baseline', (
    tester,
  ) async {
    await _setPortraitViewport(tester);
    final controller = _IdleDownloadController();
    await tester.pumpWidget(_app(controller));
    await _add(tester, 'https://example.com/firmware-a.bin');
    await _add(
      tester,
      'https://example.com/releases/OTA_GDF-G911405_3C03_V1.0_260716A.bin',
    );
    await tester.pumpAndSettle();

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
      find.byKey(const ValueKey<String>(DownloadPlaygroundIds.taskItem)),
      findsNWidgets(2),
    );
    expect(
      find.byKey(
        const ValueKey<String>(DownloadPlaygroundIds.clearCompletedButton),
      ),
      findsOneWidget,
    );
    for (final task in controller.tasks) {
      expect(
        find.byKey(
          ValueKey<String>('download_playground.task_item.${task.taskKey}'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          ValueKey<String>('download_playground.task_status.${task.taskKey}'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          ValueKey<String>('download_playground.task_progress.${task.taskKey}'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          ValueKey<String>(
            'download_playground.task_pause_button.${task.taskKey}',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          ValueKey<String>(
            'download_playground.task_resume_button.${task.taskKey}',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          ValueKey<String>(
            'download_playground.task_cancel_button.${task.taskKey}',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          ValueKey<String>(
            'download_playground.task_clear_button.${task.taskKey}',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          ValueKey<String>('download_playground.file_path.${task.taskKey}'),
        ),
        findsOneWidget,
      );
    }

    await expectLater(
      find.byType(DownloadPlaygroundPage),
      matchesGoldenFile('goldens/download_playground_multi_task_portrait.png'),
    );
  });

  testWidgets(
    'FF008 portrait stable identifiers stay visible without overlap',
    (tester) async {
      await _setPortraitViewport(tester);
      final controller = _IdleDownloadController();
      await tester.pumpWidget(_app(controller));
      await _add(tester, 'https://example.com/firmware-a.bin');
      await _add(tester, 'https://example.com/firmware-b.bin');
      await tester.pumpAndSettle();

      const viewport = Rect.fromLTWH(0, 0, 393, 852);
      expect(
        _rectFor(tester, DownloadPlaygroundIds.urlInput),
        _isInside(viewport),
      );
      expect(
        _rectFor(tester, DownloadPlaygroundIds.addButton),
        _isInside(viewport),
      );
      expect(
        _rectFor(tester, DownloadPlaygroundIds.taskList),
        _isInside(viewport),
      );
      expect(
        _rectFor(tester, DownloadPlaygroundIds.clearCompletedButton),
        _isInside(viewport),
      );

      final url = _rectFor(tester, DownloadPlaygroundIds.urlInput);
      final add = _rectFor(tester, DownloadPlaygroundIds.addButton);
      final list = _rectFor(tester, DownloadPlaygroundIds.taskList);

      _expectNoOverlap(url, add, 'URL input and add button');
      _expectNoOverlap(add, list, 'add button and task list');

      for (final task in controller.tasks) {
        final status = _rectFor(
          tester,
          'download_playground.task_status.${task.taskKey}',
        );
        final progress = _rectFor(
          tester,
          'download_playground.task_progress.${task.taskKey}',
        );
        final cancel = _rectFor(
          tester,
          'download_playground.task_cancel_button.${task.taskKey}',
        );
        final filePath = _rectFor(
          tester,
          'download_playground.file_path.${task.taskKey}',
        );

        expect(status, _isInside(viewport), reason: task.taskKey);
        expect(progress, _isInside(viewport), reason: task.taskKey);
        expect(cancel, _isInside(viewport), reason: task.taskKey);
        expect(filePath, _isInside(viewport), reason: task.taskKey);
        _expectNoOverlap(status, progress, 'task status and progress');
        _expectNoOverlap(progress, cancel, 'task progress and controls');
        _expectNoOverlap(cancel, filePath, 'task controls and file path');
      }
    },
  );
}

Widget _app(_IdleDownloadController controller) {
  return MaterialApp(home: DownloadPlaygroundPage(controller: controller));
}

Future<void> _add(WidgetTester tester, String url) async {
  await tester.enterText(
    find.byKey(const ValueKey<String>(DownloadPlaygroundIds.urlInput)),
    url,
  );
  await tester.tap(
    find.byKey(const ValueKey<String>(DownloadPlaygroundIds.addButton)),
  );
  await tester.pump();
}

Future<void> _setPortraitViewport(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(393, 852));
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() async {
    tester.view.resetDevicePixelRatio();
    await tester.binding.setSurfaceSize(null);
  });
}

Rect _rectFor(WidgetTester tester, String id) {
  final finder = find.byKey(ValueKey<String>(id));
  return tester.getRect(finder);
}

Matcher _isInside(Rect viewport) {
  return predicate<Rect>(
    (rect) =>
        rect.left >= viewport.left &&
        rect.top >= viewport.top &&
        rect.right <= viewport.right &&
        rect.bottom <= viewport.bottom,
    'inside $viewport',
  );
}

void _expectNoOverlap(Rect first, Rect second, String label) {
  expect(
    first.overlaps(second),
    isFalse,
    reason: '$label overlap: $first intersects $second',
  );
}

class _IdleDownloadController implements DownloadPlaygroundController {
  final tasks = <Host4DownloadTask>[];

  @override
  Future<Host4DownloadTask> download(Uri url) {
    final request = Host4DownloadRequest(url: url);
    final task = FakeHost4DownloadTask(
      request: request,
      progress: tasks.isEmpty ? 0.35 : 0.65,
    );
    tasks.add(task);
    return Future.value(task);
  }

  @override
  Future<void> clear(String taskKey) async {}

  @override
  Future<int> clearCompleted() async => 0;
}
