part of '../../host4_flutter_download.dart';

class Host4DownloadCleanupResult {
  const Host4DownloadCleanupResult({
    required this.limitBytes,
    required this.beforeBytes,
    required this.afterBytes,
    required this.deletedCount,
    required this.deletedTaskKeys,
  });

  final int limitBytes;
  final int beforeBytes;
  final int afterBytes;
  final int deletedCount;
  final List<String> deletedTaskKeys;

  int get freedBytes => beforeBytes - afterBytes;
  bool get cleaned => deletedCount > 0;
}
