import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_gmacro/host4_flutter_gmacro.dart';
import 'package:host4_flutter_device_native/host4_flutter_device_native.dart';
import 'package:host4_flutter_transport/host4_flutter_transport.dart';

void main() {
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
}

class _FakeDeviceNative extends Host4FlutterDeviceNative {
  final List<Map<String, Object?>> invocations = <Map<String, Object?>>[];
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
    invocations.add(<String, Object?>{
      'method': method,
      'arguments': Map<String, Object?>.from(arguments),
    });
    return <String, Object?>{};
  }

  @override
  Future<void> closeProtocol(String protocolSessionId) async {}

  Future<void> dispose() => escalationEvents.close();
}

class _FakeTransportSession implements TransportSession {
  @override
  final DeviceDescriptor device = const DeviceDescriptor(
    id: 'ble-device-1',
    name: 'Gamepad',
    kind: TransportKind.ble,
  );

  @override
  Future<void> disconnect() async {}

  @override
  Stream<TransportEvent> get events => const Stream<TransportEvent>.empty();

  @override
  String get id => 'transport-1';
}
