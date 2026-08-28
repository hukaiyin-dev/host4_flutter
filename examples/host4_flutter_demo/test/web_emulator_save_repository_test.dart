import 'dart:convert';
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

  test('SRAM replacement does not mutate the previous file handle', () async {
    final gameDirectory = Directory('${root.path}/${'a' * 64}');
    await repository.writeSram(Uint8List.fromList(<int>[1, 2, 3]));
    final previous = await File('${gameDirectory.path}/sram.bin').open();

    try {
      await repository.writeSram(Uint8List.fromList(<int>[4, 5, 6]));

      expect(await previous.read(3), <int>[1, 2, 3]);
      expect(await repository.readSram(), <int>[4, 5, 6]);
    } finally {
      await previous.close();
    }
  });

  test('state thumbnail and index are replaced as complete files', () async {
    final gameDirectory = Directory('${root.path}/${'a' * 64}');
    await repository.writeQuick(
      state: Uint8List.fromList(<int>[1, 2, 3]),
      thumbnail: Uint8List.fromList(<int>[7, 8]),
    );
    final previousState = await File(
      '${gameDirectory.path}/quick/state.bin',
    ).open();
    final previousThumbnail = await File(
      '${gameDirectory.path}/quick/thumbnail.png',
    ).open();
    final previousIndex = await File('${gameDirectory.path}/index.json').open();

    try {
      await repository.writeQuick(
        state: Uint8List.fromList(<int>[4, 5, 6]),
        thumbnail: Uint8List.fromList(<int>[9, 10]),
      );
      await repository.writeSlot(1, state: Uint8List.fromList(<int>[11]));

      expect(await previousState.read(3), <int>[1, 2, 3]);
      expect(await previousThumbnail.read(2), <int>[7, 8]);
      final previousIndexJson =
          jsonDecode(
                utf8.decode(
                  await previousIndex.read(await previousIndex.length()),
                ),
              )
              as Map<String, dynamic>;
      expect((previousIndexJson['slots'] as Map).containsKey('1'), isFalse);
      expect(await repository.readQuickState(), <int>[4, 5, 6]);
      expect((await repository.load()).quick?.thumbnailBytes, <int>[9, 10]);
      expect((await repository.load()).manualAt(1), isNotNull);
    } finally {
      await previousState.close();
      await previousThumbnail.close();
      await previousIndex.close();
    }
  });

  test('rejects unsafe game keys and invalid slots', () {
    expect(
      () => WebEmulatorSaveRepository(rootDirectory: root, gameKey: '../game'),
      throwsArgumentError,
    );
    expect(() => repository.readSlotState(0), throwsArgumentError);
  });
}
