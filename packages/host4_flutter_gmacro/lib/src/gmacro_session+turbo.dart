import 'Models/gmacro_methods.dart';
import 'Models/gmacro_turbo_models.dart';
import 'gmacro_session.dart';

extension GmacroSessionTurbo on GmacroSession {
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
