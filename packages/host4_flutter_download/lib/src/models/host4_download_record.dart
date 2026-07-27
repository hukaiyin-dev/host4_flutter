part of '../../host4_flutter_download.dart';

class Host4DownloadRecord {
  const Host4DownloadRecord({
    required this.taskKey,
    required this.url,
    required this.fileName,
    required this.status,
    required this.size,
    required this.expectedSha256,
    required this.observedSha256,
    required this.updatedAt,
    this.localPath,
    this.completedAt,
  });

  final String taskKey;
  final Uri url;
  final String fileName;
  final Host4DownloadStatus status;
  final int? size;
  final String? expectedSha256;
  final String? observedSha256;
  final DateTime updatedAt;
  final String? localPath;
  final DateTime? completedAt;
}
