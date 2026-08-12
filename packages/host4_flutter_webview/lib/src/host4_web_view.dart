import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'host4_js_bridge_adapter.dart';
import 'host4_web_controller.dart';

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

  @override
  State<Host4WebView> createState() => _Host4WebViewState();
}

class _Host4WebViewState extends State<Host4WebView> {
  late final WebViewController _controller;
  late final Host4WebController _webController;

  double _progress = 0;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _pageTitle = '';
  Timer? _bridgeReadinessTimer;
  bool _bridgeRepairInFlight = false;

  @override
  void initState() {
    super.initState();
    _controller = _buildController();
    _webController = Host4WebController(_controller);
    widget.onControllerReady?.call(_webController);
    unawaited(_initializeAndLoad());
  }

  @override
  void dispose() {
    _stopBridgeReadinessGuard();
    super.dispose();
  }

  Future<void> _initializeAndLoad() async {
    await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await _controller.setBackgroundColor(
      widget.backgroundColor ?? Colors.black,
    );

    if (widget.userAgent != null) {
      await _controller.setUserAgent(widget.userAgent);
    }

    if (!widget.enableZoom &&
        _controller.platform is AndroidWebViewController) {
      await (_controller.platform as AndroidWebViewController).enableZoom(
        false,
      );
    }

    if (widget.bridge != null) {
      await _controller.addJavaScriptChannel(
        'JsBridge',
        onMessageReceived: _onJsMessage,
      );
      await _controller.addJavaScriptChannel(
        'NativeBridge',
        onMessageReceived: _onJsMessage,
      );
    }

    await _controller.addJavaScriptChannel(
      '_FlutterJsLog',
      onMessageReceived: (msg) => debugPrint('[JS] ${msg.message}'),
    );

    await _controller.setNavigationDelegate(_navigationDelegate());

    final uri = Uri.parse(widget.initialUrl);
    debugPrint(
      '[Host4WebView] loadRequest uri=$uri scheme=${uri.scheme} hasScheme=${uri.hasScheme}',
    );
    try {
      await _controller.loadRequest(uri);
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

    return WebViewController.fromPlatformCreationParams(params);
  }

  NavigationDelegate _navigationDelegate() => NavigationDelegate(
    onPageStarted: (url) {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _progress = 0;
        _hasError = false;
      });
      // evaluateJavascript 在重定向期间可能落入旧 document，因此持续检查
      // 当前 document，直到主页面完成加载。
      _startBridgeReadinessGuard();
      widget.onPageStarted?.call(url);
    },
    onPageFinished: (url) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _progress = 1;
      });
      // 最终补注入完成后再停止守护，覆盖最后一次 document 切换。
      unawaited(_finishBridgeReadinessGuard());
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
      _stopBridgeReadinessGuard();
      final handled = widget.onWebResourceError?.call(error) ?? false;
      if (!handled) {
        setState(() {
          _hasError = true;
          _errorMessage = '${error.description} (错误码: ${error.errorCode})';
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
  );

  void _startBridgeReadinessGuard() {
    if (widget.bridge == null || _bridgeReadinessTimer != null) return;
    unawaited(_repairBridgeInCurrentDocument());
    _bridgeReadinessTimer = Timer.periodic(
      const Duration(milliseconds: 25),
      (_) => unawaited(_repairBridgeInCurrentDocument()),
    );
  }

  Future<void> _finishBridgeReadinessGuard() async {
    while (_bridgeRepairInFlight) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    await _repairBridgeInCurrentDocument(force: true);
    _stopBridgeReadinessGuard();
  }

  void _stopBridgeReadinessGuard() {
    _bridgeReadinessTimer?.cancel();
    _bridgeReadinessTimer = null;
  }

  Future<void> _repairBridgeInCurrentDocument({bool force = false}) async {
    if (_bridgeRepairInFlight || widget.bridge == null) return;
    _bridgeRepairInFlight = true;
    try {
      if (force || !await _isBridgeReadyInCurrentDocument()) {
        await _injectAdapterJs();
      }
    } catch (_) {
      // Navigation can replace the document while JavaScript is evaluated.
      // The next guard tick retries against the active document.
    } finally {
      _bridgeRepairInFlight = false;
    }
  }

  Future<bool> _isBridgeReadyInCurrentDocument() async {
    final result = await _controller.runJavaScriptReturningResult(r'''
(function() {
  return window.__Host4BridgeAdapterReady === true;
})()
''');
    return result == true || result.toString() == 'true';
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

  Future<void> _injectAdapterJs() async {
    final adapter = widget.bridge;
    if (adapter == null) return;
    await _controller.runJavaScript(
      '\n$_kGenericBridgeAdapterJs\n${adapter.adapterJs}\n'
      'window.__Host4BridgeAdapterReady = true;',
    );
    if (kDebugMode) {
      await _controller.runJavaScript(_kJsDebugSnippet);
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
              child: _hasError
                  ? _buildErrorPage()
                  : Stack(
                      children: [
                        WebViewWidget(controller: _controller),
                        if (_isLoading && widget.loadingOverlayBuilder != null)
                          widget.loadingOverlayBuilder!(context),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('页面加载失败', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _hasError = false);
                _controller.reload();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}
