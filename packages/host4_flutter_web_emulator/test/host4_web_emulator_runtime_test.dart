import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_web_emulator/host4_flutter_web_emulator.dart';

void main() {
  test('maps GB GBC and GBA launcher types to the mgba core', () {
    expect(
      Host4WebEmulatorSystem.fromLauncherType(5),
      Host4WebEmulatorSystem.gb,
    );
    expect(
      Host4WebEmulatorSystem.fromLauncherType(14),
      Host4WebEmulatorSystem.gbc,
    );
    expect(
      Host4WebEmulatorSystem.fromLauncherType(21),
      Host4WebEmulatorSystem.gba,
    );

    expect(
      Host4WebEmulatorSystem.values.map((system) => system.coreName).toSet(),
      <String>{'mgba'},
    );
  });

  test('rejects launcher types that are not handled by web emulator', () {
    expect(
      () => Host4WebEmulatorSystem.fromLauncherType(1),
      throwsArgumentError,
    );
  });

  test('detects supported systems from ROM file names', () {
    expect(
      Host4WebEmulatorSystem.fromRomFileName('demo.gb'),
      Host4WebEmulatorSystem.gb,
    );
    expect(
      Host4WebEmulatorSystem.fromRomFileName('demo.GBC'),
      Host4WebEmulatorSystem.gbc,
    );
    expect(
      Host4WebEmulatorSystem.fromRomFileName('demo.gba'),
      Host4WebEmulatorSystem.gba,
    );
    expect(Host4WebEmulatorSystem.tryFromRomFileName('demo.nes'), isNull);
    // ZIP 文件不能从文件名推断 system
    expect(Host4WebEmulatorSystem.tryFromRomFileName('roms.zip'), isNull);
    expect(Host4WebEmulatorSystem.isZipFile('roms.zip'), isTrue);
    expect(Host4WebEmulatorSystem.isZipFile('demo.gb'), isFalse);
  });

  test('keeps the first POC core URL pinned to the competitor version', () {
    expect(Host4WebEmulatorCore.mgba.name, 'mgba');
    expect(Host4WebEmulatorCore.mgba.version, 'v1.22.2');
    expect(
      Host4WebEmulatorCore.mgba.zipUrl,
      'https://cdn.jsdelivr.net/gh/arianrhodsandlot/retroarch-emscripten-build@v1.22.2/retroarch/mgba_libretro.zip',
    );
    expect(
      Host4WebEmulatorCore.mgba.zipSha256,
      'd195371c3ea626c9246e9d3ab82ded4d93f3f99f85634af1588724cc44d47644',
    );
  });

  test('builds the initial launch payload consumed by index.html', () {
    final config = Host4WebEmulatorLaunchConfig(
      system: Host4WebEmulatorSystem.gba,
      romFileUrl: Uri.file('/tmp/demo.gba'),
      romName: 'demo.gba',
    );

    expect(config.toJson(), <String, Object?>{
      'system': 'gba',
      'launcherType': 21,
      'core': 'mgba',
      'romFileUrl': 'file:///tmp/demo.gba',
      'romName': 'demo.gba',
      'coreZipUrl':
          'https://cdn.jsdelivr.net/gh/arianrhodsandlot/retroarch-emscripten-build@v1.22.2/retroarch/mgba_libretro.zip',
    });
  });

  test('bridge messages use the agreed response envelope', () {
    final message = Host4WebEmulatorBridgeMessage.success(
      type: 'launched',
      requestId: 'request-1',
      data: <String, Object?>{'system': 'gba'},
    );

    expect(message.toJson(), <String, Object?>{
      'type': 'launched',
      'requestId': 'request-1',
      'ok': true,
      'data': <String, Object?>{'system': 'gba'},
      'error': null,
    });
  });

  test('uses packaged local emulator assets as the first entry point', () {
    expect(
      Host4WebEmulatorAssets.indexHtml,
      'packages/host4_flutter_web_emulator/assets/emulator/index.html',
    );
    expect(
      Host4WebEmulatorAssets.nostalgistUmd,
      'packages/host4_flutter_web_emulator/assets/emulator/nostalgist.0.19.0.umd.js',
    );
  });

  test('generates keyEvent JS with correct Nostalgist parameters', () {
    final js = Host4WebEmulatorJavaScript.keyEvent('a', action: 'down');
    expect(js, contains('window.Host4WebEmulator.keyEvent('));
    expect(js, contains('"button":"a"'));
    expect(js, contains('"action":"down"'));
    expect(js, contains('"player":1'));
  });

  test('serializes launch config into the JavaScript bridge call', () {
    final config = Host4WebEmulatorLaunchConfig(
      system: Host4WebEmulatorSystem.gb,
      romFileUrl: Uri.file('/tmp/demo.gb'),
      romName: 'demo.gb',
    );

    expect(
      Host4WebEmulatorJavaScript.launch(config),
      contains('window.Host4WebEmulator.launch('),
    );
    expect(
      Host4WebEmulatorJavaScript.launch(config),
      contains('"romFileUrl":"file:///tmp/demo.gb"'),
    );
    expect(
      Host4WebEmulatorJavaScript.launch(config),
      contains('"core":"mgba"'),
    );
  });
}
