import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:host4_flutter_emulator_ui/host4_flutter_emulator_ui.dart';

class WebEmulatorSaveRepository implements Host4EmulatorSaveDataSource {
  WebEmulatorSaveRepository({
    required Directory rootDirectory,
    required this.gameKey,
  }) : _gameDirectory = Directory('${rootDirectory.path}/$gameKey') {
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(gameKey)) {
      throw ArgumentError.value(
        gameKey,
        'gameKey',
        'Expected a SHA-256 hex key.',
      );
    }
  }

  final String gameKey;
  final Directory _gameDirectory;

  File get _indexFile => File('${_gameDirectory.path}/index.json');
  File get _sramFile => File('${_gameDirectory.path}/sram.bin');
  Directory get _quickDirectory => Directory('${_gameDirectory.path}/quick');
  Directory _slotDirectory(int slot) =>
      Directory('${_gameDirectory.path}/slots/$slot');

  @override
  Future<Host4EmulatorSaveCatalog> load() async {
    final index = await _readIndex();
    final quick = await _readEntry(
      slot: 0,
      directory: _quickDirectory,
      modifiedAt: _modifiedAt(index['quick']),
    );
    final slots = index['slots'];
    final manual = <Host4EmulatorSaveEntry>[];
    for (var slot = 1; slot <= host4EmulatorManualSaveSlotCount; slot++) {
      final entry = await _readEntry(
        slot: slot,
        directory: _slotDirectory(slot),
        modifiedAt: slots is Map ? _modifiedAt(slots['$slot']) : null,
      );
      if (entry != null) manual.add(entry);
    }
    return Host4EmulatorSaveCatalog(quick: quick, manual: manual);
  }

  Future<void> writeQuick({
    required Uint8List state,
    Uint8List? thumbnail,
  }) async {
    final modifiedAt = DateTime.now().toUtc();
    await _writeEntry(_quickDirectory, state, thumbnail);
    final index = await _readIndex();
    index['quick'] = <String, Object?>{
      'modifiedAt': modifiedAt.toIso8601String(),
    };
    await _writeIndex(index);
  }

  Future<void> writeSlot(
    int slot, {
    required Uint8List state,
    Uint8List? thumbnail,
  }) async {
    _validateSlot(slot);
    final modifiedAt = DateTime.now().toUtc();
    await _writeEntry(_slotDirectory(slot), state, thumbnail);
    final index = await _readIndex();
    final slots = _mutableSlots(index);
    slots['$slot'] = <String, Object?>{
      'modifiedAt': modifiedAt.toIso8601String(),
    };
    index['slots'] = slots;
    await _writeIndex(index);
  }

  Future<Uint8List> readQuickState() => _readRequiredState(_quickDirectory);

  Future<Uint8List> readSlotState(int slot) {
    _validateSlot(slot);
    return _readRequiredState(_slotDirectory(slot));
  }

  Future<void> deleteQuick() async {
    if (await _quickDirectory.exists()) {
      await _quickDirectory.delete(recursive: true);
    }
    final index = await _readIndex();
    index.remove('quick');
    await _writeIndex(index);
  }

  Future<void> deleteSlot(int slot) async {
    _validateSlot(slot);
    final directory = _slotDirectory(slot);
    if (await directory.exists()) await directory.delete(recursive: true);
    final index = await _readIndex();
    final slots = _mutableSlots(index)..remove('$slot');
    index['slots'] = slots;
    await _writeIndex(index);
  }

  Future<Uint8List?> readSram() async {
    if (!await _sramFile.exists()) return null;
    return _sramFile.readAsBytes();
  }

  Future<void> writeSram(Uint8List bytes) async {
    await _gameDirectory.create(recursive: true);
    await _sramFile.writeAsBytes(bytes, flush: true);
  }

  Future<Host4EmulatorSaveEntry?> _readEntry({
    required int slot,
    required Directory directory,
    DateTime? modifiedAt,
  }) async {
    final stateFile = File('${directory.path}/state.bin');
    if (!await stateFile.exists()) return null;
    final thumbnailFile = File('${directory.path}/thumbnail.png');
    final thumbnail = await thumbnailFile.exists()
        ? await thumbnailFile.readAsBytes()
        : null;
    return Host4EmulatorSaveEntry(
      slot: slot,
      modifiedAt: modifiedAt ?? await stateFile.lastModified(),
      thumbnailBytes: thumbnail,
    );
  }

  Future<void> _writeEntry(
    Directory directory,
    Uint8List state,
    Uint8List? thumbnail,
  ) async {
    await directory.create(recursive: true);
    await File('${directory.path}/state.bin').writeAsBytes(state, flush: true);
    final thumbnailFile = File('${directory.path}/thumbnail.png');
    if (thumbnail == null) {
      if (await thumbnailFile.exists()) await thumbnailFile.delete();
    } else {
      await thumbnailFile.writeAsBytes(thumbnail, flush: true);
    }
  }

  Future<Uint8List> _readRequiredState(Directory directory) async {
    final file = File('${directory.path}/state.bin');
    if (!await file.exists()) throw StateError('存档不存在。');
    return file.readAsBytes();
  }

  Future<Map<String, dynamic>> _readIndex() async {
    if (!await _indexFile.exists()) {
      return <String, dynamic>{'version': 1, 'slots': <String, dynamic>{}};
    }
    try {
      final decoded = jsonDecode(await _indexFile.readAsString());
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      // 存档文件仍可按目录恢复，损坏的索引在下次写入时重建。
    }
    return <String, dynamic>{'version': 1, 'slots': <String, dynamic>{}};
  }

  Future<void> _writeIndex(Map<String, dynamic> index) async {
    await _gameDirectory.create(recursive: true);
    index['version'] = 1;
    index.putIfAbsent('slots', () => <String, dynamic>{});
    await _indexFile.writeAsString(jsonEncode(index), flush: true);
  }

  static Map<String, dynamic> _mutableSlots(Map<String, dynamic> index) {
    final slots = index['slots'];
    if (slots is Map) return Map<String, dynamic>.from(slots);
    return <String, dynamic>{};
  }

  static DateTime? _modifiedAt(Object? metadata) {
    if (metadata is! Map) return null;
    final value = metadata['modifiedAt'];
    return value is String ? DateTime.tryParse(value) : null;
  }

  static void _validateSlot(int slot) {
    if (slot < 1 || slot > host4EmulatorManualSaveSlotCount) {
      throw ArgumentError.value(slot, 'slot', 'Expected a slot from 1 to 5.');
    }
  }
}
