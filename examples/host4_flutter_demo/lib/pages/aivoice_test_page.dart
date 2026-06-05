import 'dart:async';

import 'package:flutter/material.dart';
import 'package:host4_flutter_aivoice/host4_flutter_aivoice.dart';

class AiVoiceTestPage extends StatefulWidget {
  const AiVoiceTestPage({super.key});

  @override
  State<AiVoiceTestPage> createState() => _AiVoiceTestPageState();
}

class _AiVoiceTestPageState extends State<AiVoiceTestPage> {
  bool _isInitialized = false;
  bool _isTalking = false;
  String _roomId = '';
  String _taskId = '';
  String _status = '未初始化';
  final List<String> _events = [];
  StreamSubscription<Map<String, dynamic>>? _eventSub;

  @override
  void initState() {
    super.initState();
    _addLog('页面已加载');
  }

  void _addLog(String msg) {
    setState(() => _events.insert(0, '[${DateTime.now().millisecond}] $msg'));
  }

  Future<void> _initialize() async {
    setState(() => _status = '正在初始化引擎+加入房间...');
    _addLog('开始初始化...');
    try {
      final roomId = 'room_${DateTime.now().millisecondsSinceEpoch}';
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      _roomId = roomId;
      _addLog('roomId=$roomId, userId=$userId');

      final success = await Host4FlutterAiVoice.buildEngine(
        roomId: roomId,
        userId: userId,
      );

      if (success) {
        _subscribeEvents();
        setState(() {
          _isInitialized = true;
          _status = '已初始化（等待房间加入+智能体）';
        });
        _addLog('✅ buildEngine 成功');
      } else {
        setState(() => _status = '❌ buildEngine 失败');
        _addLog('❌ buildEngine 返回 false');
      }
    } catch (e) {
      setState(() => _status = '❌ 异常: $e');
      _addLog('❌ 异常: $e');
    }
  }

  void _subscribeEvents() {
    _eventSub = Host4FlutterAiVoice.events.listen((event) {
      final type = event['event'] ?? 'unknown';
      _addLog('📡 事件: $type → ${event.toString().substring(0, event.toString().length.clamp(0, 150))}');

      if (type == 'roomState') {
        final state = event['state'];
        if (state == 'joined') {
          setState(() => _status = '✅ 已加入房间');
          _addLog('🎉 房间加入成功!');
        } else if (state == 'failed') {
          setState(() => _status = '❌ 房间加入失败 code=${event["code"]}');
          _addLog('❌ 房间加入失败');
        }
      } else if (type == 'agentJoin') {
        _taskId = event['taskId'] ?? '';
        setState(() => _status = '✅ 已加入房间，等待智能体...');
        _addLog('🤖 智能体事件: taskId=${event["taskId"]}');
      } else if (type == 'connectionState') {
        _addLog('🔌 连接状态: ${event["state"]}');
      } else if (type == 'subtitle') {
        _addLog('📝 字幕: ${event["text"]}');
      } else if (type == 'conversationState') {
        _addLog('💬 对话状态: code=${event["code"]}');
      } else if (type == 'chatState') {
        _addLog('💭 聊天状态: ${event["state"]}');
      }
    });
  }

  Future<void> _startTalk() async {
    await Host4FlutterAiVoice.startTalk();
    setState(() {
      _isTalking = true;
      _status = '🎤 说话中...';
    });
    _addLog('开始说话');
  }

  Future<void> _stopTalk() async {
    await Host4FlutterAiVoice.stopTalk();
    setState(() {
      _isTalking = false;
      _status = '🙊 已停止说话';
    });
    _addLog('停止说话');
  }

  Future<void> _destroy() async {
    await Host4FlutterAiVoice.destroy();
    _eventSub?.cancel();
    setState(() {
      _isInitialized = false;
      _isTalking = false;
      _status = '已销毁';
    });
    _addLog('已销毁');
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    Host4FlutterAiVoice.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Voice 测试')),
      body: Column(
        children: [
          // 状态 + 操作按钮
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('状态: $_status',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Room: $_roomId'),
                Text('Task: $_taskId'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (!_isInitialized)
                      ElevatedButton(onPressed: _initialize, child: const Text('1. 初始化')),
                    if (_isInitialized && !_isTalking)
                      ElevatedButton(onPressed: _startTalk, child: const Text('2. 开始说话')),
                    if (_isTalking)
                      ElevatedButton(onPressed: _stopTalk, child: const Text('停止说话')),
                    if (_isInitialized)
                      ElevatedButton(
                        onPressed: _destroy,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('3. 销毁'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // 事件日志
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('事件日志',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _events.clear()),
                  child: const Text('清空'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _events.isEmpty
                ? const Center(child: Text('暂无事件'))
                : ListView.builder(
                    itemCount: _events.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 2),
                      child: Text(
                        _events[i],
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
