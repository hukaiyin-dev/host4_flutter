import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_emulator_ui/host4_flutter_emulator_ui.dart';

void main() {
  testWidgets('key locator opens with the Pantas guidance copy', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: Host4EmulatorKeyLocatorOverlay()),
    );

    expect(find.text('调整虚拟按键位置'), findsOneWidget);
    expect(find.text('按住并拖动虚拟按键，调整至合适的位置'), findsOneWidget);
    expect(find.text('支持上下拖动，再次按Pantas键保存全局布局'), findsOneWidget);
    expect(find.text('如使用Gamepatch，可与其按键位置对齐，获得更好的按键手感'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}
