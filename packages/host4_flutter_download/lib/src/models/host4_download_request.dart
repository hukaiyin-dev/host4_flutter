part of '../../host4_flutter_download.dart';

class Host4DownloadRequest {
  Host4DownloadRequest({
    required Uri url,
    int? expectedSize,
    String? expectedSha256,
    this.forceRefresh = false,
  }) : url = _normalizeUrl(url),
       expectedSize = _validateExpectedSize(expectedSize),
       expectedSha256 = _validateExpectedSha256(expectedSha256) {
    taskKey = _deriveTaskKey(this.url);
  }

  final Uri url;
  final int? expectedSize;
  final String? expectedSha256;
  final bool forceRefresh;
  late final String taskKey;

  static Uri _normalizeUrl(Uri url) {
    final scheme = url.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      throw ArgumentError.value(
        url,
        'url',
        'Only HTTP and HTTPS URLs are supported.',
      );
    }

    final host = url.host.toLowerCase();
    final hasDefaultPort =
        (scheme == 'http' && url.port == 80) ||
        (scheme == 'https' && url.port == 443);
    final path = url.path.isEmpty ? '/' : Uri(path: url.path).normalizePath().path;

    final normalizedPath = path.isEmpty ? '/' : path;
    final query = url.hasQuery ? url.query : null;
    if (hasDefaultPort) {
      return Uri(
        scheme: scheme,
        userInfo: url.userInfo,
        host: host,
        path: normalizedPath,
        query: query,
      );
    }

    return Uri(
      scheme: scheme,
      userInfo: url.userInfo,
      host: host,
      port: url.hasPort ? url.port : 0,
      path: normalizedPath,
      query: query,
    );
  }

  static int? _validateExpectedSize(int? expectedSize) {
    if (expectedSize != null && expectedSize <= 0) {
      throw ArgumentError.value(
        expectedSize,
        'expectedSize',
        'Expected size must be greater than zero.',
      );
    }
    return expectedSize;
  }

  static String? _validateExpectedSha256(String? expectedSha256) {
    if (expectedSha256 == null) {
      return null;
    }
    final normalized = expectedSha256.toLowerCase();
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(normalized)) {
      throw ArgumentError.value(
        expectedSha256,
        'expectedSha256',
        'Expected SHA-256 must be a 64 character hex string.',
      );
    }
    return normalized;
  }

  static String _deriveTaskKey(Uri url) {
    return sha256.convert(utf8.encode(url.toString())).toString();
  }
}
