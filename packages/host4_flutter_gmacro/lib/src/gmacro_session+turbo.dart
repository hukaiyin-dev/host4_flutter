import 'Models/gmacro_gamepad_key.dart';
import 'Models/gmacro_methods.dart';
import 'Models/gmacro_turbo_models.dart';
import 'gmacro_session.dart';

extension GmacroSessionTurbo on GmacroSession {
  /// 0x37 0x80: all keys share the same duration and device.
  /// Per-key timing uses updateKeyTurboTiming instead.
  Future<Map<String, Object?>> setTurboDatas16({
    required List<KeyTurboPayload> keyTurbos,
    int pressDuration = 1,
    int device = 0,
  }) {
    _validateTurbo16(
      keyTurbos,
      device: device,
      pressDuration: pressDuration,
      minimumInterval: 1,
    );
    return invoke(
      GmacroMethods.setTurboDatas16,
      arguments: {
        'keyTurbos': keyTurbos.map((e) => e.toMap()).toList(),
        'pressDuration': pressDuration,
        'device': device,
      },
    );
  }

  /// 0x37 0x80: each key keeps its own duration and interval (10 ms ticks).
  Future<Map<String, Object?>> updateKeyTurboTiming({
    required List<KeyTurboPayload> keyTurbos,
    int device = 0,
  }) {
    _validateTurbo16(keyTurbos, device: device);
    return invoke(
      GmacroMethods.updateKeyTurboTiming,
      arguments: {
        'keyTurbos': keyTurbos.map((e) => e.toTimingMap()).toList(),
        'device': device,
      },
    );
  }

  /// 0x37 0x81. Returns device and config with raw key/turbo/timing values.
  Future<Map<String, Object?>> queryKeyTurbo16(
    GamepadKey key, {
    int device = 0,
  }) {
    RangeError.checkValueInInterval(device, 0, 0xFF, 'device');
    return invoke(
      GmacroMethods.queryKeyTurbo16,
      arguments: {'key': key.value, 'device': device},
    );
  }

  /// 0x37 0x82. Native SDK assembles every 0x83 fragment before completing.
  Future<Map<String, Object?>> queryAllKeyTurbo16({int device = 0}) {
    RangeError.checkValueInInterval(device, 0, 0xFF, 'device');
    return invoke(
      GmacroMethods.queryAllKeyTurbo16,
      arguments: {'device': device},
    );
  }

  /// 设置连发速率
  Future<Map<String, Object?>> setTurboDatas({
    required List<KeyTurboPayload> keyTurbos,
  }) => invoke(
    GmacroMethods.setTurboDatas,
    arguments: {'keyTurbos': keyTurbos.map((e) => e.toMap()).toList()},
  );

  /// 查询支持连发的按键
  Future<Map<String, Object?>> querySupportedTurboKeys({
    required int profile,
  }) => invoke(
    GmacroMethods.querySupportedTurboKeys,
    arguments: {'profile': profile},
  );
}

void _validateTurbo16(
  List<KeyTurboPayload> items, {
  required int device,
  int? pressDuration,
  int minimumInterval = 1,
}) {
  RangeError.checkValueInInterval(device, 0, 0xFF, 'device');
  if (items.isEmpty) {
    throw ArgumentError.value(items, 'keyTurbos', 'Must not be empty');
  }
  if (pressDuration != null) {
    RangeError.checkValueInInterval(pressDuration, 0, 0xFFFF, 'pressDuration');
  }
  for (final item in items) {
    RangeError.checkValueInInterval(
      item.speed,
      minimumInterval,
      0xFFFF,
      'interval',
    );
    if (pressDuration == null) {
      RangeError.checkValueInInterval(
        item.pressDuration,
        0,
        0xFFFF,
        'pressDuration',
      );
    }
  }
}
