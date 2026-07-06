import 'dart:async';

import 'package:flutter/services.dart';

/// Flutter 端 AI Voice API
/// 调用 showAI 后，所有 UI 和逻辑由 Native 端处理
class Host4FlutterAiVoice {
  static final _channel = MethodChannel('host4_flutter_aivoice');
  static final _eventChannel = EventChannel('host4_flutter_aivoice_events');
  static Stream<Map<String, dynamic>>? _eventStream;

  /// VIP 处理器：宿主项目实现用户鉴权 + 扣费逻辑
  /// [call] = {'type': 'check'|'deduction', ...}
  /// 返回 Map，必含 'allowed': true/false
  static Future<Map<String, dynamic>> Function(Map<String, dynamic> call)?
  _vipHandler;

  static bool _vipInitialized = false;

  /// 设置 VIP 处理器（必须在 showAI 之前调用）
  static void setVipHandler(
    Future<Map<String, dynamic>> Function(Map<String, dynamic> call) handler,
  ) {
    _vipHandler = handler;
    if (!_vipInitialized) {
      _vipInitialized = true;
      _channel.setMethodCallHandler(_handleNativeCall);
    }
    // 通知 Native 端 VIP 已就绪
    _channel.invokeMethod('registerVip');
  }

  /// 处理 Native → Flutter 的方法调用（VIP 检查/扣费）
  static Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method == 'vipAction' && _vipHandler != null) {
      final args = Map<String, dynamic>.from(call.arguments as Map? ?? {});
      return await _vipHandler!(args);
    }
    throw MissingPluginException();
  }

  /// 显示 AI 语音悬浮窗（自动处理引擎初始化、房间加入、智能体拉取、UI 显示）
  /// [boostingTableID] 智能体配置 ID
  /// [language] 语言代码（如 "zh"、"en"、"ja"），不传则使用系统语言
  static Future<bool> showAI({
    required String boostingTableID,
    String? language,
  }) async {
    final result = await _channel.invokeMethod('showAI', {
      'boostingTableID': boostingTableID,
      if (language != null) 'language': language,
    });
    return result == true;
  }

  /// 隐藏并销毁 AI 语音（销毁引擎、房间、隐藏悬浮窗/聊天窗）
  static Future<bool> hideAI() async {
    final result = await _channel.invokeMethod('hideAI');
    return result == true;
  }

  /// 监听事件流
  static Stream<Map<String, dynamic>> get events {
    _eventStream ??= _eventChannel.receiveBroadcastStream().map((
      dynamic event,
    ) {
      if (event is Map) {
        return event.map<String, dynamic>(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
      return <String, dynamic>{};
    });
    return _eventStream!;
  }
}
