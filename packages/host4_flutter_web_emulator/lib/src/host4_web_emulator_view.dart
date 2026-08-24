import 'dart:async';

import 'package:flutter/material.dart';
import 'package:host4_flutter_webview/host4_flutter_webview.dart';

import 'host4_web_emulator_assets.dart';
import 'host4_web_emulator_controller.dart';
import 'host4_web_emulator_launch_config.dart';

class Host4WebEmulatorView extends StatefulWidget {
  const Host4WebEmulatorView({
    super.key,
    required this.launchConfig,
    this.onControllerReady,
    this.onBridgeMessage,
    this.onWebError,
  });

  final Host4WebEmulatorLaunchConfig launchConfig;
  final void Function(Host4WebEmulatorController controller)? onControllerReady;
  final void Function(String method, dynamic payload)? onBridgeMessage;
  final void Function(Object error)? onWebError;

  @override
  State<Host4WebEmulatorView> createState() => _Host4WebEmulatorViewState();
}

class _Host4WebEmulatorViewState extends State<Host4WebEmulatorView> {
  Host4WebEmulatorController? _controller;
  bool _launched = false;

  Future<void> _launch(Host4WebEmulatorController controller) async {
    try {
      await controller.launch(widget.launchConfig);
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
      allowRoutePopGesture: true,
      onControllerReady: (controller) {
        _controller?.dispose();
        final emulatorController = Host4WebEmulatorController(controller);
        _controller = emulatorController;
        widget.onControllerReady?.call(emulatorController);
      },
      onPageFinished: (_) {
        final controller = _controller;
        if (controller == null || _launched) return;
        _launched = true;
        unawaited(_launch(controller));
      },
      onWebResourceError: (error) {
        widget.onWebError?.call(error);
        return false;
      },
    );
  }
}

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
