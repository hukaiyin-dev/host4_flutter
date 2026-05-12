import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:host4_flutter_gmacro/host4_flutter_gmacro.dart';
import 'package:host4_flutter_protocol/host4_flutter_protocol.dart';
import 'package:host4_flutter_transport/host4_flutter_transport.dart';

class GmacroSessionPage extends StatefulWidget {
  const GmacroSessionPage({super.key, required this.transport});

  final TransportSession transport;

  @override
  State<GmacroSessionPage> createState() => _GmacroSessionPageState();
}

class _GmacroSessionPageState extends State<GmacroSessionPage> {
  final Host4Gmacro _gmacro = Host4Gmacro();
  final List<_LogEntry> _logs = <_LogEntry>[];

  StreamSubscription<TransportEvent>? _transportSubscription;
  StreamSubscription<ProtocolEvent>? _protocolSubscription;
  GmacroSession? _gmacroSession;

  String _transportStatus = 'connecting';
  String _protocolStatus = 'waiting-transport';
  bool _isAttaching = false;
  bool _isInvoking = false;

  @override
  void initState() {
    super.initState();
    _addLog('transport', 'Transport session: ${widget.transport.id}');
    _transportSubscription = widget.transport.events.listen(
      _handleTransportEvent,
      onError: (Object error, StackTrace stackTrace) {
        _addErrorLog('transport', error.toString());
      },
    );
  }

  @override
  void dispose() {
    unawaited(_transportSubscription?.cancel());
    unawaited(_protocolSubscription?.cancel());
    final GmacroSession? session = _gmacroSession;
    if (session != null) {
      unawaited(session.close());
    }
    unawaited(widget.transport.disconnect());
    super.dispose();
  }

  void _handleTransportEvent(TransportEvent event) {
    switch (event) {
      case TransportConnecting():
        _setTransportStatus('connecting');
        _addLog('transport', 'BLE transport connecting');
      case TransportConnected():
        _setTransportStatus('connected');
        _addLog('transport', 'BLE transport connected');
      case TransportReady():
        _setTransportStatus('ready');
        _addLog('transport', 'BLE transport ready');
        unawaited(_attachGmacroProtocol());
      case TransportDisconnected(:final cause):
        _setTransportStatus('disconnected');
        final String message = cause == null
            ? 'BLE transport disconnected'
            : 'BLE transport disconnected: ${cause.message}';
        _addLog('transport', message);
      case TransportError(:final failure):
        _setTransportStatus('error');
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
    _addLog('protocol', 'Attaching GMacro protocol');

    try {
      final GmacroSession session = await _gmacro.attach(widget.transport);
      if (!mounted) {
        await session.close();
        return;
      }

      _protocolSubscription = session.events.listen(
        _handleProtocolEvent,
        onError: (Object error, StackTrace stackTrace) {
          _addErrorLog('protocol', error.toString());
        },
      );

      setState(() {
        _gmacroSession = session;
        _protocolStatus = 'attached';
      });
      _addLog('protocol', 'GMacro session attached: ${session.id}');
    } catch (error) {
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
    switch (event) {
      case ProtocolReady():
        _setProtocolStatus('ready');
        _addLog('protocol', 'GMacro protocol ready');
      case ProtocolBusy(:final reason):
        _setProtocolStatus('busy');
        _addLog('protocol', 'GMacro protocol busy: $reason');
      case ProtocolError(:final failure):
        _setProtocolStatus('error');
        _addErrorLog('protocol', '${failure.code}: ${failure.message}');
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
    _addLog('invoke', 'invoke(fetchDeviceVersion)');

    try {
      final Map<String, Object?> result = await session.invoke(
        'fetchDeviceVersion',
      );
      _addLog('result', _formatPayload(result));
    } catch (error) {
      _addErrorLog('invoke', error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isInvoking = false;
        });
      }
    }
  }

  void _showOtaPlaceholder() {
    _addLog('ota', 'OTA 按钮已预留，当前尚未接通原生 startOta 方法。');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('OTA 入口已预留，等待原生方法接通。')));
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
                      onPressed: _showOtaPlaceholder,
                      icon: const Icon(Icons.system_update_alt),
                      label: const Text('OTA'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '当前 example 用于验证 BLE -> transport -> GMacro -> fetchDeviceVersion 主链路；OTA 入口先保留。',
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
