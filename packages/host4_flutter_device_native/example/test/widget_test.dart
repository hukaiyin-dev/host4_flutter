// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:host4_flutter_device_native_example/main.dart';

void main() {
  testWidgets('shows GMacro lab entry', (WidgetTester tester) async {
    await tester.pumpWidget(const Host4FlutterDeviceNativeExampleApp());

    expect(find.text('Host4 Flutter Labs'), findsOneWidget);
    expect(find.text('GMacro 调试'), findsOneWidget);
  });
}
