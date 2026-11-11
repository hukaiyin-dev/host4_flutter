import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_gmacro/host4_flutter_gmacro.dart';
import 'package:host4_flutter_device_native/host4_flutter_device_native.dart';
import 'package:host4_flutter_transport/host4_flutter_transport.dart';

void main() {
  test(
    'heartbeat sends once through its own protocol session without a reply',
    () async {
      final native = _FakeDeviceNative();
      final session = GmacroSession(
        id: 'heartbeat-session',
        transport: _FakeTransportSession(),
        native: native,
      );
      await session.sendHeartbeat();
      expect(native.invocations.single['method'], 'sendHeartbeat');
      expect(native.invokedSessionIds.single, 'heartbeat-session');
      await session.close();
    },
  );

  test('16-bit turbo APIs preserve speed above 255 and old methods', () async {
    final native = _FakeDeviceNative();
    final session = GmacroSession(
      id: 'protocol-1',
      transport: _FakeTransportSession(),
      native: native,
    );

    await session.setTurboDatas16(
      keyTurbos: const [
        KeyTurboPayload(
          key: GamepadKey.a,
          turbo: TurboMode.fullAuto,
          speed: 300,
        ),
      ],
    );
    expect(native.invocations.single['method'], GmacroMethods.setTurboDatas16);
    expect((native.invocations.single['arguments'] as Map)['keyTurbos'], [
      {'key': GamepadKey.a.value, 'turbo': 1, 'speed': 300},
    ]);

    native.nextInvoke = Future.value(<String, Object?>{
      'rapidList': <Map<String, Object?>>[
        {'key': GamepadKey.a.value, 'mode': 1, 'speed': 300},
      ],
    });
    final info = await session.fetchGameMacroDefaultInfo16(profile: 2);
    expect(info.rapidList.single.speed, 300);
    expect(
      native.invocations.last['method'],
      GmacroMethods.fetchGameMacroDefaultInfo16,
    );
    expect(native.invocations.last['arguments'], {'profile': 2});
    expect(
      () => session.setTurboDatas16(
        keyTurbos: const [
          KeyTurboPayload(
            key: GamepadKey.a,
            turbo: TurboMode.fullAuto,
            speed: 65536,
          ),
        ],
      ),
      throwsRangeError,
    );
  });

  test(
    'rapid info preserves press duration and defaults missing values to zero',
    () {
      final info = GmacroDefaultInfo.fromMap({
        'rapidList': [
          {'key': 160, 'mode': 1, 'speed': 12000, 'pressDuration': 300},
          {'key': 161, 'mode': 2, 'speed': 100},
        ],
      });
      expect(info.rapidList.first.pressDuration, 300);
      expect(info.rapidList.first.toMap()['pressDuration'], 300);
      expect(info.rapidList.last.pressDuration, 0);
    },
  );

  test(
    'timing writes keep each duration, interval and device without scaling',
    () async {
      final native = _FakeDeviceNative();
      final session = GmacroSession(
        id: 'timing',
        transport: _FakeTransportSession(),
        native: native,
      );
      await session.updateKeyTurboTiming(
        keyTurbos: const [
          KeyTurboPayload(
            key: GamepadKey.a,
            turbo: TurboMode.fullAuto,
            speed: 12000,
            pressDuration: 300,
          ),
          KeyTurboPayload(
            key: GamepadKey.b,
            turbo: TurboMode.disabled,
            speed: 100,
          ),
        ],
        device: 2,
      );
      expect(native.invocations.single['method'], 'updateKeyTurboTiming');
      expect(native.invocations.single['arguments'], {
        'device': 2,
        'keyTurbos': [
          {'key': 160, 'turbo': 1, 'pressDuration': 300, 'interval': 12000},
          {'key': 161, 'turbo': 2, 'pressDuration': 0, 'interval': 100},
        ],
      });
      for (final duration in [-1, 65536]) {
        expect(
          () => session.updateKeyTurboTiming(
            keyTurbos: [
              KeyTurboPayload(
                key: GamepadKey.a,
                turbo: TurboMode.fullAuto,
                speed: 100,
                pressDuration: duration,
              ),
            ],
          ),
          throwsRangeError,
        );
      }
      expect(
        () => session.updateKeyTurboTiming(
          keyTurbos: const [
            KeyTurboPayload(
              key: GamepadKey.a,
              turbo: TurboMode.fullAuto,
              speed: 0,
            ),
          ],
        ),
        throwsRangeError,
      );
      expect(() => session.queryAllKeyTurbo16(device: 256), throwsRangeError);
      expect(native.invocations.length, 1);
    },
  );

  test('turbo16 legacy form forwards global duration and device', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final native = _FakeDeviceNative();
    final session = GmacroSession(
      id: 'timing',
      transport: _FakeTransportSession(),
      native: native,
    );
    await session.setTurboDatas16(
      keyTurbos: const [
        KeyTurboPayload(
          key: GamepadKey.a,
          turbo: TurboMode.fullAuto,
          speed: 600,
        ),
      ],
      pressDuration: 0,
      device: 3,
    );
    expect(native.invocations.single['arguments'], {
      'keyTurbos': [
        {'key': 160, 'turbo': 1, 'speed': 600},
      ],
      'pressDuration': 0,
      'device': 3,
    });
  });

  test(
    'Android rejects unsupported custom global duration and device before sending',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final native = _FakeDeviceNative();
      final session = GmacroSession(
        id: 'timing',
        transport: _FakeTransportSession(),
        native: native,
      );
      const items = [
        KeyTurboPayload(
          key: GamepadKey.a,
          turbo: TurboMode.fullAuto,
          speed: 100,
        ),
      ];
      expect(
        () => session.setTurboDatas16(keyTurbos: items, pressDuration: 0),
        throwsUnsupportedError,
      );
      expect(
        () => session.setTurboDatas16(keyTurbos: items, device: 2),
        throwsUnsupportedError,
      );
      expect(native.invocations, isEmpty);
      await session.setTurboDatas16(keyTurbos: items);
      expect(
        native.invocations.single['method'],
        GmacroMethods.setTurboDatas16,
      );
      await session.setTurboDatas16(
        keyTurbos: const [
          KeyTurboPayload(
            key: GamepadKey.a,
            turbo: TurboMode.disabled,
            speed: 0,
          ),
        ],
      );
      expect((native.invocations.last['arguments'] as Map)['keyTurbos'], [
        {'key': 160, 'turbo': 2, 'speed': 0},
      ]);
    },
  );

  test(
    'turbo queries preserve raw single and assembled all-key responses',
    () async {
      final native = _FakeDeviceNative();
      final session = GmacroSession(
        id: 'timing',
        transport: _FakeTransportSession(),
        native: native,
      );
      native.nextInvoke = Future.value({
        'device': 2,
        'config': {'key': 160, 'turbo': 1, 'pressDuration': 0, 'interval': 600},
      });
      final single = await session.queryKeyTurbo16(GamepadKey.a, device: 2);
      expect((single['config'] as Map)['pressDuration'], 0);
      expect(native.invocations.last['method'], 'queryKeyTurbo16');
      expect(native.invocations.last['arguments'], {'key': 160, 'device': 2});
      native.nextInvoke = Future.value({
        'device': 2,
        'configs': [
          {'key': 160, 'turbo': 1, 'pressDuration': 300, 'interval': 600},
          {'key': 161, 'turbo': 0, 'pressDuration': 0, 'interval': 12000},
        ],
      });
      final all = await session.queryAllKeyTurbo16(device: 2);
      expect((all['configs'] as List).length, 2);
      expect(((all['configs'] as List).last as Map)['interval'], 12000);
      expect(native.invocations.last['method'], 'queryAllKeyTurbo16');
      expect(native.invocations.last['arguments'], {'device': 2});
    },
  );

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('attach wraps a transport session as gmacro protocol session', () async {
    final gmacro = Host4Gmacro(native: _FakeDeviceNative());
    final transport = _FakeTransportSession();

    final session = await gmacro.attach(transport);

    expect(session.id, 'protocol-1');
    expect(session.protocolName, 'gmacro');
    expect(session.transport.id, 'transport-1');
  });

  test('touch mapping methods forward sdk arguments', () async {
    final native = _FakeDeviceNative();
    final session = GmacroSession(
      id: 'protocol-1',
      transport: _FakeTransportSession(),
      native: native,
    );

    await session.setScreenSize(orientation: 1, width: 1920, height: 1080);
    await session.setKeyMapping(
      type: 2,
      keyCode: 3,
      x: 4,
      y: 5,
      range: 6,
      sensitivity: 7,
      x1: 8,
      y1: 9,
      attribute: 10,
      page: 11,
    );
    await session.setMacroKey(
      keyCode: 12,
      x: 13,
      y: 14,
      flag: 15,
      interval: 16,
      during: 17,
      attribute: 18,
      range: 19,
      sensitivity: 20,
      opposite: 21,
    );
    await session.setMacroKeyTrigger(keyCode: 22, touchType: 23);
    await session.setMacroTerminationKey(keyCode: 24, terminateKey: 25);
    await session.keyMappingEnd(page: 26, packet: 27);

    expect(native.invocations, <Map<String, Object?>>[
      {
        'method': GmacroMethods.setScreenSize,
        'arguments': {'orientation': 1, 'width': 1920, 'height': 1080},
      },
      {
        'method': GmacroMethods.setKeyMapping,
        'arguments': {
          'type': 2,
          'keyCode': 3,
          'x': 4,
          'y': 5,
          'range': 6,
          'sensitivity': 7,
          'x1': 8,
          'y1': 9,
          'attribute': 10,
          'page': 11,
        },
      },
      {
        'method': GmacroMethods.setMacroKey,
        'arguments': {
          'keyCode': 12,
          'x': 13,
          'y': 14,
          'flag': 15,
          'interval': 16,
          'during': 17,
          'attribute': 18,
          'range': 19,
          'sensitivity': 20,
          'opposite': 21,
        },
      },
      {
        'method': GmacroMethods.setMacroKeyTrigger,
        'arguments': {'keyCode': 22, 'touchType': 23},
      },
      {
        'method': GmacroMethods.setMacroTerminationKey,
        'arguments': {'keyCode': 24, 'terminateKey': 25},
      },
      {
        'method': GmacroMethods.keyMappingEnd,
        'arguments': {'page': 26, 'packet': 27},
      },
    ]);

    await session.close();
  });

  test(
    'updateHandleFunction forwards independent handle and EP3 flags',
    () async {
      final native = _FakeDeviceNative();
      final session = GmacroSession(
        id: 'protocol-1',
        transport: _FakeTransportSession(),
        native: native,
      );

      await session.updateHandleFunction(handleOn: false, ep3CallbackOn: true);

      expect(native.invocations, <Map<String, Object?>>[
        {
          'method': GmacroMethods.updateHandleFunction,
          'arguments': {'handleOn': false, 'ep3CallbackOn': true},
        },
      ]);

      await session.close();
    },
  );

  test('fetchAppWakeKeyType forwards sdk method without arguments', () async {
    final native = _FakeDeviceNative();
    final session = GmacroSession(
      id: 'protocol-1',
      transport: _FakeTransportSession(),
      native: native,
    );

    await session.fetchAppWakeKeyType();

    expect(native.invocations, <Map<String, Object?>>[
      {
        'method': GmacroMethods.fetchAppWakeKeyType,
        'arguments': <String, Object?>{},
      },
    ]);

    await session.close();
  });

  test('Android test-mode escalation is exposed as TestEventMode', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final native = _FakeDeviceNative();
    final session = GmacroSession(
      id: 'protocol-1',
      transport: _FakeTransportSession(),
      native: native,
    );
    final eventFuture = session.realtimeEvents.first;

    native.escalationEvents.add(<String, Object?>{
      'type': 'testModeEvent',
      'keyValue': 1,
      'keys': <int>[1],
      'leftRockerXValue': 11,
      'leftRockerYValue': 22,
      'rightRockerXValue': 33,
      'rightRockerYValue': 44,
      'leftKeyLTwoValue': 55,
      'rightKeyRTwoValue': 66,
    });

    final event = await eventFuture;
    expect(event, isA<TestEventMode>());
    final testEvent = event as TestEventMode;
    expect(testEvent.rawKeys, <int>[1]);
    expect(testEvent.j1x, 11);
    expect(testEvent.j1y, 22);
    expect(testEvent.j2x, 33);
    expect(testEvent.j2y, 44);
    expect(testEvent.l2, 55);
    expect(testEvent.r2, 66);

    await session.close();
    await native.dispose();
  });

  test('Android UART merges native escalation events', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final native = _FakeDeviceNative();
    final session = GmacroSession(
      id: 'protocol-1',
      transport: _FakeTransportSession(kind: TransportKind.uart),
      native: native,
    );
    final eventFuture = session.realtimeEvents.first;

    native.escalationEvents.add(<String, Object?>{
      'type': 'testModeEvent',
      'keyValue': 1,
      'keys': <int>[1],
      'leftRockerXValue': 11,
      'leftRockerYValue': 22,
      'rightRockerXValue': 33,
      'rightRockerYValue': 44,
      'leftKeyLTwoValue': 55,
      'rightKeyRTwoValue': 66,
    });

    final event = await eventFuture;
    expect(event, isA<TestEventMode>());
    await session.close();
    await native.dispose();
  });

  test('UART request returns native -3 after its three-second wait', () async {
    final native = _FakeDeviceNative();
    final reply = Completer<Map<String, Object?>>();
    native.nextInvoke = reply.future;
    final session = GmacroSession(
      id: 'protocol-1',
      transport: _FakeTransportSession(kind: TransportKind.uart),
      native: native,
    );

    final result = expectLater(
      session.invoke('fetchDeviceVersion'),
      throwsA(
        isA<PlatformException>().having(
          (error) => error.message,
          'native status',
          contains('code=-3'),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 3100));
    reply.completeError(
      PlatformException(
        code: 'gmacro-method-failed',
        message: 'GMacro method failed with code=-3',
      ),
    );
    await result;
    await session.close();
    await native.dispose();
  });

  test('USB requests keep the Dart three-second fallback', () async {
    final native = _FakeDeviceNative();
    native.nextInvoke = Completer<Map<String, Object?>>().future;
    final session = GmacroSession(
      id: 'protocol-1',
      transport: _FakeTransportSession(kind: TransportKind.usb),
      native: native,
    );

    await expectLater(
      session.invoke('fetchDeviceVersion'),
      throwsA(isA<TimeoutException>()),
    );
    await session.close();
    await native.dispose();
  });
}

class _FakeDeviceNative extends Host4FlutterDeviceNative {
  final List<String> invokedSessionIds = <String>[];
  final List<Map<String, Object?>> invocations = <Map<String, Object?>>[];
  Future<Map<String, Object?>>? nextInvoke;
  final StreamController<Map<String, Object?>> escalationEvents =
      StreamController<Map<String, Object?>>.broadcast();

  @override
  Future<String> attachGmacroProtocol(
    String transportSessionId, {
    Map<String, Object?> options = const {},
  }) async {
    return 'protocol-1';
  }

  @override
  Stream<NativeProtocolEvent> protocolEvents(String protocolSessionId) {
    return const Stream<NativeProtocolEvent>.empty();
  }

  @override
  Stream<Map<String, Object?>> transportEscalationEvents(
    String transportSessionId,
  ) {
    return escalationEvents.stream;
  }

  @override
  Future<Map<String, Object?>> invokeGmacroMethod({
    required String protocolSessionId,
    required String method,
    Map<String, Object?> arguments = const {},
  }) async {
    invokedSessionIds.add(protocolSessionId);
    invocations.add(<String, Object?>{
      'method': method,
      'arguments': Map<String, Object?>.from(arguments),
    });
    return nextInvoke ?? <String, Object?>{};
  }

  @override
  Future<void> closeProtocol(String protocolSessionId) async {}

  Future<void> dispose() => escalationEvents.close();
}

class _FakeTransportSession implements TransportSession {
  _FakeTransportSession({this.kind = TransportKind.ble});

  final TransportKind kind;

  @override
  DeviceDescriptor get device =>
      DeviceDescriptor(id: 'device-1', name: 'Gamepad', kind: kind);

  @override
  Future<void> disconnect() async {}

  @override
  Stream<TransportEvent> get events => const Stream<TransportEvent>.empty();

  @override
  String get id => 'transport-1';
}
