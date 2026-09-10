import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_emulator_ui/host4_flutter_emulator_ui.dart';

void main() {
  testWidgets('portrait menu clears the fixed Pantas button with a safe inset', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: MediaQuery(
      data: const MediaQueryData(size: Size(390, 844), padding: EdgeInsets.only(top: 47)),
      child: Stack(fit: StackFit.expand, children: [
        Host4EmulatorMenuOverlay(actions: _FakeActions(), onOpenSaveManager: () {}),
        Host4EmulatorActiveMenuButton(
          layoutStyle: Host4EmulatorControlLayoutStyle.silicone,
          onTap: () {},
        ),
      ]),
    )));
    await tester.pumpAndSettle();
    final menu = tester.getRect(find.byKey(const ValueKey('menu.quick_save')));
    final button = tester.getRect(find.byKey(const ValueKey('controls.active_menu')));
    expect(menu.top, greaterThanOrEqualTo(button.bottom + 12));
    expect(menu.top, 122);
  });
  testWidgets('A activates focused menu action and B returns', (tester) async {
    final actions = _FakeActions();
    var backs = 0;
    await tester.pumpWidget(MaterialApp(home: Host4EmulatorUiShortcuts(
      onBack: () => backs++,
      child: Host4EmulatorMenuOverlay(actions: actions, onOpenSaveManager: () {}),
    )));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.pump();
    expect(actions.calls, ['resume']);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
    expect(backs, 1);
  });
  testWidgets(
    'reopening menu refreshes manual usage without counting quick save',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final source = _SaveSource();
      Future<void> openMenu() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Host4EmulatorMenuOverlay(
              actions: _FakeActions(),
              dataSource: source,
              onOpenSaveManager: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await openMenu();
      expect(find.text('0/5 已用'), findsOneWidget);
      for (final count in [1, 5, 0]) {
        await tester.pumpWidget(const SizedBox.shrink());
        source.count = count;
        await openMenu();
        expect(find.text('$count/5 已用'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );

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
    var openedKeyLocator = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Host4EmulatorMenuOverlay(
          actions: actions,
          onOpenSaveManager: () => openedSaveManager = true,
          onOpenLayoutPicker: () => openedLayoutPicker = true,
          onOpenKeyLocator: () => openedKeyLocator = true,
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
    expect(find.byKey(const ValueKey<String>('menu.key_locator')), findsOneWidget);

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
    await tester.tap(find.byKey(const ValueKey<String>('menu.key_locator')));
    expect(openedKeyLocator, isTrue);

    await tester.tap(find.byKey(const ValueKey<String>('menu.continue')));
    await tester.pump();
    expect(actions.calls, contains('resume'));
  });

  testWidgets('consumer can hide the manual layout action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Host4EmulatorMenuOverlay(
          actions: _FakeActions(),
          onOpenSaveManager: () {},
          showLayoutAction: false,
        ),
      ),
    );

    expect(find.byKey(const ValueKey<String>('menu.layout')), findsNothing);
    expect(find.text('切换布局'), findsNothing);
  });
}

class _SaveSource implements Host4EmulatorSaveDataSource {
  int count = 0;

  @override
  Future<Host4EmulatorSaveCatalog> load() async => Host4EmulatorSaveCatalog(
    quick: Host4EmulatorSaveEntry(slot: 0, modifiedAt: DateTime(2026)),
    manual: [
      for (var slot = 1; slot <= count; slot++)
        Host4EmulatorSaveEntry(slot: slot, modifiedAt: DateTime(2026)),
    ],
  );
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
