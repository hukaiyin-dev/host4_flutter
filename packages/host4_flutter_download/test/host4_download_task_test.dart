import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_download/host4_flutter_download.dart';

void main() {
  const expectedSha256 =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const observedSha256 =
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

  group('Host4DownloadRequest', () {
    test('normalizes expectedSha256 and derives a stable URL task key', () {
      final request = Host4DownloadRequest(
        url: Uri.parse(
          'HTTPS://Example.COM:443/firmware/../firmware.bin?b=2&a=1#section',
        ),
        expectedSize: 1024,
        expectedSha256: expectedSha256.toUpperCase(),
        forceRefresh: true,
      );
      final sameUrlDifferentValidation = Host4DownloadRequest(
        url: Uri.parse('https://example.com/firmware.bin?b=2&a=1'),
        expectedSize: 2048,
        expectedSha256: observedSha256,
      );
      final defaultPort = Host4DownloadRequest(
        url: Uri.parse('http://EXAMPLE.com:80'),
      );
      final implicitPath = Host4DownloadRequest(
        url: Uri.parse('http://example.com/'),
      );

      expect(
        request.url,
        Uri.parse('https://example.com/firmware.bin?b=2&a=1'),
      );
      expect(request.expectedSha256, expectedSha256);
      expect(request.taskKey, hasLength(64));
      expect(request.taskKey, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(sameUrlDifferentValidation.taskKey, request.taskKey);
      expect(defaultPort.url, Uri.parse('http://example.com/'));
      expect(implicitPath.taskKey, defaultPort.taskKey);
      expect(
        Host4DownloadRequest(
          url: Uri.parse('https://example.com/other.bin?b=2&a=1'),
        ).taskKey,
        isNot(request.taskKey),
      );
    });

    test('rejects unsupported URL and validation metadata', () {
      expect(
        () => Host4DownloadRequest(url: Uri.parse('file:///tmp/a.bin')),
        throwsArgumentError,
      );
      expect(
        () => Host4DownloadRequest(
          url: Uri.parse('https://example.com/a.bin'),
          expectedSize: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => Host4DownloadRequest(
          url: Uri.parse('https://example.com/a.bin'),
          expectedSize: -1,
        ),
        throwsArgumentError,
      );
      expect(
        () => Host4DownloadRequest(
          url: Uri.parse('https://example.com/a.bin'),
          expectedSha256: 'abc',
        ),
        throwsArgumentError,
      );
      expect(
        () => Host4DownloadRequest(
          url: Uri.parse('https://example.com/a.bin'),
          expectedSha256:
              'zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz',
        ),
        throwsArgumentError,
      );
    });
  });

  group('Host4DownloadedFile', () {
    test(
      'describes a completed local firmware file with verification fields',
      () {
        final file = Host4DownloadedFile(
          localPath: '/app/support/host4/downloads/firmware.bin',
          fileName: 'firmware.bin',
          size: 1024,
          expectedSha256: expectedSha256,
          observedSha256: observedSha256,
          verified: true,
        );

        expect(file.localPath, '/app/support/host4/downloads/firmware.bin');
        expect(file.fileName, 'firmware.bin');
        expect(file.size, 1024);
        expect(file.expectedSha256, expectedSha256);
        expect(file.observedSha256, observedSha256);
        expect(file.verified, isTrue);
      },
    );
  });

  group('Host4DownloadRecord', () {
    test('summarizes a managed download for public queries', () {
      final updatedAt = DateTime.utc(2026, 7, 23, 10, 30);
      final completedAt = DateTime.utc(2026, 7, 23, 10, 31);
      final record = Host4DownloadRecord(
        taskKey:
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
        url: Uri.parse('https://example.com/firmware.bin'),
        fileName: 'firmware.bin',
        status: Host4DownloadStatus.completed,
        size: 4096,
        expectedSha256: expectedSha256,
        observedSha256: observedSha256,
        updatedAt: updatedAt,
        localPath: '/app/support/host4/downloads/firmware.bin',
        completedAt: completedAt,
      );

      expect(
        record.taskKey,
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
      );
      expect(record.url, Uri.parse('https://example.com/firmware.bin'));
      expect(record.fileName, 'firmware.bin');
      expect(record.status, Host4DownloadStatus.completed);
      expect(record.size, 4096);
      expect(record.expectedSha256, expectedSha256);
      expect(record.observedSha256, observedSha256);
      expect(record.updatedAt, updatedAt);
      expect(record.localPath, '/app/support/host4/downloads/firmware.bin');
      expect(record.completedAt, completedAt);
    });
  });

  group('Host4DownloadCleanupResult', () {
    test('describes capacity cleanup outcome', () {
      const result = Host4DownloadCleanupResult(
        limitBytes: 1024,
        beforeBytes: 2048,
        afterBytes: 512,
        deletedCount: 2,
        deletedTaskKeys: <String>['a', 'b'],
      );

      expect(result.limitBytes, 1024);
      expect(result.beforeBytes, 2048);
      expect(result.afterBytes, 512);
      expect(result.deletedCount, 2);
      expect(result.deletedTaskKeys, <String>['a', 'b']);
      expect(result.freedBytes, 1536);
      expect(result.cleaned, isTrue);
    });

    test('describes no-op cleanup as explainable result', () {
      const result = Host4DownloadCleanupResult(
        limitBytes: 1024,
        beforeBytes: 900,
        afterBytes: 900,
        deletedCount: 0,
        deletedTaskKeys: <String>[],
      );

      expect(result.freedBytes, 0);
      expect(result.cleaned, isFalse);
    });
  });

  group('Host4DownloadTask', () {
    test('exposes initial public task state', () {
      final request = Host4DownloadRequest(
        url: Uri.parse('https://example.com/firmware.bin'),
      );
      final task = Host4DownloadTask(
        taskKey: request.taskKey,
        request: request,
      );

      expect(task.taskKey, request.taskKey);
      expect(task.request, same(request));
      expect(task.status, Host4DownloadStatus.queued);
      expect(task.progress, 0);
      expect(task.result, isA<Future<Host4DownloadedFile>>());
    });

    test('notifies listeners for public cancellation', () async {
      final request = Host4DownloadRequest(
        url: Uri.parse('https://example.com/firmware.bin'),
      );
      final task = Host4DownloadTask(
        taskKey: request.taskKey,
        request: request,
      );
      final observed = <String>[];

      task.addListener(() {
        observed.add('${task.status.name}:${task.progress}');
      });

      task.cancel();

      expect(observed, <String>['canceled:0.0']);
      await expectLater(task.result, throwsStateError);
    });

    test('continues notifying listeners after a listener throws', () async {
      final previousOnError = FlutterError.onError;
      final reportedErrors = <FlutterErrorDetails>[];
      FlutterError.onError = reportedErrors.add;
      addTearDown(() {
        FlutterError.onError = previousOnError;
      });
      final request = Host4DownloadRequest(
        url: Uri.parse('https://example.com/firmware.bin'),
      );
      final task = Host4DownloadTask(
        taskKey: request.taskKey,
        request: request,
      );
      var secondListenerCalls = 0;

      task.addListener(() {
        throw StateError('listener failed');
      });
      task.addListener(() {
        secondListenerCalls += 1;
      });

      final resultExpectation = expectLater(task.result, throwsStateError);
      expect(task.cancel, returnsNormally);
      expect(task.status, Host4DownloadStatus.canceled);
      expect(secondListenerCalls, 1);
      expect(reportedErrors, hasLength(1));
      expect(reportedErrors.single.exception, isA<StateError>());
      await resultExpectation;
    });

    test('allows queued cancellation and rejects invalid controls', () async {
      final request = Host4DownloadRequest(
        url: Uri.parse('https://example.com/firmware.bin'),
      );
      final task = Host4DownloadTask(
        taskKey: request.taskKey,
        request: request,
      );

      expectControlHasNoSideEffect(task, task.pause);
      expectControlHasNoSideEffect(task, task.resume);
      final resultExpectation = expectLater(task.result, throwsStateError);
      task.cancel();

      expect(task.status, Host4DownloadStatus.canceled);
      expect(task.progress, 0);
      await resultExpectation;
      expectControlHasNoSideEffect(task, task.pause);
      expectControlHasNoSideEffect(task, task.resume);
      expectControlHasNoSideEffect(task, task.cancel);
    });
  });
}

void expectControlHasNoSideEffect(
  Host4DownloadTask task,
  void Function() control,
) {
  final status = task.status;
  final progress = task.progress;
  final result = task.result;

  expect(control, throwsStateError);
  expect(task.status, status);
  expect(task.progress, progress);
  expect(task.result, same(result));
}
