import 'dart:async';

import 'package:flutter/foundation.dart';

import '../Models/gmacro_gamepad_key.dart';
import '../Models/gmacro_protocol_events.dart';
import '../gmacro_session.dart';
import 'gmacro_input_state.dart';

/// 按键边沿事件阶段。
///
/// - [down] 表示本帧按下
/// - [up] 表示本帧抬起
enum GmacroButtonPhase { down, up }

/// SDK 层统一的按键边沿事件。
///
/// 这个事件不是 native 原始事件，而是输入服务根据前后两帧状态做差分后生成的。
class GmacroButtonEvent {
  const GmacroButtonEvent({required this.key, required this.phase});

  final GamepadKey key;
  final GmacroButtonPhase phase;
}

/// 统一输入服务。
///
/// 作用：
/// 1. 监听 `GmacroSession.realtimeEvents`（BLE / USB 共用）
/// 2. 同时兼容 `devKeysState + testKeys`
/// 3. 产出统一的完整状态流 `states`
/// 4. 产出统一的按键边沿流 `buttonEvents`
class GmacroInputService {
  GmacroInputService();

  StreamSubscription<GmacroRealtimeEvent>? _inputSub;

  /// 持续广播“当前完整输入状态”。
  final _stateController = StreamController<GmacroInputState>.broadcast();

  /// 持续广播“按键 down / up 边沿事件”。
  final _buttonController = StreamController<GmacroButtonEvent>.broadcast();

  /// 最近一帧输入状态。
  ///
  /// 用于：
  /// - 对外暴露 `latestState`
  /// - 和新状态做差分，生成 down / up 事件
  GmacroInputState _latestState = GmacroInputState.empty();

  Stream<GmacroInputState> get states => _stateController.stream;
  Stream<GmacroButtonEvent> get buttonEvents => _buttonController.stream;

  GmacroInputState get latestState => _latestState;

  /// 绑定一个 GMacro session。
  ///
  /// 当前实现同时兼容两类输入事件：
  /// - `DeviceKeysStateEvent`
  /// - `TestEventMode`
  ///
  /// BLE 与 USB 均通过 `realtimeEvents` 注入，Input/Cursor 无需感知 transport 差异。
  ///
  /// 这样即使不同手柄随机上报 `devKeysState` 或 `testKeys`，
  /// 上层也仍然只面对统一输入状态。
  void bindSession(GmacroSession session) {
    _inputSub?.cancel();
    _latestState = GmacroInputState.empty();

    debugPrint('[GmacroInputService] bindSession — subscribing to realtimeEvents');

    _inputSub = session.realtimeEvents.listen(_onRealtimeEvent);
  }

  void _onRealtimeEvent(GmacroRealtimeEvent event) {
    debugPrint('[GmacroInputService] received ${event.runtimeType}: '
        'keys=${switch (event) { DeviceKeysStateEvent e => e.keys, TestEventMode e => e.keys, _ => [] }}');

    var nextState = switch (event) {
      DeviceKeysStateEvent() => GmacroInputState.fromDeviceKeysState(event),
      TestEventMode() => GmacroInputState.fromTestEventMode(event),
      _ => null,
    };

    if (nextState == null) {
      return;
    }

    // 将左摇杆偏差转为虚拟方向键，摇杆和 D-pad 共用 buttonEvents。
    nextState = nextState.mergeJoystickDirections();

    _emitDiff(_latestState, nextState);
    _latestState = nextState;
    _stateController.add(nextState);
  }

  /// 根据前后两帧 pressedKeys 差集生成按键边沿事件。
  ///
  /// - new - old -> down
  /// - old - new -> up
  void _emitDiff(GmacroInputState oldState, GmacroInputState newState) {
    for (final key in newState.pressedKeys.difference(oldState.pressedKeys)) {
      _buttonController.add(
        GmacroButtonEvent(key: key, phase: GmacroButtonPhase.down),
      );
    }

    for (final key in oldState.pressedKeys.difference(newState.pressedKeys)) {
      _buttonController.add(
        GmacroButtonEvent(key: key, phase: GmacroButtonPhase.up),
      );
    }
  }

  Future<void> dispose() async {
    await _inputSub?.cancel();
    await _stateController.close();
    await _buttonController.close();
  }
}
