import 'dart:convert';

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
  Future<void> sendData(Map<String, dynamic> data) async {
    final jsonStr = jsonEncode(data);
    await _inner.runJavaScript('Hybrid.sendData(${jsonEncode(jsonStr)})');
  }

  /// Whether the WebView can navigate back in history.
  Future<bool> canGoBack() => _inner.canGoBack();

  /// Navigates back in history.
  Future<void> goBack() => _inner.goBack();

  /// Reloads the current page.
  Future<void> reload() => _inner.reload();

  /// Executes arbitrary JavaScript.
  Future<void> runJavaScript(String js) => _inner.runJavaScript(js);
}
