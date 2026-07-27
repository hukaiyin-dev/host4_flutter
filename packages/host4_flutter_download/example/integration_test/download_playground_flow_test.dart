import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_download/host4_flutter_download.dart';
import 'package:host4_flutter_download_example/download_playground_page.dart';
import 'package:integration_test/integration_test.dart';

import 'package:host4_flutter_download_example/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('FF009 playground covers range multi-task controls', (
    tester,
  ) async {
    final urlA = _optionalEnvUrl('HOST4_RANGE_URL_A');
    final urlB = _optionalEnvUrl('HOST4_RANGE_URL_B');
    if (urlA == null || urlB == null) {
      _skipIntegration('HOST4_RANGE_URL_A and HOST4_RANGE_URL_B');
      return;
    }

    app.main();
    await tester.pumpAndSettle();

    await _addDownload(tester, urlA, expectedTaskCount: 1);
    final taskA = _firstTaskKey();
    await _waitForItemStatus(tester, taskA, Host4DownloadStatus.downloading);
    await _waitForItemProgress(tester, taskA);

    await _addDownload(tester, urlB, expectedTaskCount: 2);
    final taskB = _taskKeys().singleWhere((taskKey) => taskKey != taskA);
    await _waitForItemStatus(tester, taskB, Host4DownloadStatus.downloading);
    await _waitForItemProgress(tester, taskB);

    await _addDownload(tester, urlA, expectedTaskCount: 2);
    expect(_taskKeys(), hasLength(2));

    await tester.tap(_scopedKey(DownloadPlaygroundIds.taskPauseButton, taskA));
    await tester.pumpAndSettle();
    await _waitForItemStatus(tester, taskA, Host4DownloadStatus.paused);
    await _waitForItemStatus(tester, taskB, Host4DownloadStatus.downloading);

    await tester.tap(_scopedKey(DownloadPlaygroundIds.taskResumeButton, taskA));
    await tester.pumpAndSettle();
    await _waitForItemStatus(tester, taskA, Host4DownloadStatus.downloading);

    await tester.tap(_scopedKey(DownloadPlaygroundIds.taskCancelButton, taskB));
    await tester.pumpAndSettle();
    await _waitForItemStatus(tester, taskB, Host4DownloadStatus.canceled);

    await _waitForItemCompletion(tester, taskA);
  });

  testWidgets('FF009 playground covers no-range 200 fallback flow', (
    tester,
  ) async {
    final url = _optionalEnvUrl('HOST4_NO_RANGE_URL');
    if (url == null) {
      _skipIntegration('HOST4_NO_RANGE_URL');
      return;
    }

    app.main();
    await tester.pumpAndSettle();

    await _addDownload(tester, url, expectedTaskCount: 1);
    final firstTaskKey = _firstTaskKey();
    await _waitForItemStatus(
      tester,
      firstTaskKey,
      Host4DownloadStatus.downloading,
    );
    await _waitForItemProgress(tester, firstTaskKey);

    await tester.tap(
      _scopedKey(DownloadPlaygroundIds.taskCancelButton, firstTaskKey),
    );
    await tester.pumpAndSettle();
    await _waitForItemStatus(
      tester,
      firstTaskKey,
      Host4DownloadStatus.canceled,
    );

    await _addDownload(tester, url, expectedTaskCount: 1);
    final activeTaskKey = _taskKeys().last;
    await _waitForItemCompletion(tester, activeTaskKey);
  });
}

String? _optionalEnvUrl(String name) {
  final value = switch (name) {
    'HOST4_RANGE_URL_A' => const String.fromEnvironment('HOST4_RANGE_URL_A'),
    'HOST4_RANGE_URL_B' => const String.fromEnvironment('HOST4_RANGE_URL_B'),
    'HOST4_NO_RANGE_URL' => const String.fromEnvironment('HOST4_NO_RANGE_URL'),
    _ => '',
  };
  return value.isEmpty ? null : value;
}

void _skipIntegration(String missing) {
  markTestSkipped(
    'device_required/python_server: missing --dart-define for $missing.',
  );
}

Finder _key(String id) => find.byKey(ValueKey<String>(id));

Finder _scopedKey(String base, String taskKey) {
  return _key(DownloadPlaygroundIds.scoped(base, taskKey));
}

Future<void> _addDownload(
  WidgetTester tester,
  String url, {
  required int expectedTaskCount,
}) async {
  await tester.enterText(_key(DownloadPlaygroundIds.urlInput), url);
  await tester.tap(_key(DownloadPlaygroundIds.addButton));
  await tester.pump();
  await _waitUntil(
    tester,
    () => _taskKeys().length == expectedTaskCount,
    timeout: const Duration(seconds: 10),
  );
}

String _firstTaskKey() {
  return _taskKeys().first;
}

List<String> _taskKeys() {
  return find
      .byWidgetPredicate((widget) {
        final key = widget.key;
        return key is ValueKey<String> &&
            key.value.startsWith('${DownloadPlaygroundIds.taskItem}.');
      })
      .evaluate()
      .map((element) => element.widget.key)
      .whereType<ValueKey<String>>()
      .map((key) => key.value)
      .map(
        (value) => value.substring('${DownloadPlaygroundIds.taskItem}.'.length),
      )
      .toList();
}

Future<void> _waitForItemStatus(
  WidgetTester tester,
  String taskKey,
  Host4DownloadStatus status,
) async {
  await _waitUntil(
    tester,
    () => find
        .descendant(
          of: _scopedKey(DownloadPlaygroundIds.taskItem, taskKey),
          matching: find.textContaining(status.name),
        )
        .evaluate()
        .isNotEmpty,
  );
}

Future<void> _waitForItemProgress(WidgetTester tester, String taskKey) async {
  await _waitUntil(tester, () {
    final progress = tester.widget<LinearProgressIndicator>(
      find.descendant(
        of: _scopedKey(DownloadPlaygroundIds.taskProgress, taskKey),
        matching: find.byType(LinearProgressIndicator),
      ),
    );
    return (progress.value ?? 0) > 0;
  });
}

Future<void> _waitForItemCompletion(WidgetTester tester, String taskKey) async {
  await _waitUntil(
    tester,
    () => find
        .descendant(
          of: _scopedKey(DownloadPlaygroundIds.taskItem, taskKey),
          matching: find.textContaining('Completed'),
        )
        .evaluate()
        .isNotEmpty,
    timeout: const Duration(seconds: 45),
  );
  expect(_scopedKey(DownloadPlaygroundIds.filePath, taskKey), findsOneWidget);
}

Future<void> _waitUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (condition()) {
      return;
    }
  }
  fail('Timed out waiting for condition after ${timeout.inSeconds}s.');
}
