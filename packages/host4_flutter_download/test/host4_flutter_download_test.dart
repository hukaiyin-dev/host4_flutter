import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_download/host4_flutter_download.dart';

void main() {
  test('package root exposes the R001 download API', () {
    Future<Host4DownloadTask> callDownload(Host4Download download, Uri url) {
      return download.download(url);
    }

    expect(callDownload, isNotNull);
    expect(Host4DownloadTask, isNotNull);
    expect(Host4DownloadedFile, isNotNull);
    expect(Host4DownloadStatus.values, contains(Host4DownloadStatus.queued));
  });

  test('package root does not expose third party APIs', () {
    final entryPoint = File(
      'lib/host4_flutter_download.dart',
    ).readAsStringSync();

    expect(entryPoint, isNot(contains('flutter_download_manager')));
    expect(entryPoint, isNot(contains('dio')));
    expect(entryPoint, isNot(contains('path_provider')));
    expect(entryPoint, isNot(contains("export 'src/")));
    expect(entryPoint, isNot(contains('export "src/')));
  });
}
