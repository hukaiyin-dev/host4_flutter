// ignore_for_file: file_names

import 'Models/gmacro_methods.dart';
import 'gmacro_session.dart';

extension GmacroSessionTouchMapping on GmacroSession {
  /// 设置触点映射屏幕尺寸。
  Future<Map<String, Object?>> setScreenSize({
    required int orientation,
    required int width,
    required int height,
  }) => invoke(
    GmacroMethods.setScreenSize,
    arguments: {'orientation': orientation, 'width': width, 'height': height},
  );

  /// 设置触点映射。
  Future<Map<String, Object?>> setKeyMapping({
    required int type,
    required int keyCode,
    required int x,
    required int y,
    required int range,
    required int sensitivity,
    required int x1,
    required int y1,
    required int attribute,
    required int page,
  }) => invoke(
    GmacroMethods.setKeyMapping,
    arguments: {
      'type': type,
      'keyCode': keyCode,
      'x': x,
      'y': y,
      'range': range,
      'sensitivity': sensitivity,
      'x1': x1,
      'y1': y1,
      'attribute': attribute,
      'page': page,
    },
  );

  /// 设置触点宏按键。
  Future<Map<String, Object?>> setMacroKey({
    required int keyCode,
    required int x,
    required int y,
    required int flag,
    required int interval,
    required int during,
    required int attribute,
    required int range,
    required int sensitivity,
    required int opposite,
  }) => invoke(
    GmacroMethods.setMacroKey,
    arguments: {
      'keyCode': keyCode,
      'x': x,
      'y': y,
      'flag': flag,
      'interval': interval,
      'during': during,
      'attribute': attribute,
      'range': range,
      'sensitivity': sensitivity,
      'opposite': opposite,
    },
  );

  /// 设置触点宏按键触发方式。
  ///touchType 0按下触发 1松开触发 2按住循环
  Future<Map<String, Object?>> setMacroKeyTrigger({
    required int keyCode,
    required int touchType,
  }) => invoke(
    GmacroMethods.setMacroKeyTrigger,
    arguments: {'keyCode': keyCode, 'touchType': touchType},
  );

  /// 设置触点宏终止按键。
  Future<Map<String, Object?>> setMacroTerminationKey({
    required int keyCode,
    required int terminateKey,
  }) => invoke(
    GmacroMethods.setMacroTerminationKey,
    arguments: {'keyCode': keyCode, 'terminateKey': terminateKey},
  );

  ///设置触点映射的 turbo 速率
  ///turbo 速率：1-30
  Future<Map<String, Object?>> setKeyTurboSpeed({
    required int keyCode,
    required int turbo,
  }) =>invoke(
    GmacroMethods.setKeyTurboSpeed,
    arguments: {'keyCode':keyCode,'turbo':turbo}
  );

  /// 结束触点映射配置。
  Future<Map<String, Object?>> keyMappingEnd({
    required int page,
    required int packet,
  }) => invoke(
    GmacroMethods.keyMappingEnd,
    arguments: {'page': page, 'packet': packet},
  );
}
