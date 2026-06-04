import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:host4_flutter_device_native/host4_flutter_device_native.dart';
import 'package:host4_flutter_gmacro/host4_flutter_gmacro.dart';
import 'package:host4_flutter_protocol/host4_flutter_protocol.dart';
import 'package:host4_flutter_transport/host4_flutter_transport.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:host4_flutter_log/host4_flutter_log.dart';

class GmacroSessionPage extends StatefulWidget {
  const GmacroSessionPage({super.key, required this.transport});

  final TransportSession transport;

  @override
  State<GmacroSessionPage> createState() => _GmacroSessionPageState();
}

class _GmacroSessionPageState extends State<GmacroSessionPage> {
  final Host4Logger _log = Host4Logger('GMacroSession');
  final Host4Gmacro _gmacro = Host4Gmacro();
  final List<_LogEntry> _logs = <_LogEntry>[];

  StreamSubscription<TransportEvent>? _transportSubscription;
  StreamSubscription<ProtocolEvent>? _protocolSubscription;
  StreamSubscription<DeviceCalibrationEvent>? _calibrationSubscription;
  GmacroSession? _gmacroSession;

  String _transportStatus = 'connecting';
  String _protocolStatus = 'waiting-transport';
  bool _isAttaching = false;
  bool _isInvoking = false;

  // OTA state
  bool _isOtaRunning = false;
  double _otaProgress = 0;
  String _otaStatusMessage = '';
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    _log.info('Init session for transport: ${widget.transport.id}');
    _addLog('transport', 'Transport session: ${widget.transport.id}');
    _transportSubscription = widget.transport.events.listen(
      _handleTransportEvent,
      onError: (Object error, StackTrace stackTrace) {
        _log.error('Transport stream error', error: error, stackTrace: stackTrace);
        _addErrorLog('transport', error.toString());
      },
    );

    // For sharing or opening urls while app is in memory
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((value) {
      if (value.isNotEmpty) {
        _log.info('Shared files received (stream): ${value.length} files');
        _handleSharedFiles(value);
      }
    }, onError: (err) {
      _log.error('Intent data stream error', error: err);
      _addLog('share', 'getIntentDataStream error: $err');
    });

    // For sharing or opening urls while app is closed
    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      if (value.isNotEmpty) {
        _log.info('Initial shared files received: ${value.length} files');
        _handleSharedFiles(value);
      }
    });
  }

  void _handleSharedFiles(List<SharedMediaFile> files) {
    final binFile = files.firstWhere(
      (f) => f.path.toLowerCase().endsWith('.bin'),
      orElse: () => files.first,
    );
    _log.info('Handling shared file: ${binFile.path}');
    _showOtaDialog(File(binFile.path));
  }

  void _showOtaDialog(File file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('发现固件文件'),
        content: Text('是否开始对设备进行 OTA 升级？\n文件：${file.path.split('/').last}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startOta(file);
            },
            child: const Text('开始升级'),
          ),
        ],
      ),
    );
  }

  Future<void> _startOta(File file) async {
    final GmacroSession? session = _gmacroSession;
    if (session == null) {
      _log.error('Cannot start OTA: GMacro session is null');
      _addErrorLog('ota', 'GMacro 会话未就绪');
      return;
    }

    try {
      final bytes = await file.readAsBytes();
      _log.info('Starting OTA for file: ${file.path}, size: ${bytes.length}');
      setState(() {
        _isOtaRunning = true;
        _otaProgress = 0;
        _otaStatusMessage = '正在初始化 OTA...';
      });
      _addLog('ota', '开始 OTA 升级，文件大小: ${bytes.length} bytes');
      await session.startOta(bytes);
    } catch (e, s) {
      _log.error('Failed to start OTA', error: e, stackTrace: s);
      setState(() {
        _isOtaRunning = false;
        _otaStatusMessage = 'OTA 启动失败: $e';
      });
      _addErrorLog('ota', 'OTA 启动失败: $e');
    }
  }

  @override
  void dispose() {
    _log.info('Disposing session page');
    unawaited(_transportSubscription?.cancel());
    unawaited(_protocolSubscription?.cancel());
    unawaited(_calibrationSubscription?.cancel());
    _intentDataStreamSubscription.cancel();
    final GmacroSession? session = _gmacroSession;
    if (session != null) {
      unawaited(session.close());
    }
    unawaited(widget.transport.disconnect());
    super.dispose();
  }

  void _handleTransportEvent(TransportEvent event) {
    _log.debug('Transport event: $event');
    switch (event) {
      case TransportConnecting():
        _setTransportStatus('connecting');
        _addLog('transport', 'BLE transport connecting');
      case TransportConnected():
        _setTransportStatus('connected');
        _addLog('transport', 'BLE transport connected');
      case TransportReady():
        _setTransportStatus('ready');
        _log.info('Transport ready, attaching protocol');
        _addLog('transport', 'BLE transport ready');
        unawaited(_attachGmacroProtocol());
      case TransportDisconnected(:final cause):
        _setTransportStatus('disconnected');
        final String message = cause == null
            ? 'BLE transport disconnected'
            : 'BLE transport disconnected: ${cause.message}';
        _log.warn(message);
        _addLog('transport', message);
      case TransportError(:final failure):
        _setTransportStatus('error');
        _log.error('Transport error: ${failure.code} - ${failure.message}');
        _addErrorLog('transport', '${failure.code}: ${failure.message}');
    }
  }

  Future<void> _attachGmacroProtocol() async {
    if (_isAttaching || _gmacroSession != null) {
      return;
    }

    setState(() {
      _isAttaching = true;
      _protocolStatus = 'attaching';
    });
    _log.info('Attaching GMacro protocol...');
    _addLog('protocol', 'Attaching GMacro protocol');

    try {
      final GmacroSession session = await _gmacro.attach(widget.transport);
      if (!mounted) {
        _log.info('Page unmounted during attach, closing session');
        await session.close();
        return;
      }

      _protocolSubscription = session.events.listen(
        _handleProtocolEvent,
        onError: (Object error, StackTrace stackTrace) {
          _log.error('Protocol stream error', error: error, stackTrace: stackTrace);
          _addErrorLog('protocol', error.toString());
        },
      );

      _calibrationSubscription = session.calibrationEvents.listen(
        (DeviceCalibrationEvent event) {
          _log.info('Calibration: $event');
          _addLog(
            'calibration',
            '${event.kind?.name ?? 'subId=0x${event.subId.toRadixString(16)}'} '
            'result=${event.result} '
            'p1=${event.param1} p2=${event.param2} '
            'errors=${event.errorList}',
          );
        },
        onError: (Object error, StackTrace stackTrace) {
          _log.error(
            'Calibration stream error',
            error: error,
            stackTrace: stackTrace,
          );
        },
      );

      setState(() {
        _gmacroSession = session;
        _protocolStatus = 'attached';
      });
      _log.info('GMacro session attached: ${session.id}');
      _addLog('protocol', 'GMacro session attached: ${session.id}');
    } catch (error, stackTrace) {
      _log.error('Failed to attach GMacro protocol', error: error, stackTrace: stackTrace);
      if (!mounted) {
        return;
      }

      setState(() {
        _protocolStatus = 'attach-failed';
      });
      _addErrorLog('protocol', error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isAttaching = false;
        });
      }
    }
  }

  void _handleProtocolEvent(ProtocolEvent event) {
    _log.debug('Protocol event: $event');
    switch (event) {
      case ProtocolReady():
        _setProtocolStatus('ready');
        _log.info('GMacro protocol ready');
        _addLog('protocol', 'GMacro protocol ready');
      case ProtocolBusy(:final reason, :final payload):
        _setProtocolStatus('busy');
        _log.debug('GMacro protocol busy: $reason, payload: $payload');
        _addLog('protocol', 'GMacro protocol busy: $reason');
        if (_isOtaRunning) {
          if (reason == 'progress') {
            final progress = payload['progress'];
            if (progress is num) {
              setState(() {
                _otaProgress = progress.toDouble();
                _otaStatusMessage = '升级中: ${(progress * 100).toStringAsFixed(1)}%';
              });
            }
          } else if (reason == 'success') {
            setState(() {
              _otaProgress = 1.0;
              _isOtaRunning = false;
              _otaStatusMessage = 'OTA 升级成功！';
            });
            _addLog('ota', 'OTA 升级成功');
          }
        }
      case ProtocolError(:final failure):
        _setProtocolStatus('error');
        _log.error('Protocol error: ${failure.code} - ${failure.message}');
        _addErrorLog('protocol', '${failure.code}: ${failure.message}');
        if (_isOtaRunning) {
          setState(() {
            _isOtaRunning = false;
            _otaStatusMessage = 'OTA 失败: ${failure.message}';
          });
        }
    }
  }

  Future<void> _fetchDeviceVersion() async {
    final GmacroSession? session = _gmacroSession;
    if (session == null || _isInvoking) {
      return;
    }

    setState(() {
      _isInvoking = true;
    });
    _log.info('Invoking fetchDeviceVersion');
    _addLog('invoke', 'invoke(fetchDeviceVersion)');

    try {
      final Map<String, Object?> result = await session.invoke(
        'fetchDeviceVersion',
      );
      _log.info('fetchDeviceVersion success: $result');
      _addLog('result', _formatPayload(result));
    } catch (error, stackTrace) {
      _log.error('fetchDeviceVersion failed', error: error, stackTrace: stackTrace);
      _addErrorLog('invoke', error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isInvoking = false;
        });
      }
    }
  }

  void _testOtaMock() {
    _addLog('ota', '请通过其他 App 分享 .bin 固件文件到本 App 进行真实升级测试。');
    _showOtaDialog(File('mock_firmware.bin'));
  }

  void _setTransportStatus(String status) {
    if (!mounted) {
      return;
    }

    setState(() {
      _transportStatus = status;
    });
  }

  void _setProtocolStatus(String status) {
    if (!mounted) {
      return;
    }

    setState(() {
      _protocolStatus = status;
    });
  }

  void _addLog(String category, String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _logs.insert(
        0,
        _LogEntry(
          timestamp: DateTime.now(),
          category: category,
          message: message,
        ),
      );
    });
  }

  void _addErrorLog(String category, String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _logs.insert(
        0,
        _LogEntry(
          timestamp: DateTime.now(),
          category: category,
          message: message,
          isError: true,
        ),
      );
    });
  }

  String _formatPayload(Map<String, Object?> payload) {
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    try {
      return encoder.convert(payload);
    } catch (_) {
      return payload.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canFetchVersion = _gmacroSession != null && !_isInvoking;

    return Scaffold(
      appBar: AppBar(title: const Text('GMacro Session')),
      body: Column(
        children: <Widget>[
          if (_isOtaRunning || _otaStatusMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
              child: Column(
                children: [
                  Text(
                    _otaStatusMessage,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _otaProgress,
                    onChanged: null,
                    min: 0,
                    max: 1,
                  ),
                  if (!_isOtaRunning && _otaStatusMessage.contains('成功'))
                    TextButton(
                      onPressed: () => setState(() => _otaStatusMessage = ''),
                      child: const Text('确定'),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.transport.device.name.isEmpty
                      ? 'Unknown Device'
                      : widget.transport.device.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Device ID: ${widget.transport.device.id}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _StatusChip(label: 'Transport', value: _transportStatus),
                    _StatusChip(label: 'Protocol', value: _protocolStatus),
                    _StatusChip(
                      label: 'Action',
                      value: _isInvoking
                          ? 'invoking'
                          : _isAttaching
                          ? 'attaching'
                          : 'idle',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: canFetchVersion ? _fetchDeviceVersion : null,
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Fetch Version'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _isOtaRunning ? null : _testOtaMock,
                      icon: const Icon(Icons.system_update_alt),
                      label: const Text('OTA'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '当前支持通过系统分享 .bin 文件到此 App 进行升级；或点击 OTA 查看说明。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: _logs.isEmpty
                ? const Center(child: Text('等待事件...'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _logs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (BuildContext context, int index) {
                      final _LogEntry entry = _logs[index];
                      final ColorScheme colorScheme = Theme.of(
                        context,
                      ).colorScheme;
                      final Color color = entry.isError
                          ? colorScheme.errorContainer
                          : colorScheme.surfaceContainerHighest;
                      final Color foreground = entry.isError
                          ? colorScheme.onErrorContainer
                          : colorScheme.onSurface;

                      return Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '${entry.timeLabel} · ${entry.category}',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: foreground),
                            ),
                            const SizedBox(height: 6),
                            SelectableText(
                              entry.message,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: foreground),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $value'));
  }
}

class _LogEntry {
  const _LogEntry({
    required this.timestamp,
    required this.category,
    required this.message,
    this.isError = false,
  });

  final DateTime timestamp;
  final String category;
  final String message;
  final bool isError;

  String get timeLabel {
    final String twoDigitMinute = timestamp.minute.toString().padLeft(2, '0');
    final String twoDigitSecond = timestamp.second.toString().padLeft(2, '0');
    return '${timestamp.hour}:$twoDigitMinute:$twoDigitSecond';
  }
}
