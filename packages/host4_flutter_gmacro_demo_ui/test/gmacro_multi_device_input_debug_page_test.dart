import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_device_native/host4_flutter_device_native.dart';
import 'package:host4_flutter_gmacro/host4_flutter_gmacro.dart';
import 'package:host4_flutter_gmacro_demo_ui/host4_flutter_gmacro_demo_ui.dart';
import 'package:host4_flutter_transport/host4_flutter_transport.dart';

void main() {
  testWidgets('multi-device screens stay opaque under a transparent app theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(scaffoldBackgroundColor: Colors.transparent),
        home: const GmacroMultiDevicePage(),
      ),
    );

    final connectionPage = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(connectionPage.backgroundColor?.a, 1.0);
    await tester.tap(find.text('查看多设备按键数据'));
    await tester.pumpAndSettle();
    final inputPage = tester.widget<Scaffold>(find.byType(Scaffold).last);
    expect(inputPage.backgroundColor?.a, 1.0);
  });

  testWidgets('multi-device page opens a dedicated input debug screen', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GmacroMultiDevicePage()));

    expect(find.text('查看多设备按键数据'), findsOneWidget);
    await tester.tap(find.text('查看多设备按键数据'));
    await tester.pumpAndSettle();
    expect(find.text('多设备按键调试'), findsOneWidget);
  });

  testWidgets(
    'test-mode input stays identified by device on the debug screen',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final native = _FakeNative();
      final manager = GmacroMultiDeviceSessionManager(
        attach: (transport) => Host4Gmacro(native: native).attach(transport),
      );
      final first = _FakeTransport('ble-a');
      final second = _FakeTransport('ble-b');
      await manager.addTransport(first);
      await manager.addTransport(second);
      first.ready();
      second.ready();
      await tester.pump();

      await tester.pumpWidget(
        MaterialApp(home: GmacroMultiDeviceInputDebugPage(manager: manager)),
      );
      native.testKeys('ble-a', [0xA0]);
      native.testKeys('ble-b', [0xA1]);
      await tester.pump();

      expect(find.text('当前按键：a'), findsOneWidget);
      expect(find.text('当前按键：b'), findsOneWidget);
      expect(find.textContaining('ble-a · a down'), findsOneWidget);
      expect(find.textContaining('ble-b · b down'), findsOneWidget);
      expect(find.text('数据来源：testKeys'), findsNWidgets(2));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() async {
        await manager.close();
        await native.close();
      });
    },
  );
}

class _FakeTransport implements TransportSession {
  _FakeTransport(String id)
    : device = DeviceDescriptor(id: id, name: id, kind: TransportKind.ble);

  final _events = StreamController<TransportEvent>.broadcast();

  @override
  final DeviceDescriptor device;
  @override
  String get id => device.id;
  @override
  Stream<TransportEvent> get events => _events.stream;

  void ready() => _events.add(const TransportReady());

  @override
  Future<void> disconnect() => _events.close();
}

class _FakeNative extends Host4FlutterDeviceNative {
  final _protocolEvents = <String, StreamController<NativeProtocolEvent>>{};

  @override
  Future<String> attachGmacroProtocol(
    String transportSessionId, {
    Map<String, Object?> options = const {},
  }) async => 'protocol-$transportSessionId';

  @override
  Stream<NativeProtocolEvent> protocolEvents(String protocolSessionId) =>
      _protocolEvents
          .putIfAbsent(
            protocolSessionId,
            () => StreamController<NativeProtocolEvent>.broadcast(),
          )
          .stream;

  @override
  Stream<Map<String, Object?>> transportEscalationEvents(
    String transportSessionId,
  ) => const Stream<Map<String, Object?>>.empty();

  void testKeys(String deviceId, List<int> keys) {
    _protocolEvents['protocol-$deviceId']!.add(
      NativeProtocolEvent(
        type: NativeProtocolEventType.busy,
        reason: 'testKeys',
        payload: {'keys': keys},
      ),
    );
  }

  @override
  Future<void> closeProtocol(String protocolSessionId) async {}

  Future<void> close() async {
    for (final controller in _protocolEvents.values) {
      await controller.close();
    }
  }
}
