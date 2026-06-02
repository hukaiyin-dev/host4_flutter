import '../Models/gmacro_gamepad_key.dart';
import '../Models/gmacro_protocol_events.dart';

/// 统一输入状态的来源。
///
/// - [devKeysState] 表示来自设备完整状态上报，通常包含 original 字段。
/// - [testKeys] 表示来自测试模式上报，字段相对少一些。
enum GmacroInputSource { devKeysState, testKeys }

/// SDK 内部统一输入状态模型。
///
/// 这个类的作用不是表达“原始协议事件”，而是表达：
/// 当前这一帧，手柄整体状态是什么。
///
/// 后续不管是：
/// - 全局光标移动
/// - 页面焦点导航
/// - 确认 / 返回
/// - 调试面板展示
///
/// 都应该优先消费这个统一状态，而不是直接消费 native 原始事件。
class GmacroInputState {
  const GmacroInputState({
    required this.source,
    required this.pressedKeys,
    required this.rawKeys,
    required this.j1x,
    required this.j1y,
    required this.j2x,
    required this.j2y,
    required this.l2,
    required this.r2,
    required this.j1xOriginal,
    required this.j1yOriginal,
    required this.j2xOriginal,
    required this.j2yOriginal,
    required this.l2Original,
    required this.r2Original,
  });

  /// 空状态。
  ///
  /// 用于：
  /// - 输入系统初始化时的默认值
  /// - 尚未收到任何输入事件时的兜底状态
  factory GmacroInputState.empty() {
    return const GmacroInputState(
      source: GmacroInputSource.devKeysState,
      pressedKeys: <GamepadKey>{},
      rawKeys: <int>[],
      j1x: 127,
      j1y: 127,
      j2x: 127,
      j2y: 127,
      l2: 0,
      r2: 0,
      j1xOriginal: 127,
      j1yOriginal: 127,
      j2xOriginal: 127,
      j2yOriginal: 127,
      l2Original: 0,
      r2Original: 0,
    );
  }

  /// 从完整设备状态事件构造统一输入状态。
  factory GmacroInputState.fromDeviceKeysState(DeviceKeysStateEvent event) {
    return GmacroInputState(
      source: GmacroInputSource.devKeysState,
      pressedKeys: event.keys.toSet(),
      rawKeys: event.rawKeys,
      j1x: event.j1x,
      j1y: event.j1y,
      j2x: event.j2x,
      j2y: event.j2y,
      l2: event.l2,
      r2: event.r2,
      j1xOriginal: event.j1xOriginal,
      j1yOriginal: event.j1yOriginal,
      j2xOriginal: event.j2xOriginal,
      j2yOriginal: event.j2yOriginal,
      l2Original: event.l2Original,
      r2Original: event.r2Original,
    );
  }

  /// 从测试模式事件构造统一输入状态。
  ///
  /// `testKeys` 没有 original 字段，所以这里直接回落到当前值。
  factory GmacroInputState.fromTestEventMode(TestEventMode event) {
    return GmacroInputState(
      source: GmacroInputSource.testKeys,
      pressedKeys: event.keys.toSet(),
      rawKeys: event.rawKeys,
      j1x: event.j1x,
      j1y: event.j1y,
      j2x: event.j2x,
      j2y: event.j2y,
      l2: event.l2,
      r2: event.r2,
      j1xOriginal: event.j1x,
      j1yOriginal: event.j1y,
      j2xOriginal: event.j2x,
      j2yOriginal: event.j2y,
      l2Original: event.l2,
      r2Original: event.r2,
    );
  }

  /// 当前状态来源，方便调试当前数据来自哪个 native 事件。
  final GmacroInputSource source;

  /// 当前被判定为按下的按键集合。
  final Set<GamepadKey> pressedKeys;

  /// 原始按键值列表。
  final List<int> rawKeys;

  /// 当前摇杆 / 扳机处理后数值。
  final int j1x;
  final int j1y;
  final int j2x;
  final int j2y;
  final int l2;
  final int r2;

  /// 当前摇杆 / 扳机 original 数值。
  ///
  /// - 对于 `devKeysState`，这里来自 native 原始字段。
  /// - 对于 `testKeys`，这里直接等于当前值。
  final int j1xOriginal;
  final int j1yOriginal;
  final int j2xOriginal;
  final int j2yOriginal;
  final int l2Original;
  final int r2Original;

  bool isPressed(GamepadKey key) => pressedKeys.contains(key);

  /// 把 0-255 的摇杆值归一化到大约 -1.0 ~ 1.0。
  ///
  /// 后续做：
  /// - 光标移动速度
  /// - 焦点方向控制
  /// - 连续输入判断
  ///
  /// 时直接用这些 getter 更方便。
  double get leftStickDx => (j1x - 127) / 127.0;
  double get leftStickDy => (j1y - 127) / 127.0;
  double get rightStickDx => (j2x - 127) / 127.0;
  double get rightStickDy => (j2y - 127) / 127.0;

  /// 将左摇杆偏差值转为虚拟方向键，合入 [pressedKeys]。
  ///
  /// 作用：摇杆偏移超过阈值时，自动在 [pressedKeys] 中加入对应的
  /// [GamepadKey.up] / [GamepadKey.down] / [GamepadKey.left] / [GamepadKey.right]，
  /// 使摇杆和方向键走同一套 [GmacroButtonEvent] 机制。
  ///
  /// 阈值与原生 [confirmationDirection:] 保持一致：
  /// - [center]: 摇杆居中值，默认 127
  /// - [threshold]: 超过 center ± threshold 才触发方向，默认 64
  ///   即 X < 63 → left, X > 191 → right, Y < 63 → up, Y > 191 → down
  GmacroInputState mergeJoystickDirections({
    int center = 127,
    int threshold = 64,
  }) {
    final dirKeys = <GamepadKey>{};
    if (j1x >= center + threshold) dirKeys.add(GamepadKey.right);
    if (j1x <= center - threshold) dirKeys.add(GamepadKey.left);
    if (j1y >= center + threshold) dirKeys.add(GamepadKey.down);
    if (j1y <= center - threshold) dirKeys.add(GamepadKey.up);

    if (dirKeys.isEmpty) return this;

    return GmacroInputState(
      source: source,
      pressedKeys: {...pressedKeys, ...dirKeys},
      rawKeys: rawKeys,
      j1x: j1x,
      j1y: j1y,
      j2x: j2x,
      j2y: j2y,
      l2: l2,
      r2: r2,
      j1xOriginal: j1xOriginal,
      j1yOriginal: j1yOriginal,
      j2xOriginal: j2xOriginal,
      j2yOriginal: j2yOriginal,
      l2Original: l2Original,
      r2Original: r2Original,
    );
  }
}
