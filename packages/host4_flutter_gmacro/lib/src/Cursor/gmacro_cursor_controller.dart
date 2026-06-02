import 'dart:async';

import 'package:flutter/foundation.dart';

import '../Models/gmacro_gamepad_key.dart';
import '../Input/gmacro_input_service.dart';

/// 光标方向控制器。
///
/// 基于 [GmacroInputService.buttonEvents] 驱动，处理方向键和摇杆的方向事件。
///
/// ## 自动重复逻辑（对应原生 200ms debounce）
///
/// - 方向键 **按下瞬间** → 立即调用 [onMove] 移动一次
/// - **持续按住** → 每 [repeatInterval] 重复调用 [onMove]
/// - **松开** → 停止重复
///
/// 摇杆通过 [GmacroInputState.mergeJoystickDirections] 转为虚拟方向键后，
/// 与 D-pad 走完全相同的事件路径，不需要额外处理。
///
/// 使用方式：
/// ```dart
/// final controller = GmacroCursorController(
///   repeatInterval: Duration(milliseconds: 200),
///   onMove: (direction) { /* 移动光标 */ },
///   onConfirm: () { /* 确认 */ },
///   onBack: () { /* 返回 */ },
/// );
/// controller.bindInput(GmacroInputHub.currentService!);
/// ```
class GmacroCursorController {
  GmacroCursorController({
    this.repeatInterval = const Duration(milliseconds: 200),
    this.onMove,
    this.onConfirm,
    this.onBack,
  });

  /// 方向按住时的自动重复间隔。原生为 200ms。
  final Duration repeatInterval;

  /// 光标方向移动回调。
  final void Function(GamepadKey direction)? onMove;

  /// 确认回调（A 键）。
  final VoidCallback? onConfirm;

  /// 返回回调（B 键）。
  final VoidCallback? onBack;

  StreamSubscription<GmacroButtonEvent>? _buttonSub;
  Timer? _repeatTimer;

  /// 当前正在按下的方向键（可能多个同时按）。
  final Set<GamepadKey> _heldDirections = {};

  /// 绑定输入服务，开始监听方向事件。
  void bindInput(GmacroInputService input) {
    _buttonSub?.cancel();
    _buttonSub = input.buttonEvents.listen(_onButtonEvent);
  }

  void _onButtonEvent(GmacroButtonEvent event) {
    if (!_isDirectionKey(event.key)) {
      // 非方向键：分发确认/返回
      if (event.phase == GmacroButtonPhase.down) {
        switch (event.key) {
          case GamepadKey.a:
            onConfirm?.call();
          case GamepadKey.b:
            onBack?.call();
          default:
            break;
        }
      }
      return;
    }

    if (event.phase == GmacroButtonPhase.down) {
      // 按下 → 立即移动一次 + 启动自动重复
      _heldDirections.add(event.key);
      _onMoveOnce(event.key);
      _startRepeat();
    } else {
      // 松开 → 移除并判断是否停止重复
      _heldDirections.remove(event.key);
      if (_heldDirections.isEmpty) {
        _stopRepeat();
      }
    }
  }

  /// 立即移动一次。
  void _onMoveOnce(GamepadKey key) {
    // 如果内部有多个方向同时按住，取最先按下的方向
    onMove?.call(key);
  }

  void _startRepeat() {
    _repeatTimer?.cancel();
    _repeatTimer = Timer.periodic(repeatInterval, (_) {
      if (_heldDirections.isEmpty) {
        _stopRepeat();
        return;
      }
      onMove?.call(_heldDirections.first);
    });
  }

  void _stopRepeat() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  static bool _isDirectionKey(GamepadKey key) {
    return key == GamepadKey.up ||
        key == GamepadKey.down ||
        key == GamepadKey.left ||
        key == GamepadKey.right;
  }

  /// 释放资源。
  Future<void> dispose() async {
    _stopRepeat();
    await _buttonSub?.cancel();
  }
}
