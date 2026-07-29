import 'dart:async';
import 'dart:io';

import 'package:host4_flutter_download/host4_flutter_download.dart';
import 'package:test/test.dart';

void main() {
  late Directory downloadsDirectory;

  setUp(() async {
    downloadsDirectory = await Directory.systemTemp.createTemp(
      'host4_download_test_',
    );
  });

  tearDown(() async {
    if (await downloadsDirectory.exists()) {
      await downloadsDirectory.delete(recursive: true);
    }
  });

  test('downloads into task-local storage and reports file metadata', () async {
    final bytes = List<int>.generate(64 * 1024, (index) => index % 251);
    final server = await _startServer((request) async {
      request.response.contentLength = bytes.length;
      request.response.add(bytes);
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));
    final uri = Uri.parse(
      'http://${server.address.host}:${server.port}/firmware/controller.bin',
    );
    final download = Host4Download(
      directoryProvider: () async => downloadsDirectory,
    );

    final task = await download.download(uri);
    final progress = <double>[];
    task.addListener(() => progress.add(task.progress));
    final file = await task.result;

    expect(file.fileName, 'controller.bin');
    expect(file.size, bytes.length);
    expect(await File(file.localPath).readAsBytes(), bytes);
    expect(progress, isNotEmpty);
    expect(progress.last, 1);
    expect(task.progress, 1);
    expect(
      File(file.localPath).parent.parent.path,
      downloadsDirectory.absolute.path,
    );
  });

  test('cancels only its task and deletes the partial file', () async {
    final firstChunkSent = Completer<void>();
    final finishResponse = Completer<void>();
    final server = await _startServer((request) async {
      request.response.contentLength = 1024 * 1024;
      request.response.add(List<int>.filled(1024, 1));
      await request.response.flush();
      firstChunkSent.complete();
      await finishResponse.future;
      request.response.add(List<int>.filled(1024 * 1023, 2));
      await request.response.close();
    });
    addTearDown(() async {
      if (!finishResponse.isCompleted) finishResponse.complete();
      await server.close(force: true);
    });
    final uri = Uri.parse(
      'http://${server.address.host}:${server.port}/slow.bin',
    );
    final download = Host4Download(
      directoryProvider: () async => downloadsDirectory,
    );

    final task = await download.download(uri);
    await firstChunkSent.future;
    task.cancel();

    await expectLater(
      task.result,
      throwsA(isA<Host4DownloadCanceledException>()),
    );
    expect(downloadsDirectory.listSync(), isEmpty);
    expect(task.cancel, throwsStateError);
  });

  test('rejects non-network URLs before creating a task', () async {
    final download = Host4Download(
      directoryProvider: () async => downloadsDirectory,
    );

    await expectLater(
      download.download(Uri.file('/tmp/controller.bin')),
      throwsArgumentError,
    );
    expect(downloadsDirectory.listSync(), isEmpty);
  });

  test('uses a safe fallback when the URL has no file name', () async {
    final server = await _startServer((request) async {
      request.response.add(<int>[1, 2, 3]);
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));
    final uri = Uri.parse('http://${server.address.host}:${server.port}/');
    final download = Host4Download(
      directoryProvider: () async => downloadsDirectory,
    );

    final task = await download.download(uri);
    final file = await task.result;

    expect(file.fileName, 'download.bin');
    expect(file.size, 3);
  });
}

Future<HttpServer> _startServer(
  Future<void> Function(HttpRequest request) handler,
) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    try {
      await handler(request);
    } on HttpException {
      // Cancellation may close the response while a test server is writing.
    } on SocketException {
      // Cancellation may close the socket while a test server is writing.
    } on StateError {
      // Cancellation may settle the response before the writer resumes.
    }
  });
  return server;
}
