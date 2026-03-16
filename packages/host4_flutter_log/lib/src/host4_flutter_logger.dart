import 'package:flutter/foundation.dart';

class Host4FlutterLogger {
  const Host4FlutterLogger._();

  static void info(String message, {String tag = 'Host4Flutter'}) {
    debugPrint('[$tag] $message');
  }
}
