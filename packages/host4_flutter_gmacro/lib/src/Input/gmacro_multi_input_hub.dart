import 'dart:async';

import 'package:host4_flutter_transport/host4_flutter_transport.dart';

import '../Models/gmacro_gamepad_key.dart';
import '../Models/gmacro_protocol_events.dart';
import '../gmacro_session.dart';
import 'gmacro_input_service.dart';
import 'gmacro_input_state.dart';

/// The identity of the connection that produced an input event.
class GmacroInputSourceId {
  const GmacroInputSourceId({
    required this.deviceId,
    required this.transportSessionId,
    required this.protocolSessionId,
  });

  final String deviceId;
  final String transportSessionId;
  final String protocolSessionId;
}

class GmacroDeviceInputState extends GmacroInputSourceId {
  const GmacroDeviceInputState({
    required super.deviceId,
    required super.transportSessionId,
    required super.protocolSessionId,
    required this.state,
  });

  final GmacroInputState state;
}

class GmacroDeviceButtonEvent extends GmacroInputSourceId {
  const GmacroDeviceButtonEvent({
    required super.deviceId,
    required super.transportSessionId,
    required super.protocolSessionId,
    required this.key,
    required this.phase,
  });

  final GamepadKey key;
  final GmacroButtonPhase phase;
}

class GmacroDeviceInputError extends GmacroInputSourceId {
  const GmacroDeviceInputError({
    required super.deviceId,
    required super.transportSessionId,
    required super.protocolSessionId,
    required this.error,
    required this.stackTrace,
  });

  final Object error;
  final StackTrace stackTrace;
}

/// Combines input from independent protocol sessions without assigning players.
class GmacroMultiInputHub {
  final _bindings = <String, _SessionBinding>{};
  final _states = StreamController<GmacroDeviceInputState>.broadcast();
  final _buttonEvents = StreamController<GmacroDeviceButtonEvent>.broadcast();
  final _errors = StreamController<GmacroDeviceInputError>.broadcast();
  bool _disposed = false;

  Stream<GmacroDeviceInputState> get states => _states.stream;
  Stream<GmacroDeviceButtonEvent> get buttonEvents => _buttonEvents.stream;
  Stream<GmacroDeviceInputError> get errors => _errors.stream;

  void addSession(GmacroSession session) {
    if (_disposed) throw StateError('GmacroMultiInputHub is disposed.');
    final existing = _bindings[session.id];
    if (identical(existing?.session, session)) return;
    if (existing != null) {
      throw StateError('Protocol session ${session.id} is already registered.');
    }

    final binding = _SessionBinding(session);
    _bindings[session.id] = binding;
    binding.inputSubscription = session.realtimeEvents.listen(
      (event) => _onInput(binding, event),
      onError: (Object error, StackTrace stackTrace) =>
          _onError(binding, error, stackTrace),
      onDone: () => _remove(binding),
    );
    binding.transportSubscription = session.transport.events.listen(
      (event) {
        if (event is TransportError) {
          _onError(binding, event.failure, StackTrace.current);
        } else if (event is TransportDisconnected) {
          _remove(binding);
        }
      },
      onError: (Object error, StackTrace stackTrace) =>
          _onError(binding, error, stackTrace),
      onDone: () => _remove(binding),
    );
  }

  Future<void> removeSession(String protocolSessionId) async {
    final binding = _bindings[protocolSessionId];
    if (binding != null) await _remove(binding);
  }

  void _onInput(_SessionBinding binding, GmacroRealtimeEvent event) {
    if (!_isActive(binding)) return;
    GmacroInputState? next;
    if (event is DeviceKeysStateEvent) {
      next = GmacroInputState.fromDeviceKeysState(event);
    } else if (event is TestEventMode) {
      next = GmacroInputState.fromTestEventMode(event);
    }
    if (next == null) return;
    next = next.mergeJoystickDirections();

    final previousKeys = binding.state.pressedKeys;
    final nextKeys = next.pressedKeys;
    binding.state = next;
    for (final key in nextKeys.difference(previousKeys)) {
      _buttonEvents.add(_buttonEvent(binding, key, GmacroButtonPhase.down));
    }
    for (final key in previousKeys.difference(nextKeys)) {
      _buttonEvents.add(_buttonEvent(binding, key, GmacroButtonPhase.up));
    }
    _states.add(
      GmacroDeviceInputState(
        deviceId: binding.deviceId,
        transportSessionId: binding.transportSessionId,
        protocolSessionId: binding.protocolSessionId,
        state: next,
      ),
    );
  }

  GmacroDeviceButtonEvent _buttonEvent(
    _SessionBinding binding,
    GamepadKey key,
    GmacroButtonPhase phase,
  ) => GmacroDeviceButtonEvent(
    deviceId: binding.deviceId,
    transportSessionId: binding.transportSessionId,
    protocolSessionId: binding.protocolSessionId,
    key: key,
    phase: phase,
  );

  bool _isActive(_SessionBinding binding) =>
      !_disposed && identical(_bindings[binding.protocolSessionId], binding);

  void _onError(_SessionBinding binding, Object error, StackTrace stackTrace) {
    if (!_isActive(binding)) return;
    _reportError(binding, error, stackTrace);
    _remove(binding);
  }

  void _reportError(
    _SessionBinding binding,
    Object error,
    StackTrace stackTrace,
  ) {
    _errors.add(
      GmacroDeviceInputError(
        deviceId: binding.deviceId,
        transportSessionId: binding.transportSessionId,
        protocolSessionId: binding.protocolSessionId,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }

  Future<void> _remove(_SessionBinding binding) async {
    if (!identical(_bindings[binding.protocolSessionId], binding)) return;
    _bindings.remove(binding.protocolSessionId);
    for (final key in binding.state.pressedKeys) {
      _buttonEvents.add(_buttonEvent(binding, key, GmacroButtonPhase.up));
    }
    _states.add(
      GmacroDeviceInputState(
        deviceId: binding.deviceId,
        transportSessionId: binding.transportSessionId,
        protocolSessionId: binding.protocolSessionId,
        state: GmacroInputState.empty(),
      ),
    );
    try {
      await binding.inputSubscription?.cancel();
    } catch (error, stackTrace) {
      _reportError(binding, error, stackTrace);
    }
    try {
      await binding.transportSubscription?.cancel();
    } catch (error, stackTrace) {
      _reportError(binding, error, stackTrace);
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    for (final binding in _bindings.values.toList()) {
      await _remove(binding);
    }
    await _states.close();
    await _buttonEvents.close();
    await _errors.close();
  }
}

class _SessionBinding {
  _SessionBinding(this.session);

  final GmacroSession session;
  GmacroInputState state = GmacroInputState.empty();
  StreamSubscription<GmacroRealtimeEvent>? inputSubscription;
  StreamSubscription<TransportEvent>? transportSubscription;

  String get deviceId => session.transport.device.id;
  String get transportSessionId => session.transport.id;
  String get protocolSessionId => session.id;
}
