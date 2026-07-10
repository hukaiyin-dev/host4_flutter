import 'package:flutter/services.dart';

const _channel = MethodChannel('host4_flutter_demo/ios_tf_card');

Future<IosTfCardScanResult> scanIosTfCard({bool forcePick = false}) async {
  final payload = await _channel.invokeMethod<Object?>(
    'scanRoms',
    forcePick ? const <String, Object?>{'forcePick': true} : null,
  );
  if (payload == null) {
    return const IosTfCardScanResult.empty();
  }
  if (payload is! Map) {
    throw const FormatException('Invalid iOS TF card scan payload.');
  }
  return IosTfCardScanResult.fromMap(payload);
}

class IosTfCardScanResult {
  const IosTfCardScanResult({
    required this.rootPath,
    required this.romsPath,
    required this.platformCount,
    required this.gameCount,
    required this.platforms,
    required this.games,
  });

  const IosTfCardScanResult.empty()
    : rootPath = '',
      romsPath = '',
      platformCount = 0,
      gameCount = 0,
      platforms = const [],
      games = const [];

  factory IosTfCardScanResult.fromMap(Map<dynamic, dynamic> map) {
    final platforms = _readList(
      map['platforms'],
    ).map(IosTfCardPlatform.fromMap).toList(growable: false);
    final games = _readList(
      map['games'],
    ).map(IosTfCardGame.fromMap).toList(growable: false);

    return IosTfCardScanResult(
      rootPath: _readString(map['rootPath']),
      romsPath: _readString(map['romsPath']),
      platformCount: _readInt(map['platformCount'], fallback: platforms.length),
      gameCount: _readInt(map['gameCount'], fallback: games.length),
      platforms: platforms,
      games: games,
    );
  }

  final String rootPath;
  final String romsPath;
  final int platformCount;
  final int gameCount;
  final List<IosTfCardPlatform> platforms;
  final List<IosTfCardGame> games;
}

class IosTfCardPlatform {
  const IosTfCardPlatform({
    required this.name,
    required this.fullName,
    required this.directory,
    required this.gameCount,
  });

  factory IosTfCardPlatform.fromMap(Map<dynamic, dynamic> map) {
    return IosTfCardPlatform(
      name: _readString(map['name']),
      fullName: _readString(map['fullName']),
      directory: _readString(map['directory']),
      gameCount: _readInt(map['gameCount']),
    );
  }

  final String name;
  final String fullName;
  final String directory;
  final int gameCount;
}

class IosTfCardGame {
  const IosTfCardGame({
    required this.platform,
    required this.platformName,
    required this.name,
    required this.fileName,
    required this.relativePath,
    required this.absolutePath,
    this.image,
    this.video,
    this.desc,
  });

  factory IosTfCardGame.fromMap(Map<dynamic, dynamic> map) {
    return IosTfCardGame(
      platform: _readString(map['platform']),
      platformName: _readString(map['platformName']),
      name: _readString(map['name']),
      fileName: _readString(map['fileName']),
      relativePath: _readString(map['relativePath']),
      absolutePath: _readString(map['absolutePath']),
      image: _readNullableString(map['image']),
      video: _readNullableString(map['video']),
      desc: _readNullableString(map['desc']),
    );
  }

  final String platform;
  final String platformName;
  final String name;
  final String fileName;
  final String relativePath;
  final String absolutePath;
  final String? image;
  final String? video;
  final String? desc;
}

List<Map<dynamic, dynamic>> _readList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<Map>().cast<Map<dynamic, dynamic>>().toList();
}

String _readString(Object? value) => value?.toString() ?? '';

String? _readNullableString(Object? value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) return null;
  return text;
}

int _readInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}
