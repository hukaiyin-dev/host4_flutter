import 'package:host4_flutter_download/host4_flutter_download.dart';

class Host4DownloadManifest {
  const Host4DownloadManifest({
    required this.schemaVersion,
    required this.taskKey,
    required this.url,
    required this.fileName,
    required this.status,
    required this.expectedSize,
    required this.expectedSha256,
    required this.observedSha256,
    required this.completedAt,
    required this.updatedAt,
  });

  final int schemaVersion;
  final String taskKey;
  final String url;
  final String fileName;
  final Host4DownloadStatus status;
  final int? expectedSize;
  final String? expectedSha256;
  final String? observedSha256;
  final DateTime? completedAt;
  final DateTime updatedAt;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'taskKey': taskKey,
      'url': url,
      'fileName': fileName,
      'status': status.name,
      'expectedSize': expectedSize,
      'expectedSha256': expectedSha256,
      'observedSha256': observedSha256,
      'completedAt': completedAt?.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Host4DownloadManifest.fromJson(Map<String, Object?> json) {
    final schemaVersion = json['schemaVersion'];
    final taskKey = json['taskKey'];
    final url = json['url'];
    final fileName = json['fileName'];
    final status = json['status'];
    final updatedAt = json['updatedAt'];

    if (schemaVersion is! int ||
        taskKey is! String ||
        url is! String ||
        fileName is! String ||
        status is! String ||
        updatedAt is! String) {
      throw const FormatException('Invalid download manifest.');
    }

    final parsedStatus = Host4DownloadStatus.values
        .where((value) => value.name == status)
        .firstOrNull;
    if (parsedStatus == null) {
      throw const FormatException('Invalid download status.');
    }

    return Host4DownloadManifest(
      schemaVersion: schemaVersion,
      taskKey: taskKey,
      url: url,
      fileName: fileName,
      status: parsedStatus,
      expectedSize: _optionalInt(json['expectedSize']),
      expectedSha256: _optionalString(json['expectedSha256']),
      observedSha256: _optionalString(json['observedSha256']),
      completedAt: _optionalDateTime(json['completedAt']),
      updatedAt: DateTime.parse(updatedAt),
    );
  }

  static int? _optionalInt(Object? value) {
    if (value == null || value is int) {
      return value as int?;
    }
    throw const FormatException('Invalid integer field.');
  }

  static String? _optionalString(Object? value) {
    if (value == null || value is String) {
      return value as String?;
    }
    throw const FormatException('Invalid string field.');
  }

  static DateTime? _optionalDateTime(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw const FormatException('Invalid datetime field.');
    }
    return DateTime.parse(value);
  }
}
