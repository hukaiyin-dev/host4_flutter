import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_web_emulator/host4_flutter_web_emulator.dart';

void main() {
  test('maps the six product systems to their pinned web cores', () {
    expect(
      Host4WebEmulatorSystem.fromLauncherType(0),
      Host4WebEmulatorSystem.nes,
    );
    expect(
      Host4WebEmulatorSystem.fromLauncherType(4),
      Host4WebEmulatorSystem.megaDrive,
    );
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
      Host4WebEmulatorSystem.fromLauncherType(7),
      Host4WebEmulatorSystem.snes,
    );

    expect(
      <Host4WebEmulatorSystem, String>{
        for (final system in Host4WebEmulatorSystem.values)
          system: system.coreName,
      },
      <Host4WebEmulatorSystem, String>{
        Host4WebEmulatorSystem.nes: 'fceumm',
        Host4WebEmulatorSystem.megaDrive: 'genesis_plus_gx',
        Host4WebEmulatorSystem.gb: 'mgba',
        Host4WebEmulatorSystem.snes: 'snes9x',
        Host4WebEmulatorSystem.gbc: 'mgba',
        Host4WebEmulatorSystem.gba: 'mgba',
      },
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
    expect(
      Host4WebEmulatorSystem.fromRomFileName('demo.nes'),
      Host4WebEmulatorSystem.nes,
    );
    expect(
      Host4WebEmulatorSystem.fromRomFileName('demo.SFC'),
      Host4WebEmulatorSystem.snes,
    );
    expect(
      Host4WebEmulatorSystem.fromRomFileName('demo.smd'),
      Host4WebEmulatorSystem.megaDrive,
    );
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

  test('pins every product core to the same RetroArch build version', () {
    for (final core in <Host4WebEmulatorCore>{
      Host4WebEmulatorCore.fceumm,
      Host4WebEmulatorCore.genesisPlusGx,
      Host4WebEmulatorCore.mgba,
      Host4WebEmulatorCore.snes9x,
    }) {
      expect(core.version, 'v1.22.2');
      expect(core.zipUrl, contains('@v1.22.2/retroarch/'));
      expect(core.zipSha256, hasLength(64));
      expect(core.wasmSha256, hasLength(64));
    }
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

  test('keeps output probing disabled unless a debug launch opts in', () {
    final defaultConfig = Host4WebEmulatorLaunchConfig(
      system: Host4WebEmulatorSystem.nes,
      romFileUrl: Uri.file('/tmp/demo.nes'),
      romName: 'demo.nes',
    );
    final probeConfig = Host4WebEmulatorLaunchConfig(
      system: Host4WebEmulatorSystem.nes,
      romFileUrl: Uri.file('/tmp/demo.nes'),
      romName: 'demo.nes',
      outputProbeEnabled: true,
    );

    expect(defaultConfig.toJson().containsKey('outputProbeEnabled'), isFalse);
    expect(probeConfig.toJson()['outputProbeEnabled'], isTrue);
  });

  test('viewer WebRTC launch has no ROM and remains explicitly local', () {
    final config = Host4WebEmulatorLaunchConfig(
      system: Host4WebEmulatorSystem.nes,
      romName: 'local-webrtc-viewer',
      webRtcPreviewRole: 'viewer',
      webRtcSignalUrl: 'ws://127.0.0.1:8787',
      webRtcRoomId: 'local-poc',
    );

    expect(config.toJson(), containsPair('webRtcPreviewRole', 'viewer'));
    expect(
      config.toJson(),
      containsPair('webRtcSignalUrl', 'ws://127.0.0.1:8787'),
    );
    expect(config.toJson(), containsPair('webRtcRoomId', 'local-poc'));
    expect(config.toJson().containsKey('romBase64'), isFalse);
    expect(config.toJson().containsKey('romFileUrl'), isFalse);

    final html = File('assets/emulator/index.html').readAsStringSync();
    expect(html, contains("config.webRtcPreviewRole === 'viewer'"));
    expect(html, contains('probeCanvas.captureStream(60)'));
    expect(html, contains('retro_video_refresh'));
  });

  test('publisher JavaScript carries the selected WebRTC transport', () {
    final script = Host4WebEmulatorJavaScript.startWebRtcPublisher(
      signalUrl: 'ws://127.0.0.1:8787',
      roomId: 'local-poc',
      transport: 'data',
      captureIntervalMs: 33,
      controlProfile: 'nes',
      controlLayoutStyle: 'silicone',
      siliconeLayoutVariant: 'retroTraditional',
      maskEnabled: true,
      maskPath: 'pantas-ios://simulator-mask/nes',
      controlsCollapsed: true,
    );

    expect(script, contains('"webRtcTransport":"data"'));
    expect(script, contains('"webRtcCaptureIntervalMs":33'));
    expect(script, contains('"webRtcControlProfile":"nes"'));
    expect(script, contains('"webRtcControlLayoutStyle":"silicone"'));
    expect(
      script,
      contains('"webRtcSiliconeLayoutVariant":"retroTraditional"'),
    );
    expect(script, contains('"webRtcMaskEnabled":true'));
    expect(
      script,
      contains('"webRtcMaskPath":"pantas-ios://simulator-mask/nes"'),
    );
    expect(script, contains('"webRtcControlsCollapsed":true'));
  });

  test('viewer JavaScript sends a bounded remote input event', () {
    final script = Host4WebEmulatorJavaScript.sendWebRtcInput(
      'a',
      action: 'down',
      player: 2,
    );

    expect(script, contains('sendWebRtcInput'));
    expect(script, contains('"button":"a"'));
    expect(script, contains('"action":"down"'));
    expect(script, contains('"player":2'));
  });

  test('viewer retries signalling when it opens before a host starts sharing', () {
    final html = File('assets/emulator/index.html').readAsStringSync();

    expect(html, contains('function scheduleViewerSignalReconnect(reason)'));
    expect(html, contains('webrtc_signal_reconnect_scheduled'));
    expect(html, contains('connectSignalSocket();'));
  });

  test('runtime validates and injects remote input only on the host', () {
    final html = File('assets/emulator/index.html').readAsStringSync();

    expect(html, contains("host4-remote-input"));
    expect(html, contains('function isValidWebRtcInput(event)'));
    expect(html, contains('remote_input_rejected'));
    expect(html, contains('remote_input_dispatched'));
    expect(html, contains('Host4WebEmulator.keyEvent(event)'));
    expect(html, contains('webrtc_remote_metadata'));
    expect(html, contains('controlProfile: state.controlProfile'));
    expect(html, contains('maskEnabled: state.maskEnabled'));
    expect(html, contains('controlsCollapsed: state.controlsCollapsed'));
    // A DataChannel can become open before the viewer installs its message
    // handler. Metadata must be retried briefly so a viewer never remains on
    // the safe NES fallback merely because of that connection-time race.
    expect(html, contains('function sendPublisherMetadata(channel)'));
    expect(html, contains('window.setTimeout(function () {'));
    expect(html, contains('sendPublisherMetadata(channel);'));
  });

  test('WebRTC visual-latency marker is debug-only and opt-in', () {
    final normal = Host4WebEmulatorLaunchConfig(
      system: Host4WebEmulatorSystem.nes,
      romFileUrl: Uri.file('/tmp/demo.nes'),
      romName: 'demo.nes',
    );
    final measured = Host4WebEmulatorLaunchConfig(
      system: Host4WebEmulatorSystem.nes,
      romFileUrl: Uri.file('/tmp/demo.nes'),
      romName: 'demo.nes',
      webRtcLatencyProbeEnabled: true,
    );

    expect(normal.toJson().containsKey('webRtcLatencyProbeEnabled'), isFalse);
    expect(measured.toJson()['webRtcLatencyProbeEnabled'], isTrue);
  });

  test('runtime exposes an in-session WebRTC publisher command', () async {
    final html = await File('assets/emulator/index.html').readAsString();

    expect(html, contains('startWebRtcPreview: function (config)'));
    expect(html, contains('stopWebRtcPreview: function ()'));
  });

  test('in-session publisher can explicitly enable the optical latency probe', () {
    final script = Host4WebEmulatorJavaScript.startWebRtcPublisher(
      signalUrl: 'ws://192.168.1.8:57221',
      roomId: 'room',
      latencyProbe: true,
    );

    expect(script, contains('"webRtcLatencyProbeEnabled":true'));
  });

  test('semantic game screenshot preview is opt-in', () async {
    final config = Host4WebEmulatorLaunchConfig(
      system: Host4WebEmulatorSystem.gba,
      romFileUrl: Uri.file('/tmp/demo.gba'),
      romName: 'demo.gba',
      semanticScreenshotPreviewEnabled: true,
    );

    expect(config.toJson()['semanticScreenshotPreviewEnabled'], isTrue);

    final html = await File('assets/emulator/index.html').readAsString();
    expect(html, contains('config.semanticScreenshotPreviewEnabled === true'));
    expect(html, contains('current.screenshot()'));
    expect(html, contains('semantic_ra_screenshot'));
  });

  test('in-WebView canvas mirror preview is opt-in', () async {
    final config = Host4WebEmulatorLaunchConfig(
      system: Host4WebEmulatorSystem.gba,
      romFileUrl: Uri.file('/tmp/demo.gba'),
      romName: 'demo.gba',
      inWebViewCanvasMirrorPreviewEnabled: true,
    );

    expect(config.toJson()['inWebViewCanvasMirrorPreviewEnabled'], isTrue);

    final html = await File('assets/emulator/index.html').readAsString();
    expect(
      html,
      contains('config.inWebViewCanvasMirrorPreviewEnabled === true'),
    );
    expect(html, contains('installPreservedDrawingBufferForCanvas()'));
    expect(html, contains('startInWebViewCanvasMirrorPreview(current)'));
    expect(html, contains("document.getElementById('canvas')"));
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

  test('generates resume JavaScript with a deferred target rate', () {
    expect(
      Host4WebEmulatorJavaScript.resume('resume-1', 2),
      'window.Host4WebEmulator.resume("resume-1", 2.0);',
    );
  });

  test(
    'controller marks foreground recovery as retryable by default',
    () async {
      final scripts = <String>[];
      final controller = Host4WebEmulatorController.forJavaScriptExecutor(
        (script) async => scripts.add(script),
      );

      await controller.recoverForeground();

      expect(scripts, <String>[
        'void window.Host4WebEmulator?.recoverForeground?.(false);',
      ]);
    },
  );

  test('packaged web runtime wires SRAM restore and export', () async {
    final html = await File('assets/emulator/index.html').readAsString();
    expect(html, contains('sram: config.sramBase64'));
    expect(html, contains('saveSRAM: async function (requestId)'));
    expect(html, contains("report('sramSaved', requestId"));
    expect(html, contains("report('rateSet', requestId"));
  });

  test(
    'packaged web runtime only reports aggregate output probe snapshots',
    () async {
      final html = await File('assets/emulator/index.html').readAsString();

      expect(html, contains('function instrumentOutputProbe'));
      expect(html, contains('config.outputProbeEnabled === true'));
      expect(html, contains('output_probe_snapshot'));
      expect(html, contains('ra-video-refresh-low-latency-poc-20261125-r4'));
      expect(html, contains('currentOutputProbeUsesLocalCore'));
      expect(html, contains('module.HEAPU8'));
      expect(html, contains('renderCoreVideoPreview'));
      // Libretro cores are allowed to submit either XRGB8888 (1) or RGB565
      // (2).  FCEUmm happens to use the former, while mGBA uses the latter.
      expect(html, contains('pixelFormat !== 1 && pixelFormat !== 2'));
      expect(html, contains('RGB565 pixels are little-endian'));
      expect(html, contains("Host4WebEmulatorPost('outputPreview'"));
      expect(html, contains('flutterPreviewCanvas'));
      expect(html, contains('window.Host4WebEmulatorPost'));
      expect(html, isNot(contains('host4-core-video-preview')));
      expect(html, isNot(contains('previewContext.fillRect')));
      expect(html, contains('pcmCaptureAvailable'));
      expect(html, contains('pcmCapturedFrames'));
      expect(html, contains('pcmBufferedFrames'));
      expect(html, contains('mediaTimestampUs'));
      expect(html, contains('videoCapture'));
      expect(html, contains('textureUploadCalls'));
      expect(html, contains('textureUploadPixelCalls'));
      expect(html, contains('var _glTexImage2D='));
      expect(html, contains('var _glTexSubImage2D='));
      expect(html, isNot(contains('host4OutputVideoFrame')));
      expect(html, isNot(contains('readPixels(')));
      expect(html, contains('host4-output-preview'));
      expect(html, contains('putImageData'));
      expect(html, isNot(contains('previewContext.fillText')));
      expect(html, contains('setInterval'));
      // WebRTC is an explicit local-only role; the normal output-probe path
      // must not start it merely because diagnostics are enabled.
      expect(html, contains("config.webRtcPreviewRole === 'publisher'"));
      expect(html, contains('probeCanvas.captureStream(60)'));
    },
  );

  test(
    'external WebGL preview mode keeps the RetroArch core source intact',
    () async {
      final html = await File('assets/emulator/index.html').readAsString();
      final view = await File(
        'lib/src/host4_web_emulator_view.dart',
      ).readAsString();
      final config = await File(
        'lib/src/host4_web_emulator_launch_config.dart',
      ).readAsString();

      expect(config, contains('externalWebGlPreviewEnabled'));
      expect(view, contains('externalWebGlPreviewEnabled'));
      expect(view, contains('outputProbeEnabled &&'));
      expect(html, contains('config.externalWebGlPreviewEnabled === true'));
      expect(html, contains('return r.js;'));
      expect(html, contains('installExternalWebglPreview'));
      expect(html, contains('getEmscripten'));
    },
  );

  test('video-refresh probe packages cover every product core', () async {
    final view = await File(
      'lib/src/host4_web_emulator_view.dart',
    ).readAsString();
    final pubspec = await File('pubspec.yaml').readAsString();

    for (final core in <String>[
      'fceumm',
      'genesis_plus_gx',
      'mgba',
      'snes9x',
    ]) {
      expect(view, contains("'${core}': '${core}_libretro'"));
      expect(pubspec, contains('assets/emulator/probe/${core}_libretro.js'));
      expect(pubspec, contains('assets/emulator/probe/${core}_libretro.wasm'));
    }
    expect(view, contains('video-refresh probe package'));
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

  test(
    'controller resumes with the deferred rate in one bridge request',
    () async {
      final scripts = <String>[];
      final controller = Host4WebEmulatorController.forJavaScriptExecutor(
        (script) async => scripts.add(script),
        requestIdFactory: () => 'resume-1',
      );

      final resultFuture = controller.resume(rate: 2);
      expect(
        scripts.single,
        'window.Host4WebEmulator.resume("resume-1", 2.0);',
      );
      controller.handleBridgeMessage('resumed', <String, Object?>{
        'type': 'resumed',
        'requestId': 'resume-1',
        'ok': true,
        'data': <String, Object?>{'rate': 2},
        'error': null,
      });

      await resultFuture;
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

  test('cold launch can outlast the normal command timeout', () async {
    final controller = Host4WebEmulatorController.forJavaScriptExecutor(
      (_) async {},
      requestTimeout: Duration.zero,
      requestIdFactory: () => 'cold-launch',
    );
    final launched = controller.launch(
      Host4WebEmulatorLaunchConfig(
        system: Host4WebEmulatorSystem.snes,
        romName: 'game.sfc',
        romBase64: 'AA==',
        launchTimeout: const Duration(seconds: 5),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    controller.handleBridgeMessage('launched', <String, Object?>{
      'type': 'launched',
      'requestId': 'cold-launch',
      'ok': true,
    });
    await launched;
    await expectLater(
      controller.pause(),
      throwsA(isA<Host4WebEmulatorException>()),
    );
    controller.dispose();
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
