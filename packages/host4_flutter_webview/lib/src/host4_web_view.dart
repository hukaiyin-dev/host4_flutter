import 'dart:convert';

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
    this.onControllerReady,
    this.onPageStarted,
    this.onPageFinished,
    this.onNavigationRequest,
    this.onWebResourceError,
  });

  /// The URL to load on launch.
  final String initialUrl;

  /// Optional JS bridge adapter. When provided, a `JsBridge` JavaScript
  /// channel is registered and [Host4JsBridgeAdapter.adapterJs] is injected
  /// after each page load.
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

  @override
  void initState() {
    super.initState();
    _controller = _buildController();
    _webController = Host4WebController(_controller);
    widget.onControllerReady?.call(_webController);
    _controller.loadRequest(Uri.parse(widget.initialUrl));
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
    }

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
              _errorMessage =
                  '${error.description} (错误码: ${error.errorCode})';
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
      bridge.onMessage(method, decoded['payload']);
    } catch (_) {}
  }

  void _injectAdapterJs() {
    final adapter = widget.bridge;
    if (adapter == null) return;
    _controller.runJavaScript(adapter.adapterJs);
  }

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
      canPop: false,
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
