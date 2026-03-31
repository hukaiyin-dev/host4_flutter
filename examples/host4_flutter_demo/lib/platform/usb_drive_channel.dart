import 'package:flutter/services.dart';

const _channel = MethodChannel('host4_flutter_demo/usb_drive');

/// Opens the document picker and returns the picked file metadata, or null
/// if the user cancelled.
///
/// Throws [PlatformException] with code `'cancelled'` when the user dismisses
/// the picker. Callers should filter that code before showing an error.
///
/// Only supported on iOS. Check [Platform.isIOS] before calling.
Future<Map<Object?, Object?>?> pickDocument() {
  return _channel.invokeMethod<Map<Object?, Object?>>('pickDocument');
}
