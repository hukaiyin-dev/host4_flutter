/// Abstract adapter that defines the JS bridge protocol for a specific H5 page.
///
/// Implement this class to describe the bridge between Flutter and H5:
/// - [adapterJs]: the JS snippet injected into the page that maps the H5-side
///   named method calls (e.g. `JsBridge.setToken(token)`) to
///   `JsBridge.postMessage(JSON.stringify({method, payload}))`.
/// - [onMessage]: called when H5 sends a message through the bridge.
///
/// Injection timing: [adapterJs] is injected on `onPageFinished`, which means
/// the page content is fully loaded before the named method wrappers are
/// available. For pages where H5 only calls bridge methods in response to user
/// interaction (login, settings, etc.), this is sufficient. If H5 calls bridge
/// methods automatically on page load, coordinate with the H5 team to ensure
/// calls are deferred or guarded.
///
/// Note: `JsBridge.postMessage` itself is always available from document-start
/// (injected by the Flutter JavaScriptChannel infrastructure), so H5 can use
/// raw `postMessage` calls at any time without waiting for [adapterJs].
abstract class Host4JsBridgeAdapter {
  const Host4JsBridgeAdapter();

  /// JS code injected after page load to expose named bridge methods on
  /// `window.JsBridge`.
  ///
  /// Must produce a self-contained IIFE. Example:
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
