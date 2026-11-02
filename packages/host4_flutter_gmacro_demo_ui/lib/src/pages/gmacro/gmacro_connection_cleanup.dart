import 'package:flutter/foundation.dart';

/// Close the protocol before its transport, when this page owns that transport.
Future<void> closeGmacroConnection({
  required Future<void> Function()? closeProtocol,
  required Future<void> Function()? disconnectTransport,
}) async {
  try {
    await closeProtocol?.call();
  } catch (error) {
    debugPrint('GMacro protocol cleanup failed: $error');
  }
  try {
    await disconnectTransport?.call();
  } catch (error) {
    debugPrint('GMacro transport cleanup failed: $error');
  }
}
