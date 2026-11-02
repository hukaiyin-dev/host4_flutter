import 'dart:async';

import 'package:flutter/material.dart';
import 'package:host4_flutter_gmacro/host4_flutter_gmacro.dart';

import 'gmacro_multi_device_session_manager.dart';
import '../../widgets/sub_page_scaffold.dart';

/// Shows live input frames and button edges for every connected demo device.
class GmacroMultiDeviceInputDebugPage extends StatefulWidget {
  const GmacroMultiDeviceInputDebugPage({required this.manager, super.key});

  final GmacroMultiDeviceSessionManager manager;

  @override
  State<GmacroMultiDeviceInputDebugPage> createState() =>
      _GmacroMultiDeviceInputDebugPageState();
}

class _GmacroMultiDeviceInputDebugPageState
    extends State<GmacroMultiDeviceInputDebugPage> {
  static const _maxLogs = 80;

  final _states = <String, GmacroInputState>{};
  final _logs = <String>[];
  StreamSubscription<GmacroDeviceInputState>? _stateSub;
  StreamSubscription<GmacroDeviceButtonEvent>? _buttonSub;
  StreamSubscription<GmacroDeviceInputError>? _errorSub;

  @override
  void initState() {
    super.initState();
    widget.manager.addListener(_refresh);
    final hub = widget.manager.inputHub;
    _stateSub = hub.states.listen((event) {
      if (!mounted) return;
      setState(() => _states[event.protocolSessionId] = event.state);
    });
    _buttonSub = hub.buttonEvents.listen((event) {
      if (!mounted) return;
      setState(() {
        _addLog('${event.deviceId} · ${event.key.name} ${event.phase.name}');
      });
    });
    _errorSub = hub.errors.listen((event) {
      if (!mounted) return;
      setState(() => _addLog('${event.deviceId} · 错误：${event.error}'));
    });
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _addLog(String message) {
    _logs.insert(0, '${DateTime.now().toIso8601String()}  $message');
    if (_logs.length > _maxLogs) _logs.removeLast();
  }

  @override
  void dispose() {
    widget.manager.removeListener(_refresh);
    _stateSub?.cancel();
    _buttonSub?.cancel();
    _errorSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connections = widget.manager.connections;
    return SubPageScaffold(
      title: '多设备按键调试',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('同时显示各设备的完整输入状态及按键按下/抬起事件。'),
          const SizedBox(height: 8),
          const Text('如需 testModeEvent，请先在选中设备的 API 测试页切换测试模式。'),
          const SizedBox(height: 12),
          if (connections.isEmpty) const Text('尚未添加设备'),
          for (final connection in connections)
            _DeviceInputCard(
              connection: connection,
              state: _states[connection.session?.id],
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('按键事件与错误', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              TextButton(
                onPressed: _logs.isEmpty ? null : () => setState(_logs.clear),
                child: const Text('清空'),
              ),
            ],
          ),
          if (_logs.isEmpty)
            const Text('暂无输入事件')
          else
            for (final log in _logs)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: SelectableText(log),
              ),
        ],
      ),
    );
  }
}

class _DeviceInputCard extends StatelessWidget {
  const _DeviceInputCard({required this.connection, required this.state});

  final GmacroDemoConnection connection;
  final GmacroInputState? state;

  @override
  Widget build(BuildContext context) {
    final device = connection.transport.device;
    final input = state;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${device.name} · ${device.kind.name.toUpperCase()}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SelectableText(device.id),
            Text('连接状态：${connection.status}'),
            if (input == null)
              const Text('尚未收到输入数据')
            else ...[
              Text('数据来源：${input.source.name}'),
              Text(
                '当前按键：${input.pressedKeys.map((key) => key.name).join(', ')}',
              ),
              Text('原始按键：${input.rawKeys}'),
              Text('左摇杆：(${input.j1x}, ${input.j1y})'),
              Text('右摇杆：(${input.j2x}, ${input.j2y})'),
              Text('扳机：L2=${input.l2}  R2=${input.r2}'),
            ],
          ],
        ),
      ),
    );
  }
}
