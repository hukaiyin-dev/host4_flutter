import 'gmacro_gamepad_key.dart';
import 'gmacro_support_enums.dart';
import 'package:host4_flutter_device_native/host4_flutter_device_native.dart';

sealed class GmacroRealtimeEvent {
  const GmacroRealtimeEvent();
}

/// 校准数据
class DeviceCalibrationEvent extends GmacroRealtimeEvent {
  const DeviceCalibrationEvent({
    required this.subId,
    required this.kind,
    required this.result,
    this.param1 = const <int>[],
    this.param2 = const <int>[],
    this.errorList = const <int>[],
  });

  final int subId;
  final DeviceCalibrationSubId? kind;
  final int result;
  final List<int> param1;
  final List<int> param2;
  final List<int> errorList;

  factory DeviceCalibrationEvent.fromNative(NativeDeviceAlignEvent event) {
    return DeviceCalibrationEvent(
      subId: event.subId,
      kind: DeviceCalibrationSubId.fromValue(event.subId),
      result: event.result,
      param1: event.param1,
      param2: event.param2,
      errorList: event.errorList,
    );
  }
}

class RawGmacroEvent extends GmacroRealtimeEvent {
  const RawGmacroEvent({required this.name, required this.payload});

  final String name;
  final Map<String, Object?> payload;
}

class TestEventMode extends GmacroRealtimeEvent {
  const TestEventMode({
    required this.rawKeys,
    required this.keys,
    required this.j1x,
    required this.j1y,
    required this.j2x,
    required this.j2y,
    required this.l2,
    required this.r2,
  });

  final List<int> rawKeys;
  final List<GamepadKey> keys;
  final int j1x;
  final int j1y;
  final int j2x;
  final int j2y;
  final int l2;
  final int r2;

  int get keyValue => rawKeys.isEmpty ? 0 : rawKeys.first;

  factory TestEventMode.fromMap(Map<String, Object?> map) {
    return TestEventMode(
      rawKeys: _asIntList(map['keys']),
      keys: _asGamepadKeys(map['keys']),
      j1x: _asInt(map['j1x'], defaultValue: 127),
      j1y: _asInt(map['j1y'], defaultValue: 127),
      j2x: _asInt(map['j2x'], defaultValue: 127),
      j2y: _asInt(map['j2y'], defaultValue: 127),
      l2: _asInt(map['l2']),
      r2: _asInt(map['r2']),
    );
  }
}

class DeviceKeysStateEvent extends GmacroRealtimeEvent {
  const DeviceKeysStateEvent({
    required this.rawKeys,
    required this.keys,
    required this.j1x,
    required this.j1xOriginal,
    required this.j1y,
    required this.j1yOriginal,
    required this.j2x,
    required this.j2xOriginal,
    required this.j2y,
    required this.j2yOriginal,
    required this.l2,
    required this.l2Original,
    required this.r2,
    required this.r2Original,
  });

  final List<int> rawKeys;
  final List<GamepadKey> keys;
  final int j1x;
  final int j1xOriginal;
  final int j1y;
  final int j1yOriginal;
  final int j2x;
  final int j2xOriginal;
  final int j2y;
  final int j2yOriginal;
  final int l2;
  final int l2Original;
  final int r2;
  final int r2Original;

  factory DeviceKeysStateEvent.fromMap(Map<String, Object?> map) {
    return DeviceKeysStateEvent(
      rawKeys: _asIntList(map['keys']),
      keys: _asGamepadKeys(map['keys']),
      j1x: _asInt(map['j1x']),
      j1xOriginal: _asInt(map['j1xOriginal']),
      j1y: _asInt(map['j1y']),
      j1yOriginal: _asInt(map['j1yOriginal']),
      j2x: _asInt(map['j2x']),
      j2xOriginal: _asInt(map['j2xOriginal']),
      j2y: _asInt(map['j2y']),
      j2yOriginal: _asInt(map['j2yOriginal']),
      l2: _asInt(map['l2']),
      l2Original: _asInt(map['l2Original']),
      r2: _asInt(map['r2']),
      r2Original: _asInt(map['r2Original']),
    );
  }

  /// Builds a full-state realtime event from Android USB [DPKeyEventRsp].
  ///
  /// Android USB currently exposes key/rocker updates on a dedicated dp-key
  /// channel. Converting them here keeps the upper Input/Cursor pipeline
  /// transport-agnostic.
  factory DeviceKeysStateEvent.fromNativeDpKeyEvent(NativeDpKeyEvent event) {
    return DeviceKeysStateEvent(
      rawKeys: event.keys,
      keys: event.keys
          .map((raw) => GamepadKey.fromValue(raw) ?? GamepadKey.none)
          .toList(growable: false),
      j1x: event.leftRockerXValue,
      j1xOriginal: event.leftRockerXOriginalValue,
      j1y: event.leftRockerYValue,
      j1yOriginal: event.leftRockerYOriginalValue,
      j2x: event.rightRockerXValue,
      j2xOriginal: event.rightRockerXOriginalValue,
      j2y: event.rightRockerYValue,
      j2yOriginal: event.rightRockerYOriginalValue,
      l2: event.leftKeyLTwoValue,
      l2Original: event.leftKeyLTOriginalValue,
      r2: event.rightKeyRTwoValue,
      r2Original: event.rightKeyRTOriginalValue,
    );
  }
}

int _asInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) {
    return defaultValue;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString()) ?? defaultValue;
}

List<int> _asIntList(dynamic value) {
  if (value is! List) {
    return const <int>[];
  }
  return value.map((item) => _asInt(item)).toList(growable: false);
}

List<GamepadKey> _asGamepadKeys(dynamic value) {
  return _asIntList(value)
      .map((raw) => GamepadKey.fromValue(raw) ?? GamepadKey.none)
      .toList(growable: false);
}
