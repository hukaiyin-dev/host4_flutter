import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_emulator_ui/host4_flutter_emulator_ui.dart';

void main() {
  testWidgets('portrait menu matches the Pantas 2x3 card geometry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Host4EmulatorMenuOverlay(
          actions: _FakeActions(),
          onOpenSaveManager: () {},
          onOpenLayoutPicker: () {},
        ),
      ),
    );

    final quickSave = find.byKey(const ValueKey<String>('menu.quick_save'));
    final exit = find.byKey(const ValueKey<String>('menu.exit'));
    final saveManager = find.byKey(const ValueKey<String>('menu.save_manager'));
    final speed = find.byKey(const ValueKey<String>('menu.speed'));
    final quickLoad = find.byKey(const ValueKey<String>('menu.quick_load'));
    final continueGame = find.byKey(const ValueKey<String>('menu.continue'));

    expect(tester.getSize(quickSave), const Size(167, 102));
    expect(tester.getTopLeft(quickSave), const Offset(24, 75));
    expect(tester.getTopLeft(exit), const Offset(199, 75));
    expect(tester.getTopLeft(saveManager), const Offset(24, 185));
    expect(tester.getTopLeft(speed), const Offset(199, 185));
    expect(tester.getTopLeft(quickLoad), const Offset(24, 295));
    expect(tester.getTopLeft(continueGame), const Offset(199, 295));
    expect(find.text('游戏菜单'), findsNothing);
    expect(
      find.ancestor(of: find.text('快速存档'), matching: find.byType(Material)),
      findsOneWidget,
    );
  });

  testWidgets('menu exposes the host4 session actions', (tester) async {
    final actions = _FakeActions();
    var openedSaveManager = false;
    var openedLayoutPicker = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Host4EmulatorMenuOverlay(
          actions: actions,
          onOpenSaveManager: () => openedSaveManager = true,
          onOpenLayoutPicker: () => openedLayoutPicker = true,
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
    expect(find.byKey(const ValueKey<String>('menu.exit')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('menu.continue')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('menu.layout')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('menu.quick_save')));
    await tester.pump();
    expect(actions.calls, contains('quickSave'));

    await tester.tap(find.byKey(const ValueKey<String>('menu.speed')));
    await tester.pump();
    expect(actions.rate, 2);

    await tester.tap(find.byKey(const ValueKey<String>('menu.save_manager')));
    expect(openedSaveManager, isTrue);

    await tester.tap(find.byKey(const ValueKey<String>('menu.layout')));
    await tester.pump();
    expect(openedLayoutPicker, isTrue);

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
