import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('host4_flutter_simulator_storage');
const EventChannel _events = EventChannel(
  'host4_flutter_simulator_storage/tf_card_scan_events',
);

class Host4SimulatorStorage {
  const Host4SimulatorStorage._();

  /// Emits TF-card scan progress. Subscribe before starting a scan so no
  /// discovered ROM is missed.
  static Stream<Host4TfCardScanEvent> get tfCardRomScanEvents {
    return _events
        .receiveBroadcastStream()
        .where((event) => event is Map)
        .cast<Map>()
        .map(Host4TfCardScanEvent.fromMap);
  }

  /// Starts an iOS TF-card scan. Results arrive through [tfCardRomScanEvents].
  static Future<String> startTfCardRomScan({
    required List<Host4RomSystemSpec> systems,
    bool forcePick = false,
  }) async {
    if (systems.isEmpty) {
      throw ArgumentError.value(systems, 'systems', 'must not be empty');
    }
    final payload = await _channel
        .invokeMethod<Object?>('startTfCardRomScan', <String, Object?>{
          'forcePick': forcePick,
          'systems': systems.map((system) => system.toMap()).toList(),
        });
    if (payload is! Map) {
      throw const FormatException('Invalid TF card scan start payload.');
    }
    final scanId = _readString(payload['scanId']);
    if (scanId.isEmpty) {
      throw const FormatException('Missing TF card scan ID.');
    }
    return scanId;
  }

  static Future<bool> isTfCardAccessible() async {
    return await _channel.invokeMethod<bool>('isTfCardAccessible') ?? false;
  }

  static Future<Host4TfCardScanResult> scanTfCardRoms({
    required List<Host4RomSystemSpec> systems,
    bool forcePick = false,
  }) async {
    if (systems.isEmpty) {
      throw ArgumentError.value(systems, 'systems', 'must not be empty');
    }
    final payload = await _channel
        .invokeMethod<Object?>('scanTfCardRoms', <String, Object?>{
          'forcePick': forcePick,
          'systems': systems.map((system) => system.toMap()).toList(),
        });
    if (payload is! Map) {
      throw const FormatException('Invalid TF card scan payload.');
    }
    return Host4TfCardScanResult.fromMap(payload);
  }
}

enum Host4TfCardScanPhase {
  started,
  platformStarted,
  gameFound,
  platformCompleted,
  completed,
  skipped,
  failed,
  unknown,
}

class Host4TfCardScanEvent {
  const Host4TfCardScanEvent({
    required this.phase,
    required this.scanId,
    this.game,
    this.type = 0,
    this.platformName,
    this.message,
  });

  factory Host4TfCardScanEvent.fromMap(Map<dynamic, dynamic> map) {
    final phaseName = _readString(map['phase']);
    return Host4TfCardScanEvent(
      phase: Host4TfCardScanPhase.values.firstWhere(
        (phase) => phase.name == phaseName,
        orElse: () => Host4TfCardScanPhase.unknown,
      ),
      scanId: _readString(map['scanId']),
      game: map['game'] is Map
          ? Host4ScannedRom.fromMap(map['game'] as Map<dynamic, dynamic>)
          : null,
      type: _readInt(map['type']),
      platformName: _readNullableString(map['platformName']),
      message: _readNullableString(map['message']),
    );
  }

  final Host4TfCardScanPhase phase;
  final String scanId;
  final Host4ScannedRom? game;
  final int type;
  final String? platformName;
  final String? message;
}

class Host4RomSystemSpec {
  const Host4RomSystemSpec({
    required this.type,
    required this.name,
    required this.fullName,
    required this.dir,
    required this.extensions,
  });

  final int type;
  final String name;
  final String fullName;
  final String dir;
  final List<String> extensions;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'type': type,
      'name': name,
      'fullName': fullName,
      'dir': dir,
      'extensions': extensions,
    };
  }
}

class Host4TfCardScanResult {
  const Host4TfCardScanResult({
    required this.scanId,
    required this.rootPath,
    required this.romsPath,
    required this.platforms,
    required this.games,
  });

  factory Host4TfCardScanResult.fromMap(Map<dynamic, dynamic> map) {
    return Host4TfCardScanResult(
      scanId: _readString(map['scanId']),
      rootPath: _readString(map['rootPath']),
      romsPath: _readString(map['romsPath']),
      platforms: _readMapList(
        map['platforms'],
      ).map(Host4ScannedPlatform.fromMap).toList(growable: false),
      games: _readMapList(
        map['games'],
      ).map(Host4ScannedRom.fromMap).toList(growable: false),
    );
  }

  final String scanId;
  final String rootPath;
  final String romsPath;
  final List<Host4ScannedPlatform> platforms;
  final List<Host4ScannedRom> games;
}

class Host4ScannedPlatform {
  const Host4ScannedPlatform({
    required this.type,
    required this.name,
    required this.fullName,
    required this.dir,
    required this.path,
    required this.gameCount,
  });

  factory Host4ScannedPlatform.fromMap(Map<dynamic, dynamic> map) {
    return Host4ScannedPlatform(
      type: _readInt(map['type']),
      name: _readString(map['name']),
      fullName: _readString(map['fullName']),
      dir: _readString(map['dir']),
      path: _readString(map['path']),
      gameCount: _readInt(map['gameCount']),
    );
  }

  final int type;
  final String name;
  final String fullName;
  final String dir;
  final String path;
  final int gameCount;
}

class Host4ScannedRom {
  const Host4ScannedRom({
    required this.type,
    required this.platformName,
    required this.platformFullName,
    required this.name,
    required this.fileName,
    required this.rootPath,
    required this.resourcePath,
    required this.romPath,
    this.imagePath,
    this.videoPath,
    this.description,
  });

  factory Host4ScannedRom.fromMap(Map<dynamic, dynamic> map) {
    return Host4ScannedRom(
      type: _readInt(map['type']),
      platformName: _readString(map['platformName']),
      platformFullName: _readString(map['platformFullName']),
      name: _readString(map['name']),
      fileName: _readString(map['fileName']),
      rootPath: _readString(map['rootPath']),
      resourcePath: _readString(map['resourcePath']),
      romPath: _readString(map['romPath']),
      imagePath: _readNullableString(map['imagePath']),
      videoPath: _readNullableString(map['videoPath']),
      description: _readNullableString(map['description']),
    );
  }

  final int type;
  final String platformName;
  final String platformFullName;
  final String name;
  final String fileName;
  final String rootPath;
  final String resourcePath;
  final String romPath;
  final String? imagePath;
  final String? videoPath;
  final String? description;
}

List<Map<dynamic, dynamic>> _readMapList(Object? value) {
  if (value is! List) return const <Map<dynamic, dynamic>>[];
  return value.whereType<Map>().cast<Map<dynamic, dynamic>>().toList();
}

String _readString(Object? value) => value?.toString() ?? '';

String? _readNullableString(Object? value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) return null;
  return text;
}

int _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
