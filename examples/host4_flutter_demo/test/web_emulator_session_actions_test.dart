import 'dart:convert';
import 'dart:async';
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
      expect(runtime.resumeCount, 1);
      expect((await repository.load()).quick?.thumbnailBytes, isNotEmpty);
    },
  );

  test('manual slots route save load and delete', () async {
    await actions.saveSlot(3);
    await actions.loadSlot(3);
    expect(runtime.loadedState, 'STATE');
    expect(runtime.resumeCount, 1);

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

  test('concurrent SRAM persistence shares one runtime export', () async {
    final export = Completer<String>();
    runtime.sramCompleter = export;

    final first = actions.persistSram();
    final second = actions.persistSram();

    expect(runtime.sramSaveCount, 1);
    expect(runtime.exited, isFalse);

    export.complete('U1JBTQ==');
    await Future.wait(<Future<void>>[first, second]);

    expect(await repository.readSram(), 'SRAM'.codeUnits);
  });

  test('rate selected in a paused menu is applied during resume', () async {
    await actions.pause();
    await actions.setRate(2);

    expect(actions.rate, 2);
    expect(runtime.calls, <String>['pause']);

    await actions.resume();

    expect(runtime.calls, <String>['pause', 'resume:2.0']);
  });

  test('quick load resumes with the rate selected in the menu', () async {
    await actions.quickSave();
    runtime.calls.clear();
    await actions.pause();
    await actions.setRate(2);

    await actions.quickLoad();

    expect(runtime.calls, <String>['pause', 'loadState', 'resume:2.0']);
  });

  test('slot load resumes with the rate selected in the menu', () async {
    await actions.saveSlot(3);
    runtime.calls.clear();
    await actions.pause();
    await actions.setRate(2);

    await actions.loadSlot(3);

    expect(runtime.calls, <String>['pause', 'loadState', 'resume:2.0']);
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

  test(
    'shutdown waits for an in-flight SRAM export before runtime exit',
    () async {
      final export = Completer<String>();
      runtime.sramCompleter = export;

      final saving = actions.persistSram();
      final shutdown = actions.shutdown(reason: 'switch_rom');
      await Future<void>.delayed(Duration.zero);

      expect(runtime.exitCount, 0);

      export.complete('U1JBTQ==');
      await Future.wait(<Future<void>>[saving, shutdown]);

      expect(runtime.sramSaveCount, 1);
      expect(runtime.exitCount, 1);
      expect(await repository.readSram(), 'SRAM'.codeUnits);
    },
  );

  test('concurrent shutdown requests close one session once', () async {
    var finishCount = 0;
    actions = WebEmulatorSessionActions(
      runtime: runtime,
      repository: repository,
      onExit: () async => finishCount += 1,
    );

    final first = actions.shutdown(reason: 'menu_exit');
    final second = actions.shutdown(reason: 'switch_rom');
    await Future.wait(<Future<void>>[first, second]);

    expect(runtime.sramSaveCount, 1);
    expect(runtime.exitCount, 1);
    expect(finishCount, 1);
  });
}

class _FakeRuntime implements WebEmulatorRuntime {
  final List<String> calls = <String>[];
  String? loadedState;
  double rate = 1;
  bool failSram = false;
  bool exited = false;
  int exitCount = 0;
  int resumeCount = 0;
  int sramSaveCount = 0;
  Completer<String>? sramCompleter;

  @override
  Future<void> exit() async {
    exitCount += 1;
    exited = true;
  }

  @override
  Future<void> loadState(String stateBase64) async {
    calls.add('loadState');
    loadedState = utf8.decode(base64Decode(stateBase64));
  }

  @override
  Future<void> pause() async => calls.add('pause');

  @override
  Future<void> restart() async {}

  @override
  Future<void> resume({double? rate}) async {
    resumeCount += 1;
    calls.add('resume:$rate');
  }

  @override
  Future<Host4WebEmulatorState> saveState() async {
    calls.add('saveState');
    return const Host4WebEmulatorState(
      stateBase64: 'U1RBVEU=',
      thumbnailBase64: 'UE5H',
    );
  }

  @override
  Future<String> saveSram() async {
    sramSaveCount += 1;
    final completer = sramCompleter;
    if (completer != null) return completer.future;
    if (failSram) throw StateError('SRAM failed');
    return 'U1JBTQ==';
  }

  @override
  Future<void> setRate(double value) async {
    calls.add('rate:$value');
    rate = value;
  }
}
