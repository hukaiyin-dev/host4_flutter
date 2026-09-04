import 'dart:convert';
import 'dart:typed_data';

import 'package:host4_flutter_emulator_ui/host4_flutter_emulator_ui.dart';
import 'package:host4_flutter_log/host4_flutter_log.dart';
import 'package:host4_flutter_web_emulator/host4_flutter_web_emulator.dart';

import 'web_emulator_save_repository.dart';

final _sessionLog = Host4Logger('WebEmulatorSession');

abstract interface class WebEmulatorRuntime {
  Future<Host4WebEmulatorState> saveState();

  Future<void> loadState(String stateBase64);

  Future<String> saveSram();

  Future<void> pause();

  Future<void> resume({double? rate});

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
  Future<void> resume({double? rate}) => controller.resume(rate: rate);

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
  double? _pendingRate;
  bool _paused = false;
  Future<void>? _sramPersistFuture;
  String? _sramPersistReason;
  Future<void>? _shutdownFuture;
  String? _shutdownReason;

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
    _sessionLog.info('quick_load_started bytes=${state.length}');
    await runtime.loadState(base64Encode(state));
    _sessionLog.debug('quick_load_state_dispatched');
    await resume();
    _sessionLog.info('quick_load_completed bytes=${state.length}');
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
    _sessionLog.info('slot_load_started slot=$slot bytes=${state.length}');
    await runtime.loadState(base64Encode(state));
    _sessionLog.debug('slot_load_state_dispatched slot=$slot');
    await resume();
    _sessionLog.info('slot_load_completed slot=$slot bytes=${state.length}');
  }

  @override
  Future<void> deleteSlot(int slot) async {
    await repository.deleteSlot(slot);
    onChanged?.call();
  }

  @override
  Future<void> setRate(double value) async {
    if (_paused) {
      _pendingRate = value;
      _rate = value;
      _sessionLog.info('rate_staged paused=true target=$value');
      onChanged?.call();
      return;
    }
    _sessionLog.info('rate_apply_started paused=false target=$value');
    await runtime.setRate(value);
    _rate = value;
    _sessionLog.info('rate_apply_completed target=$value');
    onChanged?.call();
  }

  Future<void> pause() async {
    _sessionLog.debug('pause_started');
    await runtime.pause();
    _paused = true;
    _sessionLog.debug('pause_completed');
  }

  @override
  Future<void> resume() async {
    final pendingRate = _pendingRate;
    _sessionLog.info('resume_started pending_rate=$pendingRate');
    await runtime.resume(rate: pendingRate);
    _paused = false;
    _pendingRate = null;
    _sessionLog.info('resume_completed applied_rate=${pendingRate ?? _rate}');
    await onReturnToGame?.call();
  }

  @override
  Future<void> restart() async {
    await runtime.restart();
    await resume();
  }

  @override
  Future<void> exit() => shutdown(reason: 'menu_exit');

  Future<void> shutdown({required String reason}) {
    final inFlight = _shutdownFuture;
    if (inFlight != null) {
      _sessionLog.info(
        'shutdown_reused requested_reason=$reason '
        'active_reason=$_shutdownReason',
      );
      return inFlight;
    }

    _shutdownReason = reason;
    final operation = _shutdownOnce(reason);
    _shutdownFuture = operation;
    return operation;
  }

  Future<void> _shutdownOnce(String reason) async {
    _sessionLog.info('shutdown_started reason=$reason');
    try {
      try {
        await persistSram(reason: 'shutdown:$reason');
      } finally {
        _sessionLog.info('runtime_exit_started reason=$reason');
        try {
          await runtime.exit();
          _sessionLog.info('runtime_exit_completed reason=$reason');
        } finally {
          await onExit?.call();
        }
      }
      _sessionLog.info('shutdown_completed reason=$reason');
    } catch (error, stackTrace) {
      _sessionLog.error(
        'shutdown_failed reason=$reason',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> persistSram({String reason = 'manual'}) {
    final inFlight = _sramPersistFuture;
    if (inFlight != null) {
      _sessionLog.info(
        'sram_save_reused requested_reason=$reason '
        'active_reason=$_sramPersistReason',
      );
      return inFlight;
    }

    _sramPersistReason = reason;
    late final Future<void> operation;
    operation = _persistSramOnce(reason).whenComplete(() {
      if (identical(_sramPersistFuture, operation)) {
        _sramPersistFuture = null;
        _sramPersistReason = null;
      }
    });
    _sramPersistFuture = operation;
    return operation;
  }

  Future<void> _persistSramOnce(String reason) async {
    _sessionLog.info('sram_save_started reason=$reason');
    try {
      final sramBase64 = await runtime.saveSram();
      final bytes = base64Decode(sramBase64);
      await repository.writeSram(bytes);
      _sessionLog.info(
        'sram_save_completed reason=$reason bytes=${bytes.length}',
      );
    } catch (error, stackTrace) {
      _sessionLog.error(
        'sram_save_failed reason=$reason',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  static Uint8List? _decodeOptional(String? value) {
    return value == null ? null : base64Decode(value);
  }
}
