import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Typed controller wrapping [WebViewController] with H5-facing helpers.
class Host4WebController {
  Host4WebController(this._inner);

  final WebViewController _inner;

  /// The underlying [WebViewController] for platform-specific operations.
  WebViewController get inner => _inner;

  /// Calls `Hybrid.sendData(data)` on the H5 page.
  ///
  /// [data] is JSON-encoded and forwarded as the argument to `Hybrid.sendData`.
  /// The H5 page is expected to define `window.Hybrid.sendData`.
  /// Silently ignores [PlatformException] that occurs when the page is not yet
  /// ready to receive messages (e.g. `window.Hybrid` is not yet initialised).
  Future<void> sendData(Map<String, dynamic> data) async {
    final jsonStr = jsonEncode(data);
    await runJavaScript('Hybrid.sendData(${jsonEncode(jsonStr)})');
  }

  /// Executes arbitrary JavaScript, swallowing [PlatformException] caused by
  /// the page not being ready (e.g. evaluating JS before the DOM is set up).
  Future<void> runJavaScript(String js) async {
    try {
      await _inner.runJavaScript(js);
    } on PlatformException catch (e) {
      debugPrint(
        '[Host4WebView] runJavaScript failed (${e.code}): ${e.message}',
      );
    }
  }

  /// Whether the WebView can navigate back in history.
  Future<bool> canGoBack() => _inner.canGoBack();

  /// Navigates back in history.
  Future<void> goBack() => _inner.goBack();

  /// Reloads the current page.
  Future<void> reload() => _inner.reload();
}
