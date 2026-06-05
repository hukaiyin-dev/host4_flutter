import 'dart:async';

import 'package:flutter/services.dart';

/// Flutter 端 AI Voice API
class Host4FlutterAiVoice {
  static final _channel = MethodChannel('host4_flutter_aivoice');
  static final _eventChannel = EventChannel('host4_flutter_aivoice_events');
  static Stream<Map<String, dynamic>>? _eventStream;

  /// 初始化 RTC 引擎并加入房间
  static Future<bool> buildEngine({
    required String roomId,
    required String userId,
  }) async {
    final result = await _channel.invokeMethod('buildEngine', {
      'roomId': roomId,
      'userId': userId,
    });
    return result == true;
  }

  /// 重新加入房间（网络重连）
  static Future<bool> rejoinRoom() async {
    final result = await _channel.invokeMethod('rejoinRoom');
    return result == true;
  }

  /// 加入 RTC 房间
  static Future<bool> joinRoom() async {
    final result = await _channel.invokeMethod('joinRoom');
    return result == true;
  }

  /// 开始说话（发布音频）
  static Future<bool> startTalk() async {
    final result = await _channel.invokeMethod('startTalk');
    return result == true;
  }

  /// 停止说话（取消发布音频）
  static Future<bool> stopTalk() async {
    final result = await _channel.invokeMethod('stopTalk');
    return result == true;
  }

  /// 设置播放音量
  static Future<void> setVolume(int level) async {
    await _channel.invokeMethod('setVolume', {'level': level});
  }

  /// 离开并销毁
  static Future<void> destroy() async {
    await _channel.invokeMethod('destroy');
  }

  /// 监听事件流（字幕、状态、音量等）
  static Stream<Map<String, dynamic>> get events {
    _eventStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((dynamic event) {
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
