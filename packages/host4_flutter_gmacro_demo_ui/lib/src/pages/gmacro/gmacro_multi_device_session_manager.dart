import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:host4_flutter_gmacro/host4_flutter_gmacro.dart';
import 'package:host4_flutter_transport/host4_flutter_transport.dart';

/// Keeps each demo transport and its protocol session bound to one device.
class GmacroMultiDeviceSessionManager extends ChangeNotifier {
  GmacroMultiDeviceSessionManager({
    required Future<GmacroSession> Function(TransportSession) attach,
    Future<void> Function()? releaseUsb,
  }) : _attach = attach,
       _releaseUsb = releaseUsb {
    _inputSub = inputHub.buttonEvents.listen((event) {
      final key = _keyFor(TransportKind.ble, event.deviceId);
      final connection =
          _connections[key] ??
          _connections.values
              .where((entry) => entry.transport.id == event.transportSessionId)
              .firstOrNull;
      if (connection == null || _closed) return;
      connection.lastInput = '${event.key.name} ${event.phase.name}';
      notifyListeners();
    });
  }

  final Future<GmacroSession> Function(TransportSession) _attach;
  final Future<void> Function()? _releaseUsb;
  final _connections = <String, GmacroDemoConnection>{};
  final GmacroMultiInputHub inputHub = GmacroMultiInputHub();
  StreamSubscription<GmacroDeviceButtonEvent>? _inputSub;
  bool _closed = false;
  String? selectedKey;

  List<GmacroDemoConnection> get connections =>
      List<GmacroDemoConnection>.unmodifiable(_connections.values);

  GmacroSession? get selectedSession => _connections[selectedKey]?.session;

  static String _keyFor(TransportKind kind, String id) => '${kind.name}:$id';

  bool contains(TransportKind kind, String deviceId) =>
      _connections.containsKey(_keyFor(kind, deviceId));

  Future<void> addTransport(TransportSession transport) async {
    if (_closed) throw StateError('Multi-device manager is closed.');
    final key = _keyFor(transport.device.kind, transport.device.id);
    if (_connections.containsKey(key)) {
      throw StateError('Device already added: $key');
    }
    final connection = GmacroDemoConnection(key: key, transport: transport);
    _connections[key] = connection;
    selectedKey ??= key;
    connection.events = transport.events.listen(
      (event) => unawaited(_onTransportEvent(connection, event)),
      onError: (Object error) {
        if (!_isCurrent(connection)) return;
        connection.status = '连接错误: $error';
        notifyListeners();
      },
    );
    notifyListeners();
  }

  bool _isCurrent(GmacroDemoConnection connection) =>
      !_closed && identical(_connections[connection.key], connection);

  Future<void> _onTransportEvent(
    GmacroDemoConnection connection,
    TransportEvent event,
  ) async {
    if (!_isCurrent(connection)) return;
    switch (event) {
      case TransportReady():
        connection.transportReady = true;
        if (connection.session != null || connection.attaching) return;
        final generation = connection.generation;
        connection.attaching = true;
        connection.status = '协议挂载中';
        notifyListeners();
        try {
          final session = await _attach(connection.transport);
          if (!_isCurrent(connection) ||
              connection.generation != generation ||
              !connection.transportReady) {
            await session.close();
            return;
          }
          connection.session = session;
          inputHub.addSession(session);
          connection.status = '可通信';
        } catch (error) {
          if (_isCurrent(connection) && connection.generation == generation) {
            connection.transportReady = false;
            connection.status = '协议错误: $error';
          }
        } finally {
          connection.attaching = false;
          if (_isCurrent(connection)) {
            notifyListeners();
            if (connection.transportReady &&
                connection.session == null &&
                connection.generation != generation) {
              unawaited(_onTransportEvent(connection, const TransportReady()));
            }
          }
        }
      case TransportConnecting():
        connection.generation += 1;
        final generation = connection.generation;
        connection.transportReady = false;
        await _detach(connection);
        if (!_isCurrent(connection) || connection.generation != generation) {
          return;
        }
        connection.status = '连接中';
        notifyListeners();
      case TransportConnected():
        connection.status = '等待就绪';
        notifyListeners();
      case TransportRecovering():
        connection.generation += 1;
        final generation = connection.generation;
        connection.transportReady = false;
        await _detach(connection);
        if (!_isCurrent(connection) || connection.generation != generation) {
          return;
        }
        connection.status = '恢复中';
        notifyListeners();
      case TransportDisconnected():
        connection.generation += 1;
        final generation = connection.generation;
        connection.transportReady = false;
        await _detach(connection);
        if (!_isCurrent(connection) || connection.generation != generation) {
          return;
        }
        connection.status = '已断开';
        notifyListeners();
      case TransportError(failure: final failure):
        connection.generation += 1;
        final generation = connection.generation;
        connection.transportReady = false;
        await _detach(connection);
        if (!_isCurrent(connection) || connection.generation != generation) {
          return;
        }
        connection.status = '连接错误: ${failure.message}';
        notifyListeners();
    }
  }

  Future<void> _detach(GmacroDemoConnection connection) async {
    final session = connection.session;
    connection.session = null;
    if (session == null) return;
    await inputHub.removeSession(session.id);
    await session.close();
  }

  void select(String key) {
    if (!_connections.containsKey(key)) return;
    selectedKey = key;
    notifyListeners();
  }

  Future<Map<String, Object?>> querySelectedVersion() async {
    final session = selectedSession;
    if (session == null) throw StateError('Selected device is not ready.');
    return session.fetchDeviceVersion();
  }

  Future<void> remove(String key) async {
    final connection = _connections.remove(key);
    if (connection == null) return;
    if (selectedKey == key) selectedKey = _connections.keys.firstOrNull;
    if (!_closed) notifyListeners();
    await connection.events?.cancel();
    await _detach(connection);
    await connection.transport.disconnect();
    if (connection.transport.device.kind == TransportKind.usb) {
      await _releaseUsb?.call();
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    for (final key in _connections.keys.toList()) {
      await remove(key);
    }
    await _inputSub?.cancel();
    await inputHub.dispose();
    dispose();
  }
}

class GmacroDemoConnection {
  GmacroDemoConnection({required this.key, required this.transport});

  final String key;
  final TransportSession transport;
  StreamSubscription<TransportEvent>? events;
  GmacroSession? session;
  bool attaching = false;
  bool transportReady = false;
  int generation = 0;
  String status = '等待就绪';
  String? lastInput;
}
