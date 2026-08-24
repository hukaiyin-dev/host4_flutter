import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_demo/pages/web_emulator/web_emulator_save_repository.dart';
import 'package:host4_flutter_demo/pages/web_emulator/web_emulator_session_actions.dart';
import 'package:host4_flutter_web_emulator/host4_flutter_web_emulator.dart';

void main() {
  late Directory root;
  late WebEmulatorSaveRepository repository;
  late _FakeRuntime runtime;
  late WebEmulatorSessionActions actions;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('host4_session_test_');
    repository = WebEmulatorSaveRepository(
      rootDirectory: root,
      gameKey: 'b' * 64,
    );
    runtime = _FakeRuntime();
    actions = WebEmulatorSessionActions(
      runtime: runtime,
      repository: repository,
    );
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test(
    'quick save and load round-trip through runtime and repository',
    () async {
      await actions.quickSave();
      await actions.quickLoad();

      expect(runtime.loadedState, 'STATE');
      expect((await repository.load()).quick?.thumbnailBytes, isNotEmpty);
    },
  );

  test('manual slots route save load and delete', () async {
    await actions.saveSlot(3);
    await actions.loadSlot(3);
    expect(runtime.loadedState, 'STATE');

    await actions.deleteSlot(3);
    expect((await repository.load()).manualAt(3), isNull);
  });

  test('rate and SRAM persistence are explicit', () async {
    await actions.setRate(2);
    await actions.persistSram();

    expect(actions.rate, 2);
    expect(runtime.rate, 2);
    expect(await repository.readSram(), 'SRAM'.codeUnits);
  });

  test('exit still closes the runtime when SRAM persistence fails', () async {
    var finished = false;
    runtime.failSram = true;
    actions = WebEmulatorSessionActions(
      runtime: runtime,
      repository: repository,
      onExit: () async => finished = true,
    );

    await expectLater(actions.exit(), throwsStateError);

    expect(runtime.exited, isTrue);
    expect(finished, isTrue);
  });
}

class _FakeRuntime implements WebEmulatorRuntime {
  String? loadedState;
  double rate = 1;
  bool failSram = false;
  bool exited = false;

  @override
  Future<void> exit() async => exited = true;

  @override
  Future<void> loadState(String stateBase64) async {
    loadedState = utf8.decode(base64Decode(stateBase64));
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> restart() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<Host4WebEmulatorState> saveState() async {
    return const Host4WebEmulatorState(
      stateBase64: 'U1RBVEU=',
      thumbnailBase64: 'UE5H',
    );
  }

  @override
  Future<String> saveSram() async {
    if (failSram) throw StateError('SRAM failed');
    return 'U1JBTQ==';
  }

  @override
  Future<void> setRate(double value) async {
    rate = value;
  }
}
