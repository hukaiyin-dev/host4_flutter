import 'dart:io';

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

  test('parses bridge response payloads', () {
    final message = Host4WebEmulatorBridgeMessage.fromPayload(<String, Object?>{
      'type': 'stateSaved',
      'requestId': 'request-2',
      'ok': true,
      'data': <String, Object?>{'state': 'STATE'},
      'error': null,
    });

    expect(message.type, 'stateSaved');
    expect(message.requestId, 'request-2');
    expect(message.ok, isTrue);
  });

  test('launch payload can restore SRAM', () {
    final config = Host4WebEmulatorLaunchConfig(
      system: Host4WebEmulatorSystem.gbc,
      romBase64: 'ROM',
      romName: 'demo.gbc',
      sramBase64: 'SRAM',
    );

    expect(config.toJson()['sramBase64'], 'SRAM');
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

  test('generates SRAM export JavaScript', () {
    expect(
      Host4WebEmulatorJavaScript.saveSram('sram-1'),
      'window.Host4WebEmulator.saveSRAM("sram-1");',
    );
  });

  test('packaged web runtime wires SRAM restore and export', () async {
    final html = await File('assets/emulator/index.html').readAsString();
    expect(html, contains('sram: config.sramBase64'));
    expect(html, contains('saveSRAM: async function (requestId)'));
    expect(html, contains("report('sramSaved', requestId"));
    expect(html, contains("report('rateSet', requestId"));
  });

  test(
    'controller completes a state request from its matching bridge reply',
    () async {
      final scripts = <String>[];
      final controller = Host4WebEmulatorController.forJavaScriptExecutor(
        (script) async => scripts.add(script),
        requestIdFactory: () => 'state-1',
      );

      final resultFuture = controller.saveState();
      expect(scripts.single, contains('"state-1"'));

      expect(
        controller.handleBridgeMessage('stateSaved', <String, Object?>{
          'type': 'stateSaved',
          'requestId': 'state-1',
          'ok': true,
          'data': <String, Object?>{'state': 'STATE', 'thumbnail': 'THUMBNAIL'},
          'error': null,
        }),
        isTrue,
      );

      final result = await resultFuture;
      expect(result.stateBase64, 'STATE');
      expect(result.thumbnailBase64, 'THUMBNAIL');
    },
  );

  test('controller surfaces a failed bridge reply', () async {
    final controller = Host4WebEmulatorController.forJavaScriptExecutor(
      (_) async {},
      requestIdFactory: () => 'load-1',
    );

    final resultFuture = controller.loadState('STATE');
    controller.handleBridgeMessage('loadStateError', <String, Object?>{
      'type': 'loadStateError',
      'requestId': 'load-1',
      'ok': false,
      'data': null,
      'error': 'invalid state',
    });

    await expectLater(
      resultFuture,
      throwsA(
        isA<Host4WebEmulatorException>().having(
          (error) => error.message,
          'message',
          contains('invalid state'),
        ),
      ),
    );
  });

  test('controller keeps concurrent requests isolated by request id', () async {
    var sequence = 0;
    final controller = Host4WebEmulatorController.forJavaScriptExecutor(
      (_) async {},
      requestIdFactory: () => 'state-${++sequence}',
    );

    final first = controller.saveState();
    final second = controller.saveState();
    controller.handleBridgeMessage('stateSaved', <String, Object?>{
      'type': 'stateSaved',
      'requestId': 'state-2',
      'ok': true,
      'data': <String, Object?>{'state': 'SECOND'},
    });
    controller.handleBridgeMessage('stateSaved', <String, Object?>{
      'type': 'stateSaved',
      'requestId': 'state-1',
      'ok': true,
      'data': <String, Object?>{'state': 'FIRST'},
    });

    expect((await first).stateBase64, 'FIRST');
    expect((await second).stateBase64, 'SECOND');
  });

  test('controller times out a request without a bridge reply', () async {
    final controller = Host4WebEmulatorController.forJavaScriptExecutor(
      (_) async {},
      requestTimeout: const Duration(milliseconds: 1),
      requestIdFactory: () => 'state-timeout',
    );

    await expectLater(
      controller.saveState(),
      throwsA(
        isA<Host4WebEmulatorException>().having(
          (error) => error.message,
          'message',
          contains('timed out'),
        ),
      ),
    );
  });
}
