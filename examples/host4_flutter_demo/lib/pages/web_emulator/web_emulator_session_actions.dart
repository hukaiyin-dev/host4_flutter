import 'dart:convert';
import 'dart:typed_data';

import 'package:host4_flutter_emulator_ui/host4_flutter_emulator_ui.dart';
import 'package:host4_flutter_web_emulator/host4_flutter_web_emulator.dart';

import 'web_emulator_save_repository.dart';

abstract interface class WebEmulatorRuntime {
  Future<Host4WebEmulatorState> saveState();

  Future<void> loadState(String stateBase64);

  Future<String> saveSram();

  Future<void> pause();

  Future<void> resume();

  Future<void> restart();

  Future<void> exit();

  Future<void> setRate(double rate);
}

class Host4WebEmulatorRuntime implements WebEmulatorRuntime {
  const Host4WebEmulatorRuntime(this.controller);

  final Host4WebEmulatorController controller;

  @override
  Future<void> exit() => controller.exit();

  @override
  Future<void> loadState(String stateBase64) =>
      controller.loadState(stateBase64);

  @override
  Future<void> pause() => controller.pause();

  @override
  Future<void> restart() => controller.restart();

  @override
  Future<void> resume() => controller.resume();

  @override
  Future<Host4WebEmulatorState> saveState() => controller.saveState();

  @override
  Future<String> saveSram() => controller.saveSram();

  @override
  Future<void> setRate(double rate) => controller.setRate(rate);
}

class WebEmulatorSessionActions extends Host4EmulatorSessionActions {
  WebEmulatorSessionActions({
    required this.runtime,
    required this.repository,
    this.onChanged,
    this.onExit,
    this.onReturnToGame,
  });

  final WebEmulatorRuntime runtime;
  final WebEmulatorSaveRepository repository;
  final void Function()? onChanged;
  final Future<void> Function()? onExit;
  final Future<void> Function()? onReturnToGame;

  double _rate = 1;

  @override
  double get rate => _rate;

  @override
  Future<void> quickSave() async {
    final snapshot = await runtime.saveState();
    await repository.writeQuick(
      state: base64Decode(snapshot.stateBase64),
      thumbnail: _decodeOptional(snapshot.thumbnailBase64),
    );
    onChanged?.call();
  }

  @override
  Future<void> quickLoad() async {
    final state = await repository.readQuickState();
    await runtime.loadState(base64Encode(state));
    await onReturnToGame?.call();
  }

  @override
  Future<void> deleteQuickSave() async {
    await repository.deleteQuick();
    onChanged?.call();
  }

  @override
  Future<void> saveSlot(int slot) async {
    final snapshot = await runtime.saveState();
    await repository.writeSlot(
      slot,
      state: base64Decode(snapshot.stateBase64),
      thumbnail: _decodeOptional(snapshot.thumbnailBase64),
    );
    onChanged?.call();
  }

  @override
  Future<void> loadSlot(int slot) async {
    final state = await repository.readSlotState(slot);
    await runtime.loadState(base64Encode(state));
    await onReturnToGame?.call();
  }

  @override
  Future<void> deleteSlot(int slot) async {
    await repository.deleteSlot(slot);
    onChanged?.call();
  }

  @override
  Future<void> setRate(double value) async {
    await runtime.setRate(value);
    _rate = value;
    onChanged?.call();
  }

  @override
  Future<void> resume() async {
    await runtime.resume();
    await onReturnToGame?.call();
  }

  @override
  Future<void> restart() async {
    await runtime.restart();
    await runtime.resume();
    await onReturnToGame?.call();
  }

  @override
  Future<void> exit() async {
    try {
      await persistSram();
    } finally {
      try {
        await runtime.exit();
      } finally {
        await onExit?.call();
      }
    }
  }

  Future<void> persistSram() async {
    final sramBase64 = await runtime.saveSram();
    await repository.writeSram(base64Decode(sramBase64));
  }

  static Uint8List? _decodeOptional(String? value) {
    return value == null ? null : base64Decode(value);
  }
}
