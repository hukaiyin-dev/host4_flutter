import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_gmacro_demo_ui/host4_flutter_gmacro_demo_ui.dart';
import 'package:host4_flutter_transport/host4_flutter_transport.dart';

void main() {
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

  @override
  Future<void> disconnect() async {
    await _controller.close();
  }
}
