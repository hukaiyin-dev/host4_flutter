part of '../../host4_flutter_download.dart';

class Host4DownloadedFile {
  const Host4DownloadedFile({
    required this.localPath,
    required this.fileName,
    required this.size,
    required this.expectedSha256,
    required this.observedSha256,
    required this.verified,
  });

  final String localPath;
  final String fileName;
  final int size;
  final String? expectedSha256;
  final String observedSha256;
  final bool verified;
}
