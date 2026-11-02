import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_device_native/host4_flutter_device_native.dart';
import 'package:host4_flutter_gmacro/host4_flutter_gmacro.dart';
import 'package:host4_flutter_gmacro_demo_ui/host4_flutter_gmacro_demo_ui.dart';
import 'package:host4_flutter_transport/host4_flutter_transport.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'USB and two BLE sessions remain independent when one is removed',
    () async {
      final native = _FakeNative();
      final manager = GmacroMultiDeviceSessionManager(
        attach: (transport) => Host4Gmacro(native: native).attach(transport),
      );
      final usb = _FakeTransport('usb', TransportKind.usb);
      final bleA = _FakeTransport('ble-a', TransportKind.ble);
      final bleB = _FakeTransport('ble-b', TransportKind.ble);

      await manager.addTransport(usb);
      await manager.addTransport(bleA);
      await manager.addTransport(bleB);
      usb.ready();
      bleA.ready();
      bleB.ready();
      await Future<void>.delayed(Duration.zero);

      expect(manager.connections.length, 3);
      expect(
        manager.connections.every((entry) => entry.session != null),
        isTrue,
      );
      manager.select('ble:ble-b');
      expect(await manager.querySelectedVersion(), {'target': 'ble-b'});

      await manager.remove('ble:ble-a');
      expect(bleA.disconnected, isTrue);
      expect(usb.disconnected, isFalse);
      expect(bleB.disconnected, isFalse);
      expect(await manager.querySelectedVersion(), {'target': 'ble-b'});

      await manager.close();
    },
  );

  test('a late protocol attach cannot revive a disconnected device', () async {
    final native = _FakeNative();
    final pendingAttach = Completer<GmacroSession>();
    final manager = GmacroMultiDeviceSessionManager(
      attach: (_) => pendingAttach.future,
    );
    final ble = _FakeTransport('ble-late', TransportKind.ble);
    await manager.addTransport(ble);

    ble.ready();
    await Future<void>.delayed(Duration.zero);
    ble.disconnectedEvent();
    await Future<void>.delayed(Duration.zero);
    pendingAttach.complete(await Host4Gmacro(native: native).attach(ble));
    await Future<void>.delayed(Duration.zero);

    expect(manager.connections.single.session, isNull);
    expect(manager.connections.single.status, '已断开');
    await manager.close();
  });
}

class _FakeTransport implements TransportSession {
  _FakeTransport(String id, TransportKind kind)
    : device = DeviceDescriptor(id: id, name: id, kind: kind);

  final _events = StreamController<TransportEvent>.broadcast();
  bool disconnected = false;

  @override
  final DeviceDescriptor device;
  @override
  String get id => device.id;
  @override
  Stream<TransportEvent> get events => _events.stream;

  void ready() => _events.add(const TransportReady());

  void disconnectedEvent() => _events.add(const TransportDisconnected());

  @override
  Future<void> disconnect() async {
    disconnected = true;
    await _events.close();
  }
}

class _FakeNative extends Host4FlutterDeviceNative {
  @override
  Future<String> attachGmacroProtocol(
    String transportSessionId, {
    Map<String, Object?> options = const {},
  }) async => 'protocol-$transportSessionId';

  @override
  Stream<NativeProtocolEvent> protocolEvents(String protocolSessionId) =>
      const Stream<NativeProtocolEvent>.empty();

  @override
  Future<Map<String, Object?>> invokeGmacroMethod({
    required String protocolSessionId,
    required String method,
    Map<String, Object?> arguments = const {},
  }) async => {'target': protocolSessionId.substring('protocol-'.length)};

  @override
  Future<void> closeProtocol(String protocolSessionId) async {}
}
