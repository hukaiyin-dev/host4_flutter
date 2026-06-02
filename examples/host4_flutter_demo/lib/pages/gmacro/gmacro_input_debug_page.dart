import 'dart:async';

import 'package:flutter/material.dart';
import 'package:host4_flutter_gmacro/host4_flutter_gmacro.dart';

import '../../widgets/sub_page_scaffold.dart';

/// 统一输入调试页面。
///
/// 状态卡片通过 [StreamBuilder] 监听 [GmacroInputHub.currentService]，
/// 无需手动 [StreamSubscription] 和 [dispose] 清理。
///
/// 日志区域因为需要累积历史记录，使用极小量的订阅代码，
/// 这种模式仅用于调试场景；生产页面如果只读最新状态，直接用 [StreamBuilder] 即可。
class GmacroInputDebugPage extends StatelessWidget {
  const GmacroInputDebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = GmacroInputHub.currentService;

    return SubPageScaffold(
      title: '统一输入调试',
      subtitle: service == null ? '未绑定 Session' : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 状态卡片：StreamBuilder 自动管理订阅生命周期 ──
          _StateCard(service: service),

          // ── 事件日志 ──
          service == null
              ? const Expanded(child: Center(child: Text('暂无输入事件')))
              : _EventLog(service: service),
        ],
      ),
    );
  }
}

/// 状态卡片：用 [StreamBuilder] 实时展示当前帧输入状态。
///
/// 没有 [StreamSubscription] 字段，没有 [dispose] 取消，全自动。
class _StateCard extends StatelessWidget {
  const _StateCard({required this.service});

  final GmacroInputService? service;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: StreamBuilder<GmacroInputState>(
            stream: service?.states,
            initialData: GmacroInputState.empty(),
            builder: (context, snapshot) {
              final state = snapshot.data!;
              final pressedKeys =
                  state.pressedKeys.map((e) => e.name).toList();

              return DefaultTextStyle(
                style:
                    Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('当前按键: $pressedKeys'),
                    const SizedBox(height: 6),
                    Text('Raw Keys: ${state.rawKeys}'),
                    const SizedBox(height: 6),
                    Text('J1: (${state.j1x}, ${state.j1y})'),
                    const SizedBox(height: 6),
                    Text('J2: (${state.j2x}, ${state.j2y})'),
                    const SizedBox(height: 6),
                    Text('L2: ${state.l2}'),
                    const SizedBox(height: 6),
                    Text('R2: ${state.r2}'),
                    const SizedBox(height: 6),
                    Text(
                      'Left Stick Normalized: '
                      '(${state.leftStickDx.toStringAsFixed(2)}, '
                      '${state.leftStickDy.toStringAsFixed(2)})',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Right Stick Normalized: '
                      '(${state.rightStickDx.toStringAsFixed(2)}, '
                      '${state.rightStickDy.toStringAsFixed(2)})',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 事件日志：累积展示最近的输入事件。
///
/// 日志面板需要保持历史记录，无法用 [StreamBuilder] 纯声明式实现，
/// 因此使用 [StatefulWidget] + 手动监听。
///
/// 对于生产页面只需要确认按键是否按下等判断，直接用 [StreamBuilder] 即可，
/// 不需要手动订阅和 [dispose] 清理。
class _EventLog extends StatefulWidget {
  const _EventLog({required this.service});

  final GmacroInputService service;

  @override
  State<_EventLog> createState() => _EventLogState();
}

class _EventLogState extends State<_EventLog> {
  /// 事件日志列表，最新插入头部，最多 80 条。
  final List<String> _logs = [];

  /// 按钮事件订阅（仅日志需要，因为要累积历史）。
  StreamSubscription<GmacroButtonEvent>? _buttonSub;

  @override
  void initState() {
    super.initState();
    _buttonSub = widget.service.buttonEvents.listen((event) {
      if (!mounted) return;
      setState(() => _insertLog(
        'button: ${event.key.name} ${event.phase.name}',
      ));
    });
  }

  @override
  void dispose() {
    _buttonSub?.cancel();
    super.dispose();
  }

  void _insertLog(String msg) {
    _logs.insert(0, '[${DateTime.now().toIso8601String()}] $msg');
    if (_logs.length > 80) _logs.removeLast();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Text(
              '统一输入事件日志',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _logs.isEmpty
                ? const Center(child: Text('暂无输入事件'))
                : Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (_, i) => Text(
                        _logs[i],
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
