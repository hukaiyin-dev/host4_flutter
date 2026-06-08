import 'dart:async';

import 'package:flutter/services.dart';

/// Flutter 端 AI Voice API
/// 调用 showAI 后，所有 UI 和逻辑由 Native 端处理
class Host4FlutterAiVoice {
  static final _channel = MethodChannel('host4_flutter_aivoice');
  static final _eventChannel = EventChannel('host4_flutter_aivoice_events');
  static Stream<Map<String, dynamic>>? _eventStream;

  /// 显示 AI 语音悬浮窗（自动处理引擎初始化、房间加入、智能体拉取、UI 显示）
  static Future<bool> showAI({required String boostingTableID}) async {
    final result = await _channel.invokeMethod('showAI', {
      'boostingTableID': boostingTableID,
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
