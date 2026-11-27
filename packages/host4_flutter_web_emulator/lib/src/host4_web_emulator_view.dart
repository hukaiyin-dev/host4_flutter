import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:host4_flutter_webview/host4_flutter_webview.dart';

import 'host4_web_emulator_assets.dart';
import 'host4_web_emulator_controller.dart';
import 'host4_web_emulator_core_cache.dart';
import 'host4_web_emulator_launch_config.dart';

class Host4WebEmulatorView extends StatefulWidget {
  const Host4WebEmulatorView({
    super.key,
    required this.launchConfig,
    this.coreCacheDirectory,
    this.onControllerReady,
    this.onBridgeMessage,
    this.onWebError,
  });

  final Host4WebEmulatorLaunchConfig launchConfig;

  /// 提供此目录时，View 内部管理 core 缓存：首次从网络下载并持久化，
  /// 后续启动直接从缓存读取。缓存数据通过 base64 注入 WebView，
  /// 不依赖 file URL（WebView 沙盒不允许读取外部目录）。
  final Directory? coreCacheDirectory;

  final void Function(Host4WebEmulatorController controller)? onControllerReady;
  final void Function(String method, dynamic payload)? onBridgeMessage;
  final void Function(Object error)? onWebError;

  @override
  State<Host4WebEmulatorView> createState() => _Host4WebEmulatorViewState();
}

class _Host4WebEmulatorViewState extends State<Host4WebEmulatorView> {
  Host4WebEmulatorController? _controller;
  bool _pageFinished = false;
  bool _launched = false;

  void _tryLaunch() {
    final controller = _controller;
    if (controller == null || !_pageFinished || _launched) return;
    _launched = true;
    unawaited(_launch(controller));
  }

  Future<void> _launch(Host4WebEmulatorController controller) async {
    try {
      ResolvedCoreData? coreData;
      final viewerOnly = widget.launchConfig.webRtcPreviewRole == 'viewer';
      final cacheDir = widget.coreCacheDirectory;
      final probeCoreArtifact =
          !viewerOnly &&
              widget.launchConfig.outputProbeEnabled &&
              !widget.launchConfig.externalWebGlPreviewEnabled
          ? _videoRefreshProbeArtifacts[widget.launchConfig.system.core.name]
          : null;
      if (probeCoreArtifact != null) {
        // These local video-refresh probe packages are generated from the
        // same patched RetroArch frontend.  The callback is at the standard
        // libretro video boundary, before WebGL draws an intermediate texture.
        final js = await rootBundle.load(
          'packages/host4_flutter_web_emulator/assets/emulator/probe/$probeCoreArtifact.js',
        );
        final wasm = await rootBundle.load(
          'packages/host4_flutter_web_emulator/assets/emulator/probe/$probeCoreArtifact.wasm',
        );
        coreData = ResolvedCoreData(
          jsBase64: base64Encode(
            js.buffer.asUint8List(js.offsetInBytes, js.lengthInBytes),
          ),
          wasmBase64: base64Encode(
            wasm.buffer.asUint8List(wasm.offsetInBytes, wasm.lengthInBytes),
          ),
        );
      } else if (!viewerOnly && cacheDir != null) {
        final cache = Host4WebEmulatorCoreCache(cacheRoot: cacheDir);
        coreData = await cache.resolve(widget.launchConfig.system.core);
      }
      await controller.launch(widget.launchConfig, resolvedCoreData: coreData);
    } catch (error) {
      widget.onWebError?.call(error);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Host4WebView.asset(
      initialAssetPath: Host4WebEmulatorAssets.indexHtml,
      bridge: _Host4WebEmulatorBridgeAdapter(
        () => _controller,
        widget.onBridgeMessage,
      ),
      backgroundColor: Colors.black,
      showProgressBar: false,
      // The local WebRTC viewer has no user gesture before its remote track
      // arrives. WKWebView otherwise rejects `video.play()` even for the
      // muted inline receiver element.
      allowAutoplayAudio: widget.launchConfig.webRtcPreviewRole == 'viewer',
      allowRoutePopGesture: true,
      onControllerReady: (controller) {
        _controller?.dispose();
        final emulatorController = Host4WebEmulatorController(controller);
        _controller = emulatorController;
        widget.onControllerReady?.call(emulatorController);
        _tryLaunch();
      },
      onPageFinished: (_) {
        _pageFinished = true;
        _tryLaunch();
      },
      onWebResourceError: (error) {
        widget.onWebError?.call(error);
        return false;
      },
    );
  }
}

/// Supported local video-refresh probe package for each product core.
///
/// Keeping this mapping explicit means an unsupported core falls back to the
/// normal pinned artifact instead of accidentally receiving an unrelated
/// emulator binary.
const _videoRefreshProbeArtifacts = <String, String>{
  'fceumm': 'fceumm_libretro',
  'genesis_plus_gx': 'genesis_plus_gx_libretro',
  'mgba': 'mgba_libretro',
  'snes9x': 'snes9x_libretro',
};

class _Host4WebEmulatorBridgeAdapter extends Host4JsBridgeAdapter {
  const _Host4WebEmulatorBridgeAdapter(this._controller, this._onMessage);

  final Host4WebEmulatorController? Function() _controller;
  final void Function(String method, dynamic payload)? _onMessage;

  @override
  String get adapterJs => '';

  @override
  void onMessage(String method, dynamic payload) {
    _controller()?.handleBridgeMessage(method, payload);
    _onMessage?.call(method, payload);
  }
}
