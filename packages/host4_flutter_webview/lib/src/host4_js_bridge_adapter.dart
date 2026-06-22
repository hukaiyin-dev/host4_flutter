/// Abstract adapter that defines the JS bridge protocol for a specific H5 page.
///
/// Implement this class to describe the bridge between Flutter and H5:
/// - [adapterJs]: optional page-specific JS injected after the generic bridge.
///   `Host4WebView` already exposes `JsBridge.anyMethod(arg)` and forwards it as
///   `JsBridge.postMessage(JSON.stringify({method, payload}))`.
/// - [onMessage]: called when H5 sends a message through the bridge.
///
/// Injection timing: the generic bridge and [adapterJs] are injected when a page
/// starts and finishes loading. H5 should call `JsBridge[methodName](paramsStr)`
/// without branching on Flutter-specific bridge objects.
///
/// Note: `JsBridge.postMessage` itself is always available from document-start
/// (injected by the Flutter JavaScriptChannel infrastructure), so H5 can use
/// raw `postMessage` calls at any time without waiting for [adapterJs].
abstract class Host4JsBridgeAdapter {
  const Host4JsBridgeAdapter();

  /// Optional JS code for page-specific compatibility.
  ///
  /// Must produce a self-contained IIFE. New pages usually don't need to define
  /// named methods here because the generic bridge handles arbitrary method
  /// names. Example:
  /// ```javascript
  /// (function() {
  ///   var ch = window.JsBridge;
  ///   window.JsBridge = {
  ///     setToken: function(p) {
  ///       ch.postMessage(JSON.stringify({method:'setToken', payload: p}));
  ///     },
  ///   };
  /// })();
  /// ```
  String get adapterJs;

  /// Called when H5 sends a message via `JsBridge.postMessage`.
  ///
  /// [method] is the value of the `method` field in the JSON payload.
  /// [payload] is the `payload` field value (String, Map, int, or null).
  void onMessage(String method, dynamic payload);
}
