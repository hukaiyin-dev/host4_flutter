import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_emulator_ui/host4_flutter_emulator_ui.dart';

void main() {
  testWidgets('save manager renders five slots and routes slot actions', (
    tester,
  ) async {
    final actions = _FakeActions();
    final dataSource = _FakeSaveDataSource(
      manual: <Host4EmulatorSaveEntry>[
        Host4EmulatorSaveEntry(
          slot: 1,
          modifiedAt: DateTime(2026, 8, 24, 10, 30),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Host4EmulatorSaveManager(
          actions: actions,
          dataSource: dataSource,
          onBack: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (var slot = 1; slot <= host4EmulatorManualSaveSlotCount; slot++) {
      final slotFinder = find.byKey(ValueKey<String>('save.slot.$slot'));
      if (slotFinder.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          slotFinder,
          160,
          scrollable: find.byType(Scrollable),
        );
      }
      expect(slotFinder, findsOneWidget);
    }
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('save.slot.1.load')),
      -160,
      scrollable: find.byType(Scrollable),
    );
    expect(
      find.byKey(const ValueKey<String>('save.slot.1.overwrite')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('save.slot.2.save')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey<String>('save.slot.1.load')));
    await tester.pumpAndSettle();
    expect(actions.calls, contains('load:1'));

    await tester.tap(find.byKey(const ValueKey<String>('save.slot.2.save')));
    await tester.pumpAndSettle();
    expect(actions.calls, contains('save:2'));
    expect(dataSource.loadCount, greaterThanOrEqualTo(3));
  });

  testWidgets('delete requires confirmation', (tester) async {
    final actions = _FakeActions();
    final dataSource = _FakeSaveDataSource(
      manual: <Host4EmulatorSaveEntry>[
        Host4EmulatorSaveEntry(slot: 1, modifiedAt: DateTime(2026, 8, 24)),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Host4EmulatorSaveManager(
          actions: actions,
          dataSource: dataSource,
          onBack: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('save.slot.1.delete')));
    await tester.pumpAndSettle();
    expect(find.text('删除存档？'), findsOneWidget);
    expect(actions.calls, isEmpty);

    await tester.tap(find.byKey(const ValueKey<String>('save.delete.confirm')));
    await tester.pumpAndSettle();
    expect(actions.calls, contains('delete:1'));
  });
}

class _FakeSaveDataSource implements Host4EmulatorSaveDataSource {
  _FakeSaveDataSource({this.manual = const <Host4EmulatorSaveEntry>[]});

  final List<Host4EmulatorSaveEntry> manual;
  int loadCount = 0;

  @override
  Future<Host4EmulatorSaveCatalog> load() async {
    loadCount += 1;
    return Host4EmulatorSaveCatalog(manual: manual);
  }
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
