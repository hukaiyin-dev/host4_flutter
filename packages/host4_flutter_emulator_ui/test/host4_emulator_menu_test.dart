import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_emulator_ui/host4_flutter_emulator_ui.dart';

void main() {
  testWidgets('menu exposes the host4 session actions', (tester) async {
    final actions = _FakeActions();
    var openedSaveManager = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Host4EmulatorMenuOverlay(
          actions: actions,
          onOpenSaveManager: () => openedSaveManager = true,
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('menu.quick_save')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('menu.quick_load')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('menu.save_manager')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('menu.restart')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('menu.exit')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('menu.continue')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('menu.quick_save')));
    await tester.pump();
    expect(actions.calls, contains('quickSave'));

    await tester.tap(find.byKey(const ValueKey<String>('menu.speed')));
    await tester.pump();
    expect(actions.rate, 2);

    await tester.tap(find.byKey(const ValueKey<String>('menu.save_manager')));
    expect(openedSaveManager, isTrue);

    await tester.tap(find.byKey(const ValueKey<String>('menu.continue')));
    await tester.pump();
    expect(actions.calls, contains('resume'));
  });
}

class _FakeActions extends Host4EmulatorSessionActions {
  final List<String> calls = <String>[];

  @override
  double rate = 1;

  @override
  Future<void> deleteQuickSave() async => calls.add('deleteQuick');

  @override
  Future<void> deleteSlot(int slot) async => calls.add('delete:$slot');

  @override
  Future<void> exit() async => calls.add('exit');

  @override
  Future<void> loadSlot(int slot) async => calls.add('load:$slot');

  @override
  Future<void> quickLoad() async => calls.add('quickLoad');

  @override
  Future<void> quickSave() async => calls.add('quickSave');

  @override
  Future<void> restart() async => calls.add('restart');

  @override
  Future<void> resume() async => calls.add('resume');

  @override
  Future<void> saveSlot(int slot) async => calls.add('save:$slot');

  @override
  Future<void> setRate(double value) async {
    rate = value;
    calls.add('rate:$value');
  }
}
