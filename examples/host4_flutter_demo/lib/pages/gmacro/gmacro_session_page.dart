import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:host4_flutter_gmacro/host4_flutter_gmacro.dart';
import 'package:host4_flutter_protocol/host4_flutter_protocol.dart';
import 'package:host4_flutter_transport/host4_flutter_transport.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';

import '../../widgets/sub_page_scaffold.dart';

class GmacroSessionPage extends StatefulWidget {
  const GmacroSessionPage({required this.transport, super.key});

  final TransportSession transport;

  @override
  State<GmacroSessionPage> createState() => _GmacroSessionPageState();
}

class _GmacroSessionPageState extends State<GmacroSessionPage> {
  final _gmacro = Host4Gmacro();

  GmacroSession? _session;
  bool _isAttaching = true;
  bool _isBusy = false;

  final _logs = <_LogEntry>[];
  StreamSubscription<TransportEvent>? _transportSub;
  StreamSubscription<ProtocolEvent>? _protocolSub;

  @override
  void initState() {
    super.initState();
    _subscribeTransport();
    _attach();
  }

  @override
  void dispose() {
    _transportSub?.cancel();
    _protocolSub?.cancel();
    _session?.close();
    widget.transport.disconnect();
    super.dispose();
  }

  void _subscribeTransport() {
    _transportSub = widget.transport.events.listen((event) {
      if (!mounted) return;
      final label = switch (event) {
        TransportConnecting() => '📡 Transport: Connecting',
        TransportConnected() => '📡 Transport: Connected',
        TransportReady() => '📡 Transport: Ready',
        TransportDisconnected(cause: final c) =>
          '📡 Transport: Disconnected${c != null ? ' (${c.code})' : ''}',
        TransportError(failure: final f) =>
          '📡 Transport: Error ${f.code} - ${f.message}',
      };
      _addLog(label, isError: event is TransportError);
    });
  }

  Future<void> _attach() async {
    _addLog('⏳ attaching GMacro protocol…');
    try {
      final session = await _gmacro.attach(widget.transport);
      if (!mounted) return;
      setState(() {
        _session = session;
        _isAttaching = false;
      });
      _addLog('✅ GMacro protocol attached (id: ${session.id})');
      _subscribeProtocol(session);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAttaching = false);
      _addLog('❌ attach failed: $e', isError: true);
    }
  }

  void _subscribeProtocol(GmacroSession session) {
    _protocolSub = session.events.listen((event) {
      if (!mounted) return;
      switch (event) {
        case ProtocolReady():
          _addLog('🟢 Protocol: Ready');
          if (mounted) setState(() => _isBusy = false);
        case ProtocolBusy(reason: final r):
          _addLog('🟡 Protocol: Busy — $r');
          if (mounted) setState(() => _isBusy = true);
        case ProtocolError(failure: final f):
          _addLog('🔴 Protocol: Error ${f.code} - ${f.message}', isError: true);
          if (mounted) setState(() => _isBusy = false);
      }
    });
  }

  Future<void> _fetchDeviceVersion() async {
    final session = _session;
    if (session == null) return;
    _addLog('▶ invoke: fetchDeviceVersion');
    try {
      final result = await session.invoke('fetchDeviceVersion');
      _addLog('◀ result: $result');
    } catch (e) {
      _addLog('◀ error: $e', isError: true);
    }
  }

  Future<void> _startOta() async {
    final session = _session;
    if (session == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('OTA 测试'),
        content: const Text(
          '点击确认后选择本地 .bin 固件文件，\n'
          'Flutter 会将固件字节传给原生层执行 OTA。\n\n'
          'OTA 进度通过 ProtocolBusy 事件上报，\n'
          '完成后收到 ProtocolReady。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('选择固件'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 让用户选 .bin 固件文件
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['bin'],
      withData: true,
    );
    if (!mounted) return;
    final bytes = picked?.files.firstOrNull?.bytes;
    if (bytes == null) {
      _addLog('⚠ 未选择固件文件，已取消');
      return;
    }

    _addLog('▶ invoke: startOta（固件 ${bytes.length} bytes）');
    try {
      final result = await session.invoke(
        'startOta',
        arguments: {'data': bytes},
      );
      _addLog('◀ result: $result');
    } catch (e) {
      _addLog('◀ error: $e', isError: true);
    }
  }

  void _addLog(String message, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _logs.insert(0, _LogEntry(message: message, isError: isError));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    final device = widget.transport.device;

    return SubPageScaffold(
      title: device.name.isEmpty ? '设备会话' : device.name,
      subtitle: '${device.kind.name.toUpperCase()} · ${device.id}',
      child: Column(
        children: [
          // 状态栏
          _StatusBar(
            isAttaching: _isAttaching,
            isBusy: _isBusy,
            session: _session,
          ),

          // 操作按钮
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: theme.spacing.page,
              vertical: theme.spacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        (_session == null || _isBusy) ? null : _fetchDeviceVersion,
                    icon: const Icon(Icons.info_outline_rounded, size: 16),
                    label: const Text('Fetch Version'),
                  ),
                ),
                SizedBox(width: theme.spacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (_session == null || _isBusy) ? null : _startOta,
                    icon: const Icon(Icons.system_update_alt_rounded, size: 16),
                    label: const Text('OTA 测试'),
                  ),
                ),
              ],
            ),
          ),

          // 日志区域
          Padding(
            padding: EdgeInsets.fromLTRB(
              theme.spacing.page,
              0,
              theme.spacing.page,
              theme.spacing.sm,
            ),
            child: Row(
              children: [
                Host4Text('事件日志', role: Host4TextRole.heading),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _logs.clear()),
                  child: Host4Text(
                    '清空',
                    colorRole: Host4TextColorRole.secondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _logs.isEmpty
                ? Center(
                    child: Host4Text(
                      _isAttaching ? '正在挂载协议…' : '暂无事件',
                      colorRole: Host4TextColorRole.secondary,
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: theme.spacing.page,
                    ),
                    itemCount: _logs.length,
                    itemBuilder: (_, i) => _LogTile(entry: _logs[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.isAttaching,
    required this.isBusy,
    required this.session,
  });

  final bool isAttaching;
  final bool isBusy;
  final GmacroSession? session;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    Color dotColor;
    String label;
    if (isAttaching) {
      dotColor = theme.colors.warning;
      label = '挂载协议中…';
    } else if (session == null) {
      dotColor = theme.colors.warning;
      label = '协议挂载失败';
    } else if (isBusy) {
      dotColor = theme.colors.warning;
      label = 'Protocol Busy（OTA / 独占操作进行中）';
    } else {
      dotColor = theme.colors.success;
      label = 'Protocol Ready';
    }

    return Container(
      width: double.infinity,
      color: theme.colors.surfaceMuted,
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.page,
        vertical: theme.spacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: theme.spacing.sm),
          Host4Text(label),
          if (session != null) ...[
            const Spacer(),
            Host4Text(
              'session: ${session!.id.substring(0, 8)}…',
              colorRole: Host4TextColorRole.secondary,
            ),
          ],
        ],
      ),
    );
  }
}

class _LogEntry {
  const _LogEntry({required this.message, required this.isError});

  final String message;
  final bool isError;
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.entry});

  final _LogEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: theme.spacing.xs),
      child: Text(
        entry.message,
        style: theme.typography.caption.toTextStyle(
          entry.isError ? theme.colors.warning : theme.colors.textPrimary,
        ),
      ),
    );
  }
}
