import 'dart:typed_data';

const int host4EmulatorManualSaveSlotCount = 5;

class Host4EmulatorSaveEntry {
  const Host4EmulatorSaveEntry({
    required this.slot,
    required this.modifiedAt,
    this.thumbnailBytes,
  });

  final int slot;
  final DateTime modifiedAt;
  final Uint8List? thumbnailBytes;
}

class Host4EmulatorSaveCatalog {
  const Host4EmulatorSaveCatalog({
    this.quick,
    this.manual = const <Host4EmulatorSaveEntry>[],
  });

  final Host4EmulatorSaveEntry? quick;
  final List<Host4EmulatorSaveEntry> manual;

  Host4EmulatorSaveEntry? manualAt(int slot) {
    for (final entry in manual) {
      if (entry.slot == slot) return entry;
    }
    return null;
  }
}

abstract interface class Host4EmulatorSaveDataSource {
  Future<Host4EmulatorSaveCatalog> load();
}
