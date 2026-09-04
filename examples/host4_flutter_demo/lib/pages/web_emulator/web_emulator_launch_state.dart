import 'package:host4_flutter_web_emulator/host4_flutter_web_emulator.dart';

enum WebEmulatorLaunchPhase { loading, running, failed }

bool isSuccessfulLaunchBridgeMessage(String method, Object? payload) {
  if (method != 'launched') return false;
  try {
    final message = Host4WebEmulatorBridgeMessage.fromPayload(payload);
    return message.type == 'launched' && message.ok;
  } on FormatException {
    return false;
  }
}

class WebEmulatorLaunchState {
  const WebEmulatorLaunchState.loading({this.attempt = 0})
    : phase = WebEmulatorLaunchPhase.loading,
      error = null;

  const WebEmulatorLaunchState._({
    required this.phase,
    required this.attempt,
    this.error,
  });

  final WebEmulatorLaunchPhase phase;
  final int attempt;
  final String? error;

  WebEmulatorLaunchState running() => WebEmulatorLaunchState._(
    phase: WebEmulatorLaunchPhase.running,
    attempt: attempt,
  );

  WebEmulatorLaunchState failed(Object cause) => WebEmulatorLaunchState._(
    phase: WebEmulatorLaunchPhase.failed,
    attempt: attempt,
    error: cause.toString(),
  );

  WebEmulatorLaunchState retry() =>
      WebEmulatorLaunchState.loading(attempt: attempt + 1);
}
