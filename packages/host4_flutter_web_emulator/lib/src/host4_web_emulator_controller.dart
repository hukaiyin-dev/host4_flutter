import 'dart:async';

import 'package:host4_flutter_webview/host4_flutter_webview.dart';

import 'host4_web_emulator_bridge_message.dart';
import 'host4_web_emulator_core_cache.dart';
import 'host4_web_emulator_javascript.dart';
import 'host4_web_emulator_launch_config.dart';

typedef Host4WebEmulatorJavaScriptExecutor =
    Future<void> Function(String script);

class Host4WebEmulatorState {
  const Host4WebEmulatorState({
    required this.stateBase64,
    this.thumbnailBase64,
  });

  final String stateBase64;
  final String? thumbnailBase64;
}

class Host4WebEmulatorException implements Exception {
  const Host4WebEmulatorException(this.message);

  final String message;

  @override
  String toString() => 'Host4WebEmulatorException: $message';
}

class Host4WebEmulatorController {
  Host4WebEmulatorController(
    Host4WebController webController, {
    Duration requestTimeout = const Duration(seconds: 15),
  }) : this._(webController.runJavaScript, requestTimeout: requestTimeout);

  Host4WebEmulatorController._(
    this._executeJavaScript, {
    required this.requestTimeout,
    String Function()? requestIdFactory,
  }) : _requestIdFactory = requestIdFactory;

  factory Host4WebEmulatorController.forJavaScriptExecutor(
    Host4WebEmulatorJavaScriptExecutor executor, {
    Duration requestTimeout = const Duration(seconds: 15),
    String Function()? requestIdFactory,
  }) {
    return Host4WebEmulatorController._(
      executor,
      requestTimeout: requestTimeout,
      requestIdFactory: requestIdFactory,
    );
  }

  final Host4WebEmulatorJavaScriptExecutor _executeJavaScript;
  final Duration requestTimeout;
  final String Function()? _requestIdFactory;
  final Map<String, Completer<Host4WebEmulatorBridgeMessage>> _pending =
      <String, Completer<Host4WebEmulatorBridgeMessage>>{};
  int _requestSequence = 0;
  bool _disposed = false;

  Future<void> launch(
    Host4WebEmulatorLaunchConfig config, {
    ResolvedCoreData? resolvedCoreData,
  }) async {
    await _request(
      action: 'launch',
      successType: 'launched',
      script: (requestId) => Host4WebEmulatorJavaScript.launch(
        config,
        requestId: requestId,
        resolvedCoreData: resolvedCoreData,
      ),
    );
  }

  Future<void> pause() async {
    await _request(
      action: 'pause',
      successType: 'paused',
      script: Host4WebEmulatorJavaScript.pause,
    );
  }

  Future<void> resume({double? rate}) async {
    await _request(
      action: 'resume',
      successType: 'resumed',
      script: (requestId) => Host4WebEmulatorJavaScript.resume(requestId, rate),
    );
  }

  Future<void> restart() async {
    await _request(
      action: 'restart',
      successType: 'restarted',
      script: Host4WebEmulatorJavaScript.restart,
    );
  }

  Future<void> exit() async {
    await _request(
      action: 'exit',
      successType: 'exited',
      script: Host4WebEmulatorJavaScript.exit,
    );
  }

  Future<Host4WebEmulatorState> saveState() async {
    final message = await _request(
      action: 'saveState',
      successType: 'stateSaved',
      script: Host4WebEmulatorJavaScript.saveState,
    );
    final data = _dataMap(message);
    final state = data['state'];
    final thumbnail = data['thumbnail'];
    if (state is! String) {
      throw const Host4WebEmulatorException(
        'stateSaved response does not contain state data.',
      );
    }
    return Host4WebEmulatorState(
      stateBase64: state,
      thumbnailBase64: thumbnail is String ? thumbnail : null,
    );
  }

  Future<void> loadState(String stateBase64) async {
    await _request(
      action: 'loadState',
      successType: 'stateLoaded',
      script: (requestId) =>
          Host4WebEmulatorJavaScript.loadState(stateBase64, requestId),
    );
  }

  Future<String> screenshot() async {
    final message = await _request(
      action: 'screenshot',
      successType: 'screenshotTaken',
      script: Host4WebEmulatorJavaScript.screenshot,
    );
    final image = _dataMap(message)['image'];
    if (image is! String) {
      throw const Host4WebEmulatorException(
        'screenshot response does not contain image data.',
      );
    }
    return image;
  }

  Future<String> saveSram() async {
    final message = await _request(
      action: 'saveSRAM',
      successType: 'sramSaved',
      script: Host4WebEmulatorJavaScript.saveSram,
    );
    final sram = _dataMap(message)['sram'];
    if (sram is! String) {
      throw const Host4WebEmulatorException(
        'sramSaved response does not contain SRAM data.',
      );
    }
    return sram;
  }

  Future<void> setRate(double rate) async {
    await _request(
      action: 'setRate',
      successType: 'rateSet',
      script: (requestId) =>
          Host4WebEmulatorJavaScript.setRate(rate, requestId),
    );
  }

  Future<void> keyEvent(
    String button, {
    String action = 'down',
    int player = 1,
    int? duration,
  }) {
    return _executeJavaScript(
      Host4WebEmulatorJavaScript.keyEvent(
        button,
        action: action,
        player: player,
        duration: duration,
      ),
    );
  }

  bool handleBridgeMessage(String method, Object? payload) {
    Host4WebEmulatorBridgeMessage message;
    try {
      message = Host4WebEmulatorBridgeMessage.fromPayload(payload);
    } on FormatException {
      return false;
    }
    final completer = _pending[message.requestId];
    if (completer == null || completer.isCompleted) return false;
    completer.complete(message);
    return true;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    const error = Host4WebEmulatorException('Controller was disposed.');
    for (final completer in _pending.values) {
      if (!completer.isCompleted) completer.completeError(error);
    }
    _pending.clear();
  }

  Future<Host4WebEmulatorBridgeMessage> _request({
    required String action,
    required String successType,
    required String Function(String requestId) script,
  }) async {
    if (_disposed) {
      throw const Host4WebEmulatorException('Controller was disposed.');
    }
    final requestId = _nextRequestId(action);
    final completer = Completer<Host4WebEmulatorBridgeMessage>();
    _pending[requestId] = completer;
    try {
      await _executeJavaScript(script(requestId));
      final message = await completer.future.timeout(
        requestTimeout,
        onTimeout: () => throw Host4WebEmulatorException(
          '$action timed out after ${requestTimeout.inSeconds}s.',
        ),
      );
      if (!message.ok) {
        throw Host4WebEmulatorException(
          message.error?.toString() ?? '$action failed.',
        );
      }
      if (message.type != successType) {
        throw Host4WebEmulatorException(
          '$action returned unexpected response ${message.type}.',
        );
      }
      return message;
    } finally {
      _pending.remove(requestId);
    }
  }

  String _nextRequestId(String action) {
    final factory = _requestIdFactory;
    if (factory != null) return factory();
    _requestSequence += 1;
    return '${action}_${DateTime.now().microsecondsSinceEpoch}_$_requestSequence';
  }

  static Map<Object?, Object?> _dataMap(Host4WebEmulatorBridgeMessage message) {
    final data = message.data;
    if (data is Map) return data;
    return const <Object?, Object?>{};
  }
}
