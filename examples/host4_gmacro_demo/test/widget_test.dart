import 'package:flutter_test/flutter_test.dart';
import 'package:host4_gmacro_demo/main.dart';

void main() {
  testWidgets('shows standalone GMacro entry page', (tester) async {
    await tester.pumpWidget(const Host4GmacroDemoApp());

    expect(find.text('GMacro 调试'), findsOneWidget);
    expect(find.text('BLE 连接'), findsOneWidget);
  });
}
