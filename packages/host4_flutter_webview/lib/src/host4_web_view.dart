import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'host4_js_bridge_adapter.dart';
import 'host4_web_controller.dart';
import 'host4_web_view_copy.dart';

/// A WebView widget with progress, error handling, and optional JS bridge support.
///
/// Usage:
/// ```dart
/// Host4WebView(
///   initialUrl: 'https://example.com',
///   bridge: MyJsBridgeAdapter(onToken: _handleToken),
///   onControllerReady: (controller) {
///     _controller = controller;
///   },
/// )
/// ```
class Host4WebView extends StatefulWidget {
  const Host4WebView({
    super.key,
    required this.initialUrl,
    this.bridge,
    this.backgroundColor,
    this.loadingOverlayBuilder,
    this.showProgressBar = true,
    this.needTitleBar = false,
    this.title,
    this.enableZoom = false,
    this.userAgent,
    this.allowRoutePopGesture = false,
    this.onControllerReady,
    this.onPageStarted,
    this.onPageFinished,
    this.onNavigationRequest,
    this.onWebResourceError,
    this.copy,
  });

  /// The URL to load on launch.
  final String initialUrl;

  /// Optional JS bridge adapter. When provided, `JsBridge` / `NativeBridge`
  /// JavaScript channels are registered and a generic `JsBridge.method(arg)`
  /// adapter is injected so H5 can call Flutter like Android JavascriptInterface.
  final Host4JsBridgeAdapter? bridge;

  /// Background color shown before the first page starts loading.
  /// Defaults to [Colors.black] when null.
  final Color? backgroundColor;

  /// Optional overlay shown on top of the WebView while the page is loading.
  /// Removed when [onPageFinished] fires. Use this to hide the WKWebView
  /// platform-view frame animation on iOS.
  final Widget Function(BuildContext context)? loadingOverlayBuilder;

  /// Whether to show a linear progress indicator while the page is loading.
  final bool showProgressBar;

  /// Whether to show a title bar (AppBar) above the WebView.
  final bool needTitleBar;

  /// AppBar title. Defaults to the page title reported by the WebView.
  final String? title;

  /// Whether the user can pinch-to-zoom. Defaults to false.
  final bool enableZoom;

  /// Custom User-Agent string. Uses the platform default when null.
  final String? userAgent;

  /// Allows the host route to handle system pop gestures directly.
  ///
  /// Keep this disabled for ordinary web pages so system back can first walk
  /// web history. Enable it for full-screen pages such as login where native
  /// edge-swipe should leave the page.
  final bool allowRoutePopGesture;

  /// Called once the [Host4WebController] is ready, before the first URL loads.
  final void Function(Host4WebController controller)? onControllerReady;

  /// Called when a page starts loading.
  final void Function(String url)? onPageStarted;

  /// Called when a page finishes loading.
  final void Function(String url)? onPageFinished;

  /// Called for each navigation request. Return true to allow, false to block.
  /// When null, only `http` and `https` schemes are allowed.
  final bool Function(Uri url)? onNavigationRequest;

  /// Called when a main-frame resource load error occurs. Return true if
  /// handled; false shows the built-in error page.
  final bool Function(WebResourceError error)? onWebResourceError;

  /// Optional override for the built-in error page strings.
  ///
  /// When null, strings follow [Localizations.localeOf].
  final Host4WebViewCopy? copy;

  @override
  State<Host4WebView> createState() => _Host4WebViewState();
}

class _Host4WebViewState extends State<Host4WebView> {
  late final WebViewController _controller;
  late final WebViewWidget _webViewWidget;
  late final Host4WebController _webController;

  double _progress = 0;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorDescription = '';
  int? _errorCode;
  String _pageTitle = '';
  late final Uri _initialUri;

  @override
  void initState() {
    super.initState();
    _controller = _buildController();
    _webController = Host4WebController(_controller);
    // Keep one widget/controller pair as well as keeping it mounted below.
    // This avoids asking the platform implementation to recreate its native
    // view on every state change (progress, errors, and retries).
    _webViewWidget = WebViewWidget(controller: _controller);
    // Initialize the widget before notifying consumers. A consumer is allowed
    // to synchronously rebuild from onControllerReady, and that rebuild must
    // not observe an uninitialized late field.
    widget.onControllerReady?.call(_webController);
    _initialUri = Uri.parse(widget.initialUrl);
    debugPrint(
      '[Host4WebView] loadRequest uri=$_initialUri '
      'scheme=${_initialUri.scheme} hasScheme=${_initialUri.hasScheme}',
    );
    try {
      _controller.loadRequest(_initialUri);
    } catch (e, st) {
      debugPrint('[Host4WebView] loadRequest failed: $e\n$st');
    }
  }

  WebViewController _buildController() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(widget.backgroundColor ?? Colors.black);

    if (widget.userAgent != null) {
      controller.setUserAgent(widget.userAgent);
    }

    if (!widget.enableZoom && controller.platform is AndroidWebViewController) {
      (controller.platform as AndroidWebViewController).enableZoom(false);
    }

    if (widget.bridge != null) {
      controller.addJavaScriptChannel(
        'JsBridge',
        onMessageReceived: _onJsMessage,
      );
      controller.addJavaScriptChannel(
        'NativeBridge',
        onMessageReceived: _onJsMessage,
      );
    }

    controller.addJavaScriptChannel(
      '_FlutterJsLog',
      onMessageReceived: (msg) => debugPrint('[JS] ${msg.message}'),
    );

    controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (url) {
          if (!mounted) return;
          setState(() {
            _isLoading = true;
            _progress = 0;
            _hasError = false;
          });
          // 尽早注入 adapterJs，确保 H5 任何 JS 运行前 bridge 已就位
          // （Android @JavascriptInterface 在 WebView 创建时即可用，此处对齐该行为）
          _injectAdapterJs();
          widget.onPageStarted?.call(url);
        },
        onPageFinished: (url) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _progress = 1;
          });
          // 再次注入，覆盖页面内部可能重置 window.JsBridge 的情况
          _injectAdapterJs();
          widget.onPageFinished?.call(url);
          _updatePageTitle();
        },
        onProgress: (p) {
          if (!mounted) return;
          setState(() => _progress = p / 100.0);
        },
        onWebResourceError: (error) {
          if (!mounted) return;
          final isMain = error.isForMainFrame ?? true;
          if (!isMain) return;
          final handled = widget.onWebResourceError?.call(error) ?? false;
          if (!handled) {
            setState(() {
              _hasError = true;
              _errorDescription = error.description;
              _errorCode = error.errorCode;
              _isLoading = false;
            });
          }
        },
        onNavigationRequest: (req) {
          final uri = Uri.tryParse(req.url);
          if (uri == null) return NavigationDecision.prevent;
          final custom = widget.onNavigationRequest?.call(uri);
          if (custom != null) {
            return custom
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          }
          return (uri.scheme == 'http' || uri.scheme == 'https')
              ? NavigationDecision.navigate
              : NavigationDecision.prevent;
        },
      ),
    );

    return controller;
  }

  void _onJsMessage(JavaScriptMessage message) {
    final bridge = widget.bridge;
    if (bridge == null) return;
    try {
      final decoded = jsonDecode(message.message);
      if (decoded is! Map) return;
      final method = decoded['method']?.toString() ?? '';
      if (method.isEmpty) return;
      // 兼容两种字段名：adapterJs 包装层用 `payload`，H5 直接调用时用 `params`
      final payload = decoded.containsKey('payload')
          ? decoded['payload']
          : decoded['params'];
      bridge.onMessage(method, payload);
    } catch (_) {}
  }

  void _injectAdapterJs() {
    final adapter = widget.bridge;
    if (adapter == null) return;
    _controller.runJavaScript(_kGenericBridgeAdapterJs);
    _controller.runJavaScript(adapter.adapterJs);
    if (kDebugMode) {
      _controller.runJavaScript(_kJsDebugSnippet);
    }
  }

  static const String _kGenericBridgeAdapterJs = r'''
(function() {
  var jsChannel = window.__Host4JsBridgeChannel || window.JsBridge;
  var nativeChannel = window.__Host4NativeBridgeChannel || window.NativeBridge;
  if (!jsChannel || typeof jsChannel.postMessage !== 'function') return;

  window.__Host4JsBridgeChannel = jsChannel;
  if (nativeChannel && typeof nativeChannel.postMessage === 'function') {
    window.__Host4NativeBridgeChannel = nativeChannel;
  }

  function send(method, args) {
    var payload = null;
    if (args.length === 1) {
      payload = args[0];
    } else if (args.length > 1) {
      payload = Array.prototype.slice.call(args);
    }
    jsChannel.postMessage(JSON.stringify({ method: String(method), payload: payload }));
  }

  var bridge = new Proxy({
    postMessage: function(message) {
      jsChannel.postMessage(message);
    }
  }, {
    get: function(target, prop) {
      if (prop in target) return target[prop];
      if (typeof prop === 'symbol') return undefined;
      return function() { send(prop, arguments); };
    }
  });

  window.JsBridge = bridge;
  if (nativeChannel && typeof nativeChannel.postMessage === 'function') {
    window.NativeBridge = {
      postMessage: function(message) {
        nativeChannel.postMessage(message);
      }
    };
  }
})();
''';

  static const String _kJsDebugSnippet = r'''
(function() {
  function _log(tag, msg) {
    try { _FlutterJsLog.postMessage('[' + tag + '] ' + msg); } catch(e) {}
  }
  var _origError = console.error.bind(console);
  console.error = function() {
    _origError.apply(console, arguments);
    _log('console.error', Array.prototype.join.call(arguments, ' '));
  };
  var _origWarn = console.warn.bind(console);
  console.warn = function() {
    _origWarn.apply(console, arguments);
    _log('console.warn', Array.prototype.join.call(arguments, ' '));
  };
  window.addEventListener('error', function(e) {
    _log('window.onerror', (e.message || '') + ' @ ' + (e.filename || '') + ':' + (e.lineno || ''));
  });
  window.addEventListener('unhandledrejection', function(e) {
    _log('unhandledrejection', String(e.reason));
  });
  _log('bridge-check', 'JsBridge=' + typeof window.JsBridge + ' NativeBridge=' + typeof window.NativeBridge);
})();
''';

  Future<void> _updatePageTitle() async {
    try {
      final t = await _controller.getTitle();
      if (t != null && t.isNotEmpty && mounted) {
        setState(() => _pageTitle = t);
      }
    } catch (_) {}
  }

  Future<bool> _handleBackNavigation() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.allowRoutePopGesture,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _handleBackNavigation();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: widget.backgroundColor ?? Colors.black,
        resizeToAvoidBottomInset: false,
        appBar: widget.needTitleBar
            ? AppBar(
                title: Text(
                  widget.title ??
                      (_pageTitle.isNotEmpty ? _pageTitle : '加载中...'),
                ),
              )
            : null,
        body: Column(
          children: [
            if (widget.showProgressBar && _isLoading)
              LinearProgressIndicator(value: _progress),
            Expanded(
              key: const ValueKey<String>('host4_webview_content'),
              // Keep the platform view mounted for the entire lifetime of the
              // route.  On iOS, removing a UiKitView and then attaching a new
              // one for the same WKWebView controller can leave the platform
              // view with no surface after reload (a black screen).  Both the
              // loading and error states are therefore overlays instead of
              // alternate branches that replace WebViewWidget.
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _webViewWidget,
                  if (_isLoading && widget.loadingOverlayBuilder != null)
                    widget.loadingOverlayBuilder!(context),
                  if (_hasError) Positioned.fill(child: _buildErrorPage()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPage() {
    final copy = widget.copy ?? Host4WebViewCopy.of(context);
    final detail = copy.errorDetail(
      description: _errorDescription,
      code: _errorCode,
    );
    return Material(
      color: widget.backgroundColor ?? Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                copy.loadFailed,
                key: const ValueKey<String>('host4_webview_error_title'),
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                detail,
                key: const ValueKey<String>('host4_webview_error_detail'),
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                key: const ValueKey<String>('host4_webview_retry'),
                onPressed: _retry,
                icon: const Icon(Icons.refresh),
                label: Text(copy.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _retry() async {
    if (!mounted) return;

    // Show the normal loading state while the existing native WebView starts
    // its new request.  Keeping the controller/view pair intact is important
    // for WKWebView; only the Flutter overlay is changed here.
    setState(() {
      _hasError = false;
      _isLoading = true;
      _progress = 0;
      _errorDescription = '';
      _errorCode = null;
    });

    try {
      // Do not use reload() here: it reloads the WebView's *current* page.
      // After a failed first main-frame load nothing has committed, so the
      // current page is the blank initial surface (about:blank). reload()
      // "succeeds" reloading that blank page, leaving a black screen with
      // neither content nor an error — even after the network recovers.
      // Always re-request the original URL instead.
      await _controller.loadRequest(_initialUri);
    } catch (error, stackTrace) {
      // A platform error should never leave the route with an empty/black
      // surface.  Return to the same actionable error page so the user can
      // retry again (or leave the route).
      debugPrint(
          '[Host4WebView] retry loadRequest failed: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
        _errorDescription = '$error';
        _errorCode = null;
      });
    }
  }
}
