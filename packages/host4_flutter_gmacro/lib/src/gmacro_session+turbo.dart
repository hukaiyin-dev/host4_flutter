import 'Models/gmacro_methods.dart';
import 'Models/gmacro_turbo_models.dart';
import 'gmacro_session.dart';

extension GmacroSessionTurbo on GmacroSession {
  /// 0x37 0x80：设置 16 位连发速率。旧 0x37 接口保持不变。
  Future<Map<String, Object?>> setTurboDatas16({
    required List<KeyTurboPayload> keyTurbos,
  }) {
    for (final item in keyTurbos) {
      if (item.speed < 0 || item.speed > 0xFFFF) {
        throw RangeError.range(item.speed, 0, 0xFFFF, 'speed');
      }
    }
    return invoke(
      GmacroMethods.setTurboDatas16,
      arguments: {'keyTurbos': keyTurbos.map((e) => e.toMap()).toList()},
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
