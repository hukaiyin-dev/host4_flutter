import 'Models/gmacro_methods.dart';
import 'gmacro_session.dart';

extension GmacroSessionSleep on GmacroSession {
  /// 查询睡眠时间
  Future<Map<String, Object?>> getSleepTime({required int profile}) =>
      invoke(GmacroMethods.getSleepTime, arguments: {'profile': profile});

  /// 设置睡眠时间
  Future<Map<String, Object?>> setSleepTime({required int time}) =>
      invoke(GmacroMethods.setSleepTime, arguments: {'time': time});
}
