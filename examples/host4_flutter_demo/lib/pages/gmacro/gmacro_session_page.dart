import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:host4_flutter_device_native/host4_flutter_device_native.dart';
import 'package:host4_flutter_gmacro/host4_flutter_gmacro.dart';
import 'package:host4_flutter_protocol/host4_flutter_protocol.dart';
import 'package:host4_flutter_transport/host4_flutter_transport.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';

import '../../widgets/sub_page_scaffold.dart';
import 'gmacro_api_test_page.dart';

enum _OtaFirmwareSource { bundled, picker }

class GmacroBundledOtaFirmware {
  const GmacroBundledOtaFirmware({
    required this.assetPath,
    required this.fileName,
  });

  final String assetPath;
  final String fileName;
}

const _mfiBundledOtaFirmware = GmacroBundledOtaFirmware(
  assetPath: 'assets/ota/OTA_GDF-G910202_8520_V1.0_260715a.bin',
  fileName: 'OTA_GDF-G910202_8520_V1.0_260715a.bin',
);

const _bleBundledOtaFirmware = GmacroBundledOtaFirmware(
  assetPath: 'assets/ota/OTA_GDF-G560637_46D4_V1.0_260510a.bin',
  fileName: 'OTA_GDF-G560637_46D4_V1.0_260510a.bin',
);

GmacroBundledOtaFirmware gmacroBundledOtaFirmwareForTransportKind(
  TransportKind kind,
) {
  return switch (kind) {
    TransportKind.mfi => _mfiBundledOtaFirmware,
    TransportKind.ble || TransportKind.usb => _bleBundledOtaFirmware,
  };
}

class GmacroSessionPage extends StatefulWidget {
  const GmacroSessionPage({required this.transport, super.key});

  final TransportSession transport;

  @override
  State<GmacroSessionPage> createState() => _GmacroSessionPageState();
}

class _GmacroSessionPageState extends State<GmacroSessionPage> {
  final _gmacro = Host4Gmacro();
  final GmacroInputHub _inputHub = GmacroInputHub();

  GmacroSession? _session;
  // bool _isAttaching = true;
  bool _isAttaching = false;
  bool _isBusy = false;

  bool get _isSystemConnectedTransport =>
      widget.transport.device.id == 'system-connected';

  static const _nativeLogChannel = EventChannel(
    'host4_flutter_device_native/native_log',
  );

  final _logs = <_LogEntry>[];
  StreamSubscription<TransportEvent>? _transportSub;
  StreamSubscription<ProtocolEvent>? _protocolSub;
  StreamSubscription<NativeOtaUpgradeEvent>? _otaSub;
  StreamSubscription<dynamic>? _nativeLogSub;
  bool _isOtaRunning = false;
  bool _isOtaCompleted = false;
  double _otaPercent = 0;

  @override
  void initState() {
    super.initState();
    _subscribeTransport();
    _subscribeNativeLog();

    // if (_isSystemConnectedTransport) {
    //   Future<void>.delayed(const Duration(milliseconds: 800), () {
    //     if (!mounted) return;
    //     _attach();
    //   });
    // } else {
    //   _attach();
    // }
    if (_isSystemConnectedTransport) {
      _addLog('⏳ System-connected: 等待 TransportReady 后自动挂载协议…');
    } else {
      _attach();
    }
  }

  @override
  void dispose() {
    _transportSub?.cancel();
    _protocolSub?.cancel();
    _otaSub?.cancel();
    _nativeLogSub?.cancel();
    unawaited(_inputHub.dispose());
    _session?.close();
    widget.transport.disconnect();
    super.dispose();
  }

  void _subscribeNativeLog() {
    _nativeLogSub = _nativeLogChannel.receiveBroadcastStream().listen((
      message,
    ) {
      if (!mounted) return;
      _addLog('[Native] $message');
    });
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

      if (_isSystemConnectedTransport && event is TransportReady) {
        _attach();
      }
    });
  }

  // Future<void> _attach() async {
  //   _addLog('⏳ attaching GMacro protocol…');
  //   try {
  //     final session = await _gmacro.attach(widget.transport);
  //     if (!mounted) return;
  //     setState(() {
  //       _session = session;
  //       _isAttaching = false;
  //     });
  //     _addLog('✅ GMacro protocol attached (id: ${session.id})');
  //     _subscribeProtocol(session);
  //   } catch (e) {
  //     if (!mounted) return;
  //     setState(() => _isAttaching = false);
  //     _addLog('❌ attach failed: $e', isError: true);
  //   }
  // }
  Future<void> _attach() async {
    if (_isAttaching || _session != null) return;

    if (mounted) {
      setState(() => _isAttaching = true);
    }

    _addLog('⏳ attaching GMacro protocol…');
    try {
      final session = await _gmacro.attach(widget.transport);

      if (!mounted) return;

      setState(() {
        _session = session;
        _isAttaching = false;
      });

      _addLog('✅ GMacro protocol attached (id: ${session.id})');

      _inputHub.bindSession(session);

      _subscribeProtocol(session);
      _subscribeOta(session);
    } catch (e) {
      if (!mounted) return;

      setState(() => _isAttaching = false);
      _addLog('❌ attach failed: $e', isError: true);
    }
  }

  // void _subscribeProtocol(GmacroSession session) {
  //   _protocolSub = session.events.listen((event) {
  //     if (!mounted) return;

  //     switch (event) {
  //       case ProtocolReady():
  //         _addLog('🟢 Protocol: Ready');
  //         if (mounted) {
  //           setState(() => _isBusy = false);
  //         }

  //       case ProtocolBusy(reason: final reason, payload: final payload):
  //         _addLog('🟡 Protocol: Busy — $reason');

  //         final eventName = payload['event'];
  //         if (eventName == 'testKeys') {
  //           _addLog('🎮 testKeys payload: $payload');
  //         } else if (eventName == 'devKeysState') {
  //           _addLog('🎮 devKeysState payload: $payload');
  //         } else if (eventName == 'configKeys') {
  //           _addLog('⌨️ configKeys payload: $payload');
  //         } else if (eventName == 'recordKeys') {
  //           _addLog('🎬 recordKeys payload: $payload');
  //         } else if (eventName == 'endRecord') {
  //           _addLog('🛑 endRecord payload: $payload');
  //         } else if (eventName == 'calibrationFinished') {
  //           _addLog('📏 calibrationFinished payload: $payload');
  //         } else if (eventName == 'deviceConnected') {
  //           _addLog('🔌 deviceConnected payload: $payload');
  //         }

  //         if (mounted) {
  //           setState(() => _isBusy = true);
  //         }

  //       case ProtocolError(failure: final failure):
  //         _addLog(
  //           '🔴 Protocol: Error ${failure.code} - ${failure.message}',
  //           isError: true,
  //         );
  //         if (mounted) {
  //           setState(() => _isBusy = false);
  //         }
  //     }
  //   });
  // }

  void _subscribeProtocol(GmacroSession session) {
    _protocolSub = session.events.listen((event) {
      if (!mounted) return;
      switch (event) {
        case ProtocolReady():
          _addLog('🟢 Protocol: Ready');
          if (mounted) setState(() => _isBusy = false);
        case ProtocolBusy(reason: final r):
          _handleProtocolOtaEvent(event);
          _addLog('🟡 Protocol: Busy — $r');
          if (mounted && r != 'success' && r != 'failed') {
            setState(() => _isBusy = true);
          }
        case ProtocolError(failure: final f):
          _addLog('🔴 Protocol: Error ${f.code} - ${f.message}', isError: true);
          if (mounted) {
            setState(() {
              _isBusy = false;
              if (_isOtaRunning) {
                _isOtaRunning = false;
              }
            });
          }
      }
    });
  }

  void _handleProtocolOtaEvent(ProtocolBusy event) {
    final payload = event.payload;

    switch (payload['event']) {
      case 'progress':
        final progress = payload['progress'];
        final percent = progress is num ? progress.toDouble() : 0.0;
        setState(() {
          _isOtaRunning = true;
          _isOtaCompleted = false;
          _otaPercent = percent.clamp(0.0, 1.0).toDouble();
        });
      case 'success':
        _markOtaSuccess();
      case 'failed':
        setState(() {
          _isBusy = false;
          _isOtaRunning = false;
          _isOtaCompleted = false;
        });
    }
  }

  void _markOtaSuccess() {
    final shouldLog = !_isOtaCompleted;
    setState(() {
      _isBusy = false;
      _isOtaRunning = false;
      _isOtaCompleted = true;
      _otaPercent = 1;
    });
    if (shouldLog) {
      _addLog('🟢 OTA 升级成功');
    }
  }

  void _subscribeOta(GmacroSession session) {
    _otaSub?.cancel();
    _otaSub = session.otaUpgradeEvents.listen((event) {
      if (!mounted) return;
      switch (event.type) {
        case NativeOtaUpgradeEventType.progress:
          setState(() {
            _isOtaRunning = true;
            _isOtaCompleted = false;
            _otaPercent = event.percent;
          });
          _addLog(
            '🟠 OTA 进度: ${(event.percent * 100).toStringAsFixed(1)}% '
            '(${event.progress}/${event.total})',
          );
        case NativeOtaUpgradeEventType.success:
          _markOtaSuccess();
        case NativeOtaUpgradeEventType.failed:
          setState(() {
            _isBusy = false;
            _isOtaRunning = false;
            _isOtaCompleted = false;
          });
          _addLog('🔴 OTA 升级失败，code=${event.code ?? -1}', isError: true);
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

    final source = await showDialog<_OtaFirmwareSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('OTA 测试'),
        content: const Text(
          '可以直接使用项目内置测试固件，或选择本地 .bin 固件文件。\n'
          'Flutter 会将固件字节传给原生层执行 OTA。\n\n'
          '升级进度/成功/失败将通过 otaUpgradeEvents 监听。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _OtaFirmwareSource.bundled),
            child: const Text('已有文件'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _OtaFirmwareSource.picker),
            child: const Text('选择固件'),
          ),
        ],
      ),
    );

    if (source == null) return;

    late final Uint8List bytes;
    late final String firmwareName;
    switch (source) {
      case _OtaFirmwareSource.bundled:
        final firmware = gmacroBundledOtaFirmwareForTransportKind(
          widget.transport.device.kind,
        );
        final data = await rootBundle.load(firmware.assetPath);
        if (!mounted) return;
        bytes = data.buffer.asUint8List();
        firmwareName = firmware.fileName;
      case _OtaFirmwareSource.picker:
        final picked = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['bin', 'signed'],
          withData: true,
        );
        if (!mounted) return;
        final file = picked?.files.firstOrNull;
        final pickedBytes = file?.bytes;
        if (pickedBytes == null) {
          _addLog('⚠ 未选择固件文件，已取消');
          return;
        }
        bytes = pickedBytes;
        firmwareName = file?.name ?? 'selected firmware';
    }

    if (bytes.isEmpty) {
      _addLog('⚠ 固件文件为空，已取消', isError: true);
      return;
    }

    _addLog('▶ invoke: startOta（$firmwareName，${bytes.length} bytes）');
    setState(() {
      _isOtaRunning = true;
      _isOtaCompleted = false;
      _otaPercent = 0;
    });
    try {
      await session.startOta(bytes);
      _addLog('◀ startOta 已发起，等待 OTA 回调事件…');
    } catch (e) {
      setState(() {
        _isOtaRunning = false;
      });
      _addLog('◀ error: $e', isError: true);
    }
  }

  void _openApiTestPage() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GmacroApiTestPage(session: _session)),
    );
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
      subtitle: '★v2 ${device.kind.name.toUpperCase()} · ${device.id}',
      // subtitle: '${device.kind.name.toUpperCase()} · ${device.id}',
      child: Column(
        children: [
          // 状态栏
          _StatusBar(
            isAttaching: _isAttaching,
            isBusy: _isBusy,
            isOtaRunning: _isOtaRunning,
            isOtaCompleted: _isOtaCompleted,
            otaPercent: _otaPercent,
            session: _session,
          ),

          // 操作按钮
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: theme.spacing.page,
              vertical: theme.spacing.md,
            ),

            //   child: Row(
            //     children: [
            //       Expanded(
            //         child: OutlinedButton.icon(
            //           onPressed: (_session == null || _isBusy)
            //               ? null
            //               : _fetchDeviceVersion,
            //           icon: const Icon(Icons.info_outline_rounded, size: 16),
            //           label: const Text('Fetch Version'),
            //         ),
            //       ),
            //       SizedBox(width: theme.spacing.sm),
            //       Expanded(
            //         child: OutlinedButton.icon(
            //           onPressed: (_session == null || _isBusy) ? null : _startOta,
            //           icon: const Icon(Icons.system_update_alt_rounded, size: 16),
            //           label: const Text('OTA 测试'),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: (_session == null || _isBusy)
                            ? null
                            : _fetchDeviceVersion,
                        icon: const Icon(Icons.info_outline_rounded, size: 16),
                        label: const Text('Fetch Version'),
                      ),
                    ),
                    SizedBox(width: theme.spacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: (_session == null || _isBusy)
                            ? null
                            : _startOta,
                        icon: const Icon(
                          Icons.system_update_alt_rounded,
                          size: 16,
                        ),
                        label: const Text('OTA 测试'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: theme.spacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openApiTestPage,
                    icon: const Icon(Icons.science_outlined, size: 16),
                    label: const Text('打开 API 测试页'),
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
    required this.isOtaRunning,
    required this.isOtaCompleted,
    required this.otaPercent,
    required this.session,
  });

  final bool isAttaching;
  final bool isBusy;
  final bool isOtaRunning;
  final bool isOtaCompleted;
  final double otaPercent;
  final GmacroSession? session;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    Color dotColor;
    String label;
    if (isAttaching) {
      dotColor = theme.colors.warning;
      label = '挂载协议中…';
    } else if (isOtaRunning) {
      dotColor = theme.colors.warning;
      label = 'OTA 升级中 ${(otaPercent * 100).toStringAsFixed(1)}%';
    } else if (isOtaCompleted) {
      dotColor = theme.colors.success;
      label = 'OTA 升级成功';
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
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
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
