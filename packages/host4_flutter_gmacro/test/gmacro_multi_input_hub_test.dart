import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_device_native/host4_flutter_device_native.dart';
import 'package:host4_flutter_gmacro/host4_flutter_gmacro.dart';
import 'package:host4_flutter_transport/host4_flutter_transport.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('two sessions keep same-key edges and source IDs separate', () async {
    final first = _TestSession('protocol-a', 'transport-a', 'device-a');
    final second = _TestSession('protocol-b', 'transport-b', 'device-b');
    final hub = GmacroMultiInputHub();
    final events = <GmacroDeviceButtonEvent>[];
    final subscription = hub.buttonEvents.listen(events.add);

    hub.addSession(first);
    hub.addSession(second);
    first.emitKeys(<GamepadKey>[GamepadKey.a]);
    second.emitKeys(<GamepadKey>[GamepadKey.a]);
    first.emitKeys(<GamepadKey>[]);
    await _flush();

    expect(
      events.map((event) => (event.deviceId, event.phase)).toList(),
      <(String, GmacroButtonPhase)>[
        ('device-a', GmacroButtonPhase.down),
        ('device-b', GmacroButtonPhase.down),
        ('device-a', GmacroButtonPhase.up),
      ],
    );
    expect(events.map((event) => event.transportSessionId).toList(), <String>[
      'transport-a',
      'transport-b',
      'transport-a',
    ]);
    expect(events.map((event) => event.protocolSessionId).toList(), <String>[
      'protocol-a',
      'protocol-b',
      'protocol-a',
    ]);

    await subscription.cancel();
    await hub.dispose();
    await first.disposeTest();
    await second.disposeTest();
  });

  test(
    'one disconnect releases only its held keys and ignores late input',
    () async {
      final first = _TestSession('protocol-a', 'transport-a', 'device-a');
      final second = _TestSession('protocol-b', 'transport-b', 'device-b');
      final hub = GmacroMultiInputHub();
      final events = <GmacroDeviceButtonEvent>[];
      final subscription = hub.buttonEvents.listen(events.add);
      hub.addSession(first);
      hub.addSession(second);

      first.emitKeys(<GamepadKey>[GamepadKey.a]);
      second.emitKeys(<GamepadKey>[GamepadKey.a]);
      await first.testTransport.disconnect();
      first.emitKeys(<GamepadKey>[GamepadKey.b]);
      second.emitKeys(<GamepadKey>[]);
      await _flush();

      expect(
        events
            .map((event) => (event.deviceId, event.key, event.phase))
            .toList(),
        <(String, GamepadKey, GmacroButtonPhase)>[
          ('device-a', GamepadKey.a, GmacroButtonPhase.down),
          ('device-b', GamepadKey.a, GmacroButtonPhase.down),
          ('device-a', GamepadKey.a, GmacroButtonPhase.up),
          ('device-b', GamepadKey.a, GmacroButtonPhase.up),
        ],
      );

      await subscription.cancel();
      await hub.dispose();
      await first.disposeTest();
      await second.disposeTest();
    },
  );

  test('state and joystick edges are isolated per device', () async {
    final first = _TestSession('protocol-a', 'transport-a', 'device-a');
    final second = _TestSession('protocol-b', 'transport-b', 'device-b');
    final hub = GmacroMultiInputHub();
    final states = <GmacroDeviceInputState>[];
    final edges = <GmacroDeviceButtonEvent>[];
    final stateSub = hub.states.listen(states.add);
    final edgeSub = hub.buttonEvents.listen(edges.add);
    hub.addSession(first);
    hub.addSession(second);

    first.emitInput(j1x: 255, l2: 81);
    second.emitInput(j1x: 127, l2: 12);
    first.emitInput(j1x: 127, l2: 81);
    await _flush();

    expect(
      states.map((event) => (event.deviceId, event.state.l2)).toList(),
      <(String, int)>[('device-a', 81), ('device-b', 12), ('device-a', 81)],
    );
    expect(
      edges.map((event) => (event.deviceId, event.key, event.phase)).toList(),
      <(String, GamepadKey, GmacroButtonPhase)>[
        ('device-a', GamepadKey.right, GmacroButtonPhase.down),
        ('device-a', GamepadKey.right, GmacroButtonPhase.up),
      ],
    );

    await stateSub.cancel();
    await edgeSub.cancel();
    await hub.dispose();
    await first.disposeTest();
    await second.disposeTest();
  });

  test(
    'duplicate add is idempotent but conflicting protocol ID is rejected',
    () async {
      final first = _TestSession('protocol-a', 'transport-a', 'device-a');
      final conflict = _TestSession('protocol-a', 'transport-b', 'device-b');
      final hub = GmacroMultiInputHub();
      final events = <GmacroDeviceButtonEvent>[];
      final subscription = hub.buttonEvents.listen(events.add);
      hub.addSession(first);
      hub.addSession(first);
      expect(() => hub.addSession(conflict), throwsStateError);
      first.emitKeys(<GamepadKey>[GamepadKey.a]);
      await _flush();
      expect(events.length, 1);
      expect(events.single.deviceId, 'device-a');

      await subscription.cancel();
      await hub.dispose();
      await first.disposeTest();
      await conflict.disposeTest();
    },
  );

  test(
    'input stream error is tagged and removes only failed session',
    () async {
      final first = _TestSession('protocol-a', 'transport-a', 'device-a');
      final second = _TestSession('protocol-b', 'transport-b', 'device-b');
      final hub = GmacroMultiInputHub();
      final errors = <GmacroDeviceInputError>[];
      final edges = <GmacroDeviceButtonEvent>[];
      final errorSub = hub.errors.listen(errors.add);
      final edgeSub = hub.buttonEvents.listen(edges.add);
      hub.addSession(first);
      hub.addSession(second);
      first.emitKeys(<GamepadKey>[GamepadKey.a]);
      first.emitError(StateError('bad packet'));
      first.emitKeys(<GamepadKey>[GamepadKey.b]);
      second.emitKeys(<GamepadKey>[GamepadKey.a]);
      await _flush();

      expect(errors.single.deviceId, 'device-a');
      expect(errors.single.error, isA<StateError>());
      expect(
        edges.map((event) => (event.deviceId, event.key, event.phase)).toList(),
        <(String, GamepadKey, GmacroButtonPhase)>[
          ('device-a', GamepadKey.a, GmacroButtonPhase.down),
          ('device-a', GamepadKey.a, GmacroButtonPhase.up),
          ('device-b', GamepadKey.a, GmacroButtonPhase.down),
        ],
      );

      await errorSub.cancel();
      await edgeSub.cancel();
      await hub.dispose();
      await first.disposeTest();
      await second.disposeTest();
    },
  );

  test(
    'manual removal and dispose release held keys without closing sessions',
    () async {
      final first = _TestSession('protocol-a', 'transport-a', 'device-a');
      final second = _TestSession('protocol-b', 'transport-b', 'device-b');
      final hub = GmacroMultiInputHub();
      final edges = <GmacroDeviceButtonEvent>[];
      final subscription = hub.buttonEvents.listen(edges.add);
      hub.addSession(first);
      hub.addSession(second);
      first.emitKeys(<GamepadKey>[GamepadKey.a]);
      second.emitKeys(<GamepadKey>[GamepadKey.b]);
      await hub.removeSession('protocol-a');
      first.emitKeys(<GamepadKey>[GamepadKey.b]);
      await hub.dispose();
      expect(() => hub.addSession(first), throwsStateError);
      expect(
        edges.map((event) => (event.deviceId, event.key, event.phase)).toList(),
        <(String, GamepadKey, GmacroButtonPhase)>[
          ('device-a', GamepadKey.a, GmacroButtonPhase.down),
          ('device-b', GamepadKey.b, GmacroButtonPhase.down),
          ('device-a', GamepadKey.a, GmacroButtonPhase.up),
          ('device-b', GamepadKey.b, GmacroButtonPhase.up),
        ],
      );

      await subscription.cancel();
      await first.disposeTest();
      await second.disposeTest();
    },
  );

  test(
    'completed input stream releases keys and allows a new session',
    () async {
      final first = _TestSession('protocol-a', 'transport-a', 'device-a');
      final replacement = _TestSession(
        'protocol-a',
        'transport-new',
        'device-a',
      );
      final hub = GmacroMultiInputHub();
      final edges = <GmacroDeviceButtonEvent>[];
      final subscription = hub.buttonEvents.listen(edges.add);
      hub.addSession(first);
      first.emitKeys(<GamepadKey>[GamepadKey.a]);
      await first.finishInput();
      hub.addSession(replacement);
      replacement.emitKeys(<GamepadKey>[GamepadKey.b]);
      await _flush();

      expect(
        edges.map((event) => (event.transportSessionId, event.phase)).toList(),
        <(String, GmacroButtonPhase)>[
          ('transport-a', GmacroButtonPhase.down),
          ('transport-a', GmacroButtonPhase.up),
          ('transport-new', GmacroButtonPhase.down),
        ],
      );

      await subscription.cancel();
      await hub.dispose();
      await first.disposeTest();
      await replacement.disposeTest();
    },
  );

  test('full device state uses the same per-device edge calculation', () async {
    final session = _TestSession('protocol-a', 'transport-a', 'device-a');
    final hub = GmacroMultiInputHub();
    final states = <GmacroDeviceInputState>[];
    final edges = <GmacroDeviceButtonEvent>[];
    final stateSub = hub.states.listen(states.add);
    final edgeSub = hub.buttonEvents.listen(edges.add);
    hub.addSession(session);
    session.emitFullState(<GamepadKey>[GamepadKey.x]);
    session.emitKeys(<GamepadKey>[]);
    await _flush();

    expect(states.first.state.source, GmacroInputSource.devKeysState);
    expect(states.first.state.j1xOriginal, 200);
    expect(edges.map((event) => event.phase).toList(), <GmacroButtonPhase>[
      GmacroButtonPhase.down,
      GmacroButtonPhase.up,
    ]);

    await stateSub.cancel();
    await edgeSub.cancel();
    await hub.dispose();
    await session.disposeTest();
  });

  test('listener can remove a session during a button callback', () async {
    final session = _TestSession('protocol-a', 'transport-a', 'device-a');
    final hub = GmacroMultiInputHub();
    final phases = <GmacroButtonPhase>[];
    final subscription = hub.buttonEvents.listen((event) {
      phases.add(event.phase);
      if (event.phase == GmacroButtonPhase.down) {
        hub.removeSession('protocol-a');
      }
    });
    hub.addSession(session);

    session.emitKeys(<GamepadKey>[GamepadKey.a]);
    await _flush();
    expect(phases, <GmacroButtonPhase>[
      GmacroButtonPhase.down,
      GmacroButtonPhase.up,
    ]);

    await subscription.cancel();
    await hub.dispose();
    await session.disposeTest();
  });

  test('dispose rejects a new session immediately while canceling', () async {
    final first = _TestSession('protocol-a', 'transport-a', 'device-a');
    final second = _TestSession('protocol-b', 'transport-b', 'device-b');
    final hub = GmacroMultiInputHub();
    hub.addSession(first);

    final disposing = hub.dispose();
    expect(() => hub.addSession(second), throwsStateError);
    await disposing;

    await first.disposeTest();
    await second.disposeTest();
  });

  test('removal emits a neutral state for only the removed device', () async {
    final first = _TestSession('protocol-a', 'transport-a', 'device-a');
    final second = _TestSession('protocol-b', 'transport-b', 'device-b');
    final hub = GmacroMultiInputHub();
    final states = <GmacroDeviceInputState>[];
    final subscription = hub.states.listen(states.add);
    hub.addSession(first);
    hub.addSession(second);
    first.emitInput(j1x: 220, l2: 80);
    second.emitInput(j1x: 150, l2: 30);
    await hub.removeSession('protocol-a');
    await _flush();

    expect(
      states
          .map((event) => (event.deviceId, event.state.j1x, event.state.l2))
          .toList(),
      <(String, int, int)>[
        ('device-a', 220, 80),
        ('device-b', 150, 30),
        ('device-a', 127, 0),
      ],
    );

    await subscription.cancel();
    await hub.dispose();
    await first.disposeTest();
    await second.disposeTest();
  });

  test('transport failure is reported with its device ID', () async {
    final session = _TestSession('protocol-a', 'transport-a', 'device-a');
    final hub = GmacroMultiInputHub();
    final errors = <GmacroDeviceInputError>[];
    final subscription = hub.errors.listen(errors.add);
    hub.addSession(session);

    session.testTransport.emitFailure();
    await _flush();

    expect(errors.single.deviceId, 'device-a');
    expect((errors.single.error as TransportFailure).code, 'link-lost');

    await subscription.cancel();
    await hub.dispose();
    await session.disposeTest();
  });

  test(
    'a cancellation failure does not block cleanup of other sessions',
    () async {
      final first = _TestSession(
        'protocol-a',
        'transport-a',
        'device-a',
        failTransportCancel: true,
      );
      final second = _TestSession('protocol-b', 'transport-b', 'device-b');
      final hub = GmacroMultiInputHub();
      final errors = <GmacroDeviceInputError>[];
      final states = <GmacroDeviceInputState>[];
      final errorSub = hub.errors.listen(errors.add);
      final stateSub = hub.states.listen(states.add);
      hub.addSession(first);
      hub.addSession(second);
      first.emitKeys(<GamepadKey>[GamepadKey.a]);
      second.emitKeys(<GamepadKey>[GamepadKey.b]);

      await hub.dispose();
      expect(errors.single.deviceId, 'device-a');
      expect(
        states
            .where((event) => event.state.pressedKeys.isEmpty)
            .map((event) => event.deviceId)
            .toList(),
        <String>['device-a', 'device-b'],
      );

      await errorSub.cancel();
      await stateSub.cancel();
      await first.disposeTest();
      await second.disposeTest();
    },
  );
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

class _TestSession extends GmacroSession {
  _TestSession(
    String protocolId,
    String transportId,
    String deviceId, {
    bool failTransportCancel = false,
  }) : super(
         id: protocolId,
         transport: _TestTransport(
           transportId,
           deviceId,
           failOnCancel: failTransportCancel,
         ),
         native: _TestNative(),
       );

  _TestTransport get testTransport => transport as _TestTransport;
  final _events = StreamController<GmacroRealtimeEvent>.broadcast(sync: true);

  @override
  Stream<GmacroRealtimeEvent> get realtimeEvents => _events.stream;

  void emitKeys(List<GamepadKey> keys) => emitInput(keys: keys);

  void emitInput({
    List<GamepadKey> keys = const <GamepadKey>[],
    int j1x = 127,
    int l2 = 0,
  }) => _events.add(
    TestEventMode(
      rawKeys: const <int>[],
      keys: keys,
      j1x: j1x,
      j1y: 127,
      j2x: 127,
      j2y: 127,
      l2: l2,
      r2: 0,
    ),
  );

  void emitError(Object error) => _events.addError(error);

  Future<void> finishInput() => _events.close();

  void emitFullState(List<GamepadKey> keys) => _events.add(
    DeviceKeysStateEvent(
      rawKeys: const <int>[],
      keys: keys,
      j1x: 127,
      j1xOriginal: 200,
      j1y: 127,
      j1yOriginal: 127,
      j2x: 127,
      j2xOriginal: 127,
      j2y: 127,
      j2yOriginal: 127,
      l2: 0,
      l2Original: 0,
      r2: 0,
      r2Original: 0,
    ),
  );

  Future<void> disposeTest() async {
    await _events.close();
    await testTransport.close();
    await close();
  }
}

class _TestTransport implements TransportSession {
  _TestTransport(this.id, String deviceId, {bool failOnCancel = false})
    : device = DeviceDescriptor(
        id: deviceId,
        name: deviceId,
        kind: TransportKind.ble,
      ),
      _events = failOnCancel
          ? StreamController<TransportEvent>(
              onCancel: () async {
                throw StateError('transport cancel failed');
              },
              sync: true,
            )
          : StreamController<TransportEvent>.broadcast(sync: true);

  @override
  final String id;
  @override
  final DeviceDescriptor device;
  final StreamController<TransportEvent> _events;
  @override
  Stream<TransportEvent> get events => _events.stream;
  @override
  Future<void> disconnect() async => _events.add(const TransportDisconnected());
  void emitFailure() => _events.add(
    const TransportError(
      TransportFailure(code: 'link-lost', message: 'Device disconnected'),
    ),
  );
  Future<void> close() => _events.close();
}

class _TestNative extends Host4FlutterDeviceNative {
  @override
  Stream<NativeProtocolEvent> protocolEvents(String protocolSessionId) =>
      const Stream<NativeProtocolEvent>.empty();
  @override
  Future<void> closeProtocol(String protocolSessionId) async {}
}
