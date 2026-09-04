import 'host4_web_emulator_core_cache.dart';
import 'host4_web_emulator_system.dart';

class Host4WebEmulatorLaunchConfig {
  Host4WebEmulatorLaunchConfig({
    required this.system,
    required this.romName,
    this.romFileUrl,
    this.romBase64,
    this.sramBase64,
  }) {
    if (romFileUrl == null && romBase64 == null) {
      throw ArgumentError('Either romFileUrl or romBase64 is required.');
    }
  }

  final Host4WebEmulatorSystem system;
  final Uri? romFileUrl;
  final String? romBase64;
  final String? sramBase64;
  final String romName;

  Map<String, Object?> toJson({ResolvedCoreData? resolvedCoreData}) {
    final core = system.core;
    return <String, Object?>{
      'system': system.name,
      'launcherType': system.launcherType,
      'core': core.name,
      if (romFileUrl != null) 'romFileUrl': romFileUrl.toString(),
      if (romBase64 != null) 'romBase64': romBase64,
      if (sramBase64 != null) 'sramBase64': sramBase64,
      'romName': romName,
      if (resolvedCoreData != null) ...{
        'coreJsBase64': resolvedCoreData.jsBase64,
        'coreWasmBase64': resolvedCoreData.wasmBase64,
      } else
        'coreZipUrl': core.zipUrl,
    };
  }
}
