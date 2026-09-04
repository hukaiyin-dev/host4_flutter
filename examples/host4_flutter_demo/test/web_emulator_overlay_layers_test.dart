import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_demo/pages/web_emulator/web_emulator_overlay_layers.dart';

void main() {
  testWidgets('menu overlay keeps controls below mask and SET above it', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: WebEmulatorOverlayLayers(
          game: SizedBox(key: ValueKey<String>('game')),
          controls: SizedBox(key: ValueKey<String>('controls')),
          overlay: SizedBox(key: ValueKey<String>('overlay')),
          activeMenuButton: SizedBox(key: ValueKey<String>('active_set')),
        ),
      ),
    );

    expect(find.byKey(const ValueKey<String>('controls')), findsOneWidget);
    final stack = tester.widget<Stack>(find.byType(Stack));
    expect(stack.children.map((child) => child.key), const <Key?>[
      ValueKey<String>('game'),
      ValueKey<String>('controls'),
      ValueKey<String>('overlay'),
      ValueKey<String>('active_set'),
    ]);
  });
}
