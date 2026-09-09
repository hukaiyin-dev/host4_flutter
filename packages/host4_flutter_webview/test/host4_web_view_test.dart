import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_webview/host4_flutter_webview.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeWebViewPlatform platform;
  WebViewPlatform? previousPlatform;

  setUp(() {
    previousPlatform = WebViewPlatform.instance;
    platform = _FakeWebViewPlatform();
    WebViewPlatform.instance = platform;
  });

  tearDown(() {
    final previous = previousPlatform;
    if (previous != null) {
      WebViewPlatform.instance = previous;
    }
  });

  testWidgets(
    'keeps the native view mounted across failed and successful retries',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Host4WebView(
            initialUrl: 'https://example.com/login',
            showProgressBar: false,
            copy: Host4WebViewCopy(
              loadFailed: '页面加载失败',
              retry: '重试',
              errorCodeLabel: '错误码',
            ),
          ),
        ),
      );

      expect(find.byKey(_FakePlatformWebViewWidget.surfaceKey), findsOneWidget);
      expect(platform.controller.loadRequestCount, 1);
      expect(platform.widgetCreationCount, 1);

      platform.controller.emitError();
      await tester.pump();

      expect(find.text('页面加载失败'), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);
      // The regression is the platform view disappearing when the error page
      // is shown. It must remain in the tree behind the actionable overlay.
      expect(find.byKey(_FakePlatformWebViewWidget.surfaceKey), findsOneWidget);

      // An offline retry should return to the same error page, not a blank
      // route, and the native view must still be the same mounted surface.
      // The retry must re-request the original URL: reload() would reload the
      // blank (about:blank) current page instead, black-screening the route.
      await tester.tap(find.text('重试'));
      await tester.pump();
      expect(find.text('页面加载失败'), findsOneWidget);
      expect(platform.controller.loadRequestCount, 2);
      expect(
        platform.controller.lastRequestedUri,
        Uri.parse('https://example.com/login'),
      );
      expect(platform.controller.reloadCount, 0);
      expect(find.byKey(_FakePlatformWebViewWidget.surfaceKey), findsOneWidget);

      platform.controller.emitError();
      await tester.pump();
      expect(find.text('页面加载失败'), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);
      expect(find.byKey(_FakePlatformWebViewWidget.surfaceKey), findsOneWidget);
      expect(platform.widgetCreationCount, 1);

      // Once the network is available, the same retry can complete normally.
      await tester.tap(find.text('重试'));
      await tester.pump();
      expect(find.text('页面加载失败'), findsOneWidget);
      platform.controller.emitPageStarted();
      platform.controller.emitPageFinished();
      await tester.pump();

      expect(platform.controller.loadRequestCount, 3);
      expect(platform.controller.reloadCount, 0);
      expect(find.text('页面加载失败'), findsNothing);
      expect(find.byKey(_FakePlatformWebViewWidget.surfaceKey), findsOneWidget);
      expect(platform.widgetCreationCount, 1);
    },
  );

  testWidgets('retries the Flutter asset and preserves the ready callback', (
    WidgetTester tester,
  ) async {
    var readyCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Host4WebView.asset(
          initialAssetPath: 'assets/index.html',
          showProgressBar: false,
          copy: const Host4WebViewCopy(
            loadFailed: 'Asset failed',
            retry: 'Try asset again',
            errorCodeLabel: 'Code',
          ),
          onControllerReady: (_) {
            expect(
              find.byKey(_FakePlatformWebViewWidget.surfaceKey),
              findsOneWidget,
            );
            readyCount++;
          },
        ),
      ),
    );

    expect(readyCount, 1);
    expect(platform.controller.loadAssetCount, 1);
    expect(platform.controller.lastAssetPath, 'assets/index.html');
    expect(platform.controller.loadRequestCount, 0);

    platform.controller.emitError();
    await tester.pump();
    expect(find.text('Asset failed'), findsOneWidget);
    await tester.tap(find.text('Try asset again'));
    await tester.pump();

    expect(platform.controller.loadAssetCount, 2);
    expect(platform.controller.lastAssetPath, 'assets/index.html');
    expect(platform.controller.loadRequestCount, 0);
    expect(platform.controller.reloadCount, 0);
    platform.controller.emitPageStarted();
    platform.controller.emitPageFinished();
    await tester.pump();
    expect(find.text('Asset failed'), findsNothing);
    expect(platform.widgetCreationCount, 1);
    expect(readyCount, 1);
  });

  testWidgets('shows an actionable error when loadRequest itself fails', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Host4WebView(
          initialUrl: 'https://example.com/login',
          showProgressBar: false,
          copy: Host4WebViewCopy(
            loadFailed: '页面加载失败',
            retry: '重试',
            errorCodeLabel: '错误码',
          ),
        ),
      ),
    );

    platform.controller.emitError();
    await tester.pump();
    platform.controller.loadRequestFailure = StateError('native load failed');

    await tester.tap(find.text('重试'));
    await tester.pump();

    expect(find.text('页面加载失败'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
    expect(find.byKey(_FakePlatformWebViewWidget.surfaceKey), findsOneWidget);
  });

  testWidgets('localizes the error page for English',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        supportedLocales: <Locale>[Locale('en')],
        home: Host4WebView(
          initialUrl: 'https://example.com/login',
          showProgressBar: false,
        ),
      ),
    );

    platform.controller.emitError();
    await tester.pump();

    expect(find.text('Failed to load page'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('页面加载失败'), findsNothing);
    expect(find.text('重试'), findsNothing);
    expect(
      find.text('offline (Error code: -1009)'),
      findsOneWidget,
    );
  });
}

class _FakeWebViewPlatform extends WebViewPlatform {
  late final _FakeWebViewController controller;
  int widgetCreationCount = 0;

  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    controller = _FakeWebViewController(params);
    return controller;
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) {
    return _FakeNavigationDelegate(params);
  }

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
    widgetCreationCount++;
    return _FakePlatformWebViewWidget(params);
  }
}

class _FakeWebViewController extends PlatformWebViewController {
  _FakeWebViewController(PlatformWebViewControllerCreationParams params)
      : super.implementation(params);

  _FakeNavigationDelegate? navigationDelegate;
  int loadRequestCount = 0;
  int reloadCount = 0;
  int loadAssetCount = 0;
  String? lastAssetPath;
  Uri? lastRequestedUri;
  Object? loadRequestFailure;

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setBackgroundColor(Color color) async {}

  @override
  Future<void> addJavaScriptChannel(
    JavaScriptChannelParams javaScriptChannelParams,
  ) async {}

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {
    navigationDelegate = handler as _FakeNavigationDelegate;
  }

  @override
  Future<void> loadRequest(LoadRequestParams params) async {
    loadRequestCount++;
    lastRequestedUri = params.uri;
    final failure = loadRequestFailure;
    if (failure != null) {
      throw failure;
    }
  }

  @override
  Future<void> loadFlutterAsset(String key) async {
    loadAssetCount++;
    lastAssetPath = key;
  }

  @override
  Future<void> reload() async {
    reloadCount++;
  }

  @override
  Future<void> runJavaScript(String javaScript) async {}

  @override
  Future<String?> getTitle() async => null;

  @override
  Future<bool> canGoBack() async => false;

  void emitError() {
    navigationDelegate?.onWebResourceErrorCallback?.call(
      const WebResourceError(
        errorCode: -1009,
        description: 'offline',
        isForMainFrame: true,
      ),
    );
  }

  void emitPageStarted() {
    navigationDelegate?.onPageStartedCallback
        ?.call('https://example.com/login');
  }

  void emitPageFinished() {
    navigationDelegate?.onPageFinishedCallback
        ?.call('https://example.com/login');
  }
}

class _FakeNavigationDelegate extends PlatformNavigationDelegate {
  _FakeNavigationDelegate(PlatformNavigationDelegateCreationParams params)
      : super.implementation(params);

  PageEventCallback? onPageStartedCallback;
  PageEventCallback? onPageFinishedCallback;
  ProgressCallback? onProgressCallback;
  WebResourceErrorCallback? onWebResourceErrorCallback;
  NavigationRequestCallback? onNavigationRequestCallback;

  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async {
    onPageStartedCallback = onPageStarted;
  }

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {
    onPageFinishedCallback = onPageFinished;
  }

  @override
  Future<void> setOnProgress(ProgressCallback onProgress) async {
    onProgressCallback = onProgress;
  }

  @override
  Future<void> setOnWebResourceError(
    WebResourceErrorCallback onWebResourceError,
  ) async {
    onWebResourceErrorCallback = onWebResourceError;
  }

  @override
  Future<void> setOnNavigationRequest(
    NavigationRequestCallback onNavigationRequest,
  ) async {
    onNavigationRequestCallback = onNavigationRequest;
  }
}

class _FakePlatformWebViewWidget extends PlatformWebViewWidget {
  _FakePlatformWebViewWidget(PlatformWebViewWidgetCreationParams params)
      : super.implementation(params);

  static const ValueKey<String> surfaceKey = ValueKey<String>(
    'fake-webview-surface',
  );

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(key: surfaceKey, color: Colors.transparent);
  }
}
