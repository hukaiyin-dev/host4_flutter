import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:host4_flutter_log/host4_flutter_log.dart';
import 'package:host4_flutter_transport/host4_flutter_transport.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';
import 'package:host4_flutter_usb/host4_flutter_usb.dart';

import '../../widgets/sub_page_scaffold.dart';
import 'gmacro_session_page.dart';

/// USB connect page: relies on SDK [ReliableUsbCommManager] for permission,
/// attach/detach broadcasts, and auto reconnect after replug.
class GmacroUsbScanPage extends StatefulWidget {
  const GmacroUsbScanPage({super.key});

  @override
  State<GmacroUsbScanPage> createState() => _GmacroUsbScanPageState();
}

class _GmacroUsbScanPageState extends State<GmacroUsbScanPage> {
  final _log = Host4Logger('GMacroUsb');
  final _usb = Host4Usb();

  StreamSubscription<TransportEvent>? _transportSub;
  TransportSession? _session;

  bool _isConnected = false;
  String _status = '正在初始化 USB…';

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && Platform.isAndroid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_startUsbSession());
      });
    }
  }

  @override
  void dispose() {
    _transportSub?.cancel();
    unawaited(_usb.release());
    super.dispose();
  }

  Future<void> _startUsbSession() async {
    _log.info('Starting USB session (SDK init + connect)...');
    setState(() {
      _isConnected = false;
      _status = '正在连接 USB 设备…\n若弹出权限对话框，请选择「允许」';
    });

    await _transportSub?.cancel();
    _transportSub = null;
    _session = null;

    try {
      final session = await _usb.connectAuto();
      _session = session;

      // Listen before the next frame: native init() is posted after sessionId returns.
      _transportSub = session.events.listen(
        _onTransportEvent,
        onError: (Object err, StackTrace stack) {
          _log.error('Transport stream error', error: err, stackTrace: stack);
          if (!mounted) return;
          setState(() {
            _isConnected = false;
            _status = '连接异常: $err';
          });
        },
      );
    } catch (e, s) {
      _log.error('connectUsb failed', error: e, stackTrace: s);
      if (!mounted) return;
      setState(() => _status = '连接失败: $e');
    }
  }

  void _onTransportEvent(TransportEvent event) {
    if (!mounted) return;

    switch (event) {
      case TransportConnecting():
        setState(() {
          _isConnected = false;
          _status = '正在建立 USB 连接…';
        });
      case TransportConnected():
        setState(() => _status = 'USB 已连接，等待就绪…');
      case TransportReady():
        _log.info('USB transport ready');
        setState(() {
          _isConnected = true;
          _status = '已连接，可进入 GMacro 测试';
        });
      case TransportDisconnected(cause: final cause):
        _log.warn('USB disconnected', error: cause?.message);
        setState(() {
          _isConnected = false;
          _status = cause?.message ?? '设备已拔出，请重新插入';
        });
      case TransportError(failure: final failure):
        _log.error('USB transport error', error: failure.message);
        setState(() {
          _isConnected = false;
          _status = failure.message;
        });
    }
  }

  Future<void> _reconnect() async {
    setState(() {
      _isConnected = false;
      _status = '正在重新连接…';
    });
    try {
      await _usb.reconnect();
    } catch (e, s) {
      _log.error('reconnectUsb failed', error: e, stackTrace: s);
      if (!mounted) return;
      setState(() => _status = '重连失败: $e');
    }
  }

  Future<void> _openSessionPage() async {
    final session = _session;
    if (session == null || !_isConnected) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GmacroSessionPage(
          transport: session,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && !Platform.isAndroid) {
      return const SubPageScaffold(
        title: 'USB 连接',
        subtitle: '当前仅支持 Android USB Host 模式',
        child: Center(child: Text('请在 Android 设备上使用 USB 调试')),
      );
    }

    final theme = context.host4Theme;
    final isBusy = !_isConnected && _status.contains('正在');

    return SubPageScaffold(
      title: 'USB 连接',
      subtitle: '插入后自动连接，拔出后可重新插入',
      child: Padding(
        padding: EdgeInsets.all(theme.spacing.page),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isConnected
                          ? Icons.check_circle_rounded
                          : Icons.usb_rounded,
                      size: 56,
                      color: _isConnected
                          ? theme.colors.success
                          : theme.colors.brandSecondary,
                    ),
                    SizedBox(height: theme.spacing.lg),
                    if (isBusy)
                      Padding(
                        padding: EdgeInsets.only(bottom: theme.spacing.md),
                        child: const CircularProgressIndicator(),
                      ),
                    Host4Text(
                      _status,
                      colorRole: Host4TextColorRole.secondary,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isConnected ? _openSessionPage : null,
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('进入 GMacro 测试'),
              ),
            ),
            SizedBox(height: theme.spacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isBusy ? null : () => unawaited(_reconnect()),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('手动重连'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
