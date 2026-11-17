import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_gmacro_demo_ui/host4_flutter_gmacro_demo_ui.dart';
import 'package:host4_flutter_transport/host4_flutter_transport.dart';

void main() {
  final calls = <String>[];
  Completer<String>? attachGate;
  setUp(() {
    calls.clear();
    attachGate = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('host4_flutter_device_native'),
          (call) async {
            calls.add(call.method);
            if (call.method == 'attachGmacroProtocol') {
              return attachGate == null
                  ? 'test-protocol'
                  : await attachGate!.future;
            }
            return null;
          },
        );
    for (final channel in [
      'host4_flutter_device_native/native_log',
      'host4_flutter_device_native/protocol_events/test-protocol',
      'host4_flutter_device_native/ota_events/test-protocol',
    ]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(channel), (call) async {
            calls.add('$channel:${call.method}');
            return null;
          });
    }
  });

  testWidgets('MFi waits for ready and disables commands after disconnect', (
    tester,
  ) async {
    final transport = _FakeTransportSession(
      device: const DeviceDescriptor(
        id: 'mfi-test',
        name: 'MFi Accessory',
        kind: TransportKind.mfi,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: GmacroSessionPage(transport: transport)),
    );
    await tester.pumpAndSettle();
    OutlinedButton button(String text) => tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, text),
    );
    expect(calls, isNot(contains('attachGmacroProtocol')));
    expect(button('Fetch Version').onPressed, isNull);
    expect(button('打开 API 测试页').onPressed, isNull);
    transport.emit(const TransportConnected());
    await tester.pumpAndSettle();
    expect(calls, isNot(contains('attachGmacroProtocol')));

    transport.emit(const TransportReady());
    await tester.pumpAndSettle();
    expect(calls.where((call) => call == 'attachGmacroProtocol'), hasLength(1));
    expect(button('Fetch Version').onPressed, isNotNull);
    expect(button('打开 API 测试页').onPressed, isNotNull);
    transport.emit(const TransportReady());
    await tester.pumpAndSettle();
    expect(calls.where((call) => call == 'attachGmacroProtocol'), hasLength(1));

    transport.emit(const TransportDisconnected());
    await tester.pumpAndSettle();
    expect(button('Fetch Version').onPressed, isNull);
    expect(button('OTA 测试').onPressed, isNull);
    expect(button('打开 API 测试页').onPressed, isNull);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(calls, contains('closeProtocol'));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('late MFi attach cannot enable a disconnected session', (
    tester,
  ) async {
    attachGate = Completer<String>();
    final transport = _FakeTransportSession(
      device: const DeviceDescriptor(
        id: 'mfi-late',
        name: 'MFi Accessory',
        kind: TransportKind.mfi,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: GmacroSessionPage(transport: transport)),
    );
    transport.emit(const TransportReady());
    await tester.pumpAndSettle();
    expect(calls, contains('attachGmacroProtocol'));
    transport.emit(const TransportDisconnected());
    await tester.pumpAndSettle();
    attachGate!.complete('test-protocol');
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, '打开 API 测试页'),
          )
          .onPressed,
      isNull,
    );
    expect(calls, contains('closeProtocol'));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('session page status bar fits narrow iPhone width', (
    tester,
  ) async {
    final errors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previousOnError);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: GmacroSessionPage(
          transport: _FakeTransportSession(
            device: const DeviceDescriptor(
              id: 'system-connected',
              name: 'Mobapad-ML35',
              kind: TransportKind.ble,
            ),
          ),
        ),
      ),
    );

    expect(
      errors.where(
        (error) => error.exceptionAsString().contains('RenderFlex overflowed'),
      ),
      isEmpty,
    );
  });
}

class _FakeTransportSession implements TransportSession {
  _FakeTransportSession({required this.device});

  final _controller = StreamController<TransportEvent>.broadcast();

  @override
  final DeviceDescriptor device;

  @override
  String get id => 'fake-system-connected';

  @override
  Stream<TransportEvent> get events => _controller.stream;

  void emit(TransportEvent event) => _controller.add(event);

  @override
  Future<void> disconnect() async {
    await _controller.close();
  }
}
