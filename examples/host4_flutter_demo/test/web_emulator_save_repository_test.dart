import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_demo/pages/web_emulator/web_emulator_save_repository.dart';

void main() {
  late Directory root;
  late WebEmulatorSaveRepository repository;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('host4_web_emulator_test_');
    repository = WebEmulatorSaveRepository(
      rootDirectory: root,
      gameKey: 'a' * 64,
    );
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('persists quick and manual states with thumbnail metadata', () async {
    await repository.writeQuick(
      state: Uint8List.fromList(<int>[1, 2, 3]),
      thumbnail: Uint8List.fromList(<int>[7, 8]),
    );
    await repository.writeSlot(
      2,
      state: Uint8List.fromList(<int>[4, 5, 6]),
      thumbnail: Uint8List.fromList(<int>[9]),
    );

    final catalog = await repository.load();
    expect(catalog.quick?.thumbnailBytes, <int>[7, 8]);
    expect(catalog.manualAt(1), isNull);
    expect(catalog.manualAt(2)?.thumbnailBytes, <int>[9]);
    expect(await repository.readQuickState(), <int>[1, 2, 3]);
    expect(await repository.readSlotState(2), <int>[4, 5, 6]);
  });

  test('deletes states and keeps other slots intact', () async {
    await repository.writeQuick(state: Uint8List.fromList(<int>[1]));
    await repository.writeSlot(1, state: Uint8List.fromList(<int>[2]));
    await repository.writeSlot(2, state: Uint8List.fromList(<int>[3]));

    await repository.deleteQuick();
    await repository.deleteSlot(1);

    final catalog = await repository.load();
    expect(catalog.quick, isNull);
    expect(catalog.manualAt(1), isNull);
    expect(await repository.readSlotState(2), <int>[3]);
  });

  test('persists SRAM separately from save states', () async {
    expect(await repository.readSram(), isNull);

    await repository.writeSram(Uint8List.fromList(<int>[10, 11, 12]));

    expect(await repository.readSram(), <int>[10, 11, 12]);
  });

  test('rejects unsafe game keys and invalid slots', () {
    expect(
      () => WebEmulatorSaveRepository(rootDirectory: root, gameKey: '../game'),
      throwsArgumentError,
    );
    expect(() => repository.readSlotState(0), throwsArgumentError);
  });
}
