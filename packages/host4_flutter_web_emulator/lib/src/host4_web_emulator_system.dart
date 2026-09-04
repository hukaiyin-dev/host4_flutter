import 'host4_web_emulator_core.dart';

enum Host4WebEmulatorSystem {
  nes(
    launcherType: 0,
    romExtensions: <String>[
      '.fds',
      '.nes',
      '.nsf',
      '.qd',
      '.rom',
      '.unif',
      '.unf',
    ],
    core: Host4WebEmulatorCore.fceumm,
  ),
  megaDrive(
    launcherType: 4,
    romExtensions: <String>['.bin', '.gen', '.md', '.sg', '.smd'],
    core: Host4WebEmulatorCore.genesisPlusGx,
  ),
  gb(
    launcherType: 5,
    romExtensions: <String>['.gb'],
    core: Host4WebEmulatorCore.mgba,
  ),
  snes(
    launcherType: 7,
    romExtensions: <String>['.smc', '.fig', '.sfc', '.swc'],
    core: Host4WebEmulatorCore.snes9x,
  ),
  gbc(
    launcherType: 14,
    romExtensions: <String>['.gbc'],
    core: Host4WebEmulatorCore.mgba,
  ),
  gba(
    launcherType: 21,
    romExtensions: <String>['.gba'],
    core: Host4WebEmulatorCore.mgba,
  );

  const Host4WebEmulatorSystem({
    required this.launcherType,
    required this.romExtensions,
    required this.core,
  });

  final int launcherType;
  final List<String> romExtensions;
  final Host4WebEmulatorCore core;

  String get coreName => core.name;

  static Host4WebEmulatorSystem fromLauncherType(int launcherType) {
    for (final system in values) {
      if (system.launcherType == launcherType) return system;
    }
    throw ArgumentError.value(
      launcherType,
      'launcherType',
      'Web emulator only supports launcher types 0, 4, 5, 7, 14, and 21.',
    );
  }

  static Host4WebEmulatorSystem fromRomFileName(String fileName) {
    final system = tryFromRomFileName(fileName);
    if (system != null) return system;
    throw ArgumentError.value(
      fileName,
      'fileName',
      'The ROM extension is not supported by the Web emulator.',
    );
  }

  /// 从文件名推断 system。`.zip` 需要由调用方提供系统类型。
  ///
  /// `.zip` 文件由 Nostalgist 自动解压，但 Dart 侧无法从 ZIP 文件名推断
  /// system 类型，此时返回 `null`，调用方需要让用户手动选择或从其它来源确定。
  static Host4WebEmulatorSystem? tryFromRomFileName(String fileName) {
    final normalized = fileName.toLowerCase();
    for (final system in values) {
      if (system.romExtensions.any(normalized.endsWith)) return system;
    }
    return null;
  }

  /// `.zip` 文件是否可能包含受支持系统的 ROM。
  static bool isZipFile(String fileName) =>
      fileName.toLowerCase().endsWith('.zip');
}
