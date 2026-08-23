import 'host4_web_emulator_core.dart';

enum Host4WebEmulatorSystem {
  gb(launcherType: 5, romExtension: '.gb'),
  gbc(launcherType: 14, romExtension: '.gbc'),
  gba(launcherType: 21, romExtension: '.gba');

  const Host4WebEmulatorSystem({
    required this.launcherType,
    required this.romExtension,
  });

  final int launcherType;
  final String romExtension;

  String get coreName => core.name;

  Host4WebEmulatorCore get core => Host4WebEmulatorCore.mgba;

  static Host4WebEmulatorSystem fromLauncherType(int launcherType) {
    for (final system in values) {
      if (system.launcherType == launcherType) return system;
    }
    throw ArgumentError.value(
      launcherType,
      'launcherType',
      'GB/GBC/GBA web emulator only supports launcher types 5, 14, and 21.',
    );
  }

  static Host4WebEmulatorSystem fromRomFileName(String fileName) {
    final system = tryFromRomFileName(fileName);
    if (system != null) return system;
    throw ArgumentError.value(
      fileName,
      'fileName',
      'GB/GBC/GBA web emulator only supports .gb, .gbc, and .gba ROMs.',
    );
  }

  /// 从文件名推断 system。支持 `.gb`、`.gbc`、`.gba` 和 `.zip`。
  ///
  /// `.zip` 文件由 Nostalgist 自动解压，但 Dart 侧无法从 ZIP 文件名推断
  /// system 类型，此时返回 `null`，调用方需要让用户手动选择或从其它来源确定。
  static Host4WebEmulatorSystem? tryFromRomFileName(String fileName) {
    final normalized = fileName.toLowerCase();
    for (final system in values) {
      if (normalized.endsWith(system.romExtension)) return system;
    }
    return null;
  }

  /// `.zip` 文件是否可能包含 GB/GBC/GBA ROM。
  static bool isZipFile(String fileName) =>
      fileName.toLowerCase().endsWith('.zip');
}
