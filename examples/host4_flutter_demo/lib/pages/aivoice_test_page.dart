import 'dart:async';

import 'package:flutter/material.dart';
import 'package:host4_flutter_aivoice/host4_flutter_aivoice.dart';

class AiVoiceTestPage extends StatefulWidget {
  const AiVoiceTestPage({super.key});

  @override
  State<AiVoiceTestPage> createState() => _AiVoiceTestPageState();
}

class _AiVoiceTestPageState extends State<AiVoiceTestPage> {
  bool _isAIOn = false;
  String _status = '未启动';
  final List<String> _events = [];
  StreamSubscription<Map<String, dynamic>>? _eventSub;

  @override
  void initState() {
    super.initState();
    _addLog('AI 语音悬浮窗测试（全部原生）');
  }

  void _addLog(String msg) {
    setState(() => _events.insert(0, '[${DateTime.now().millisecond}] $msg'));
  }

  Future<void> _toggleAI() async {
    if (_isAIOn) {
      // 关闭
      await Host4FlutterAiVoice.hideAI();
      _eventSub?.cancel();
      _eventSub = null;
      setState(() {
        _isAIOn = false;
        _status = '已关闭';
      });
      _addLog('✅ hideAI 已调用');
    } else {
      // 开启
      setState(() => _status = '正在启动 AI 语音...');
      _addLog('调用 showAI...');

      try {
        final success = await Host4FlutterAiVoice.showAI(
          boostingTableID: 'GameMacro',
        );
        if (success) {
          _subscribeEvents();
          setState(() {
            _isAIOn = true;
            _status = '✅ 悬浮窗已显示';
          });
          _addLog('✅ showAI 成功');
        } else {
          setState(() => _status = '❌ 启动失败');
          _addLog('❌ showAI 返回 false');
        }
      } catch (e) {
        setState(() => _status = '❌ 异常: $e');
        _addLog('❌ 异常: $e');
      }
    }
  }

  void _subscribeEvents() {
    _eventSub = Host4FlutterAiVoice.events.listen((event) {
      final type = event['event'] ?? 'unknown';
      _addLog('📡 $type');

      switch (type) {
        case 'agentJoined':
          setState(() => _status = '🎉 智能体已加入');
          break;
        case 'agentJoinFailed':
          setState(() => _status = '❌ 智能体加入失败');
          break;
      }
    });
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    Host4FlutterAiVoice.hideAI();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI 语音测试（原生 UI）')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: Column(
              children: [
                Text('状态: $_status',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _toggleAI,
                  icon: Icon(_isAIOn ? Icons.stop : Icons.play_arrow),
                  label: Text(_isAIOn ? '关闭 AI' : '开启 AI 悬浮窗'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAIOn ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
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
                      child: Text(_events[i],
                          style: const TextStyle(
                              fontSize: 12, fontFamily: 'monospace')),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
