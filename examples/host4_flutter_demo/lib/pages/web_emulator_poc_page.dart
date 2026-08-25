import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:host4_flutter_crypto/host4_flutter_crypto.dart';
import 'package:host4_flutter_emulator_ui/host4_flutter_emulator_ui.dart';
import 'package:host4_flutter_log/host4_flutter_log.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';
import 'package:host4_flutter_web_emulator/host4_flutter_web_emulator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'web_emulator/web_emulator_layout_preference_store.dart';
import 'web_emulator/web_emulator_overlay_layers.dart';
import 'web_emulator/web_emulator_save_repository.dart';
import 'web_emulator/web_emulator_session_actions.dart';

enum _WebEmulatorOverlay { none, menu, saves, keyLocator }

final _layoutLog = Host4Logger('WebEmulatorLayout');

class WebEmulatorPocPage extends StatefulWidget {
  const WebEmulatorPocPage({super.key});

  @override
  State<WebEmulatorPocPage> createState() => _WebEmulatorPocPageState();
}

class _WebEmulatorPocPageState extends State<WebEmulatorPocPage>
    with WidgetsBindingObserver {
  Host4WebEmulatorLaunchConfig? _launchConfig;
  Host4WebEmulatorController? _controller;
  WebEmulatorSaveRepository? _repository;
  WebEmulatorSessionActions? _actions;
  String? _gameKey;
  String _status = '请选择一个 .gb / .gbc / .gba / .zip ROM。';
  bool _loadingRom = false;
  bool _launched = false;
  bool _sramSaveInFlight = false;
  Host4EmulatorControlLayoutStyle _layoutStyle =
      Host4EmulatorControlLayoutStyle.silicone;
  late final WebEmulatorLayoutPreferenceCoordinator _layoutPreferences;
  _WebEmulatorOverlay _overlay = _WebEmulatorOverlay.none;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _layoutPreferences = WebEmulatorLayoutPreferenceCoordinator(
      SharedPreferences.getInstance()
          .then<WebEmulatorLayoutPreferencePersistence>(
            WebEmulatorLayoutPreferenceStore.new,
          ),
      currentStyle: _layoutStyle,
      onLog: _layoutLog.debug,
    );
    unawaited(_loadLayoutStyle());
  }

  Future<void> _loadLayoutStyle() async {
    try {
      final style = await _layoutPreferences.load();
      if (mounted && style != null) setState(() => _layoutStyle = style);
    } catch (error, stackTrace) {
      _layoutLog.error(
        'preference_load_failed; keeping=${_layoutStyle.name}',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _setLayoutStyle(Host4EmulatorControlLayoutStyle style) async {
    if (_layoutStyle != style) setState(() => _layoutStyle = style);
    try {
      await _layoutPreferences.select(style);
    } catch (error, stackTrace) {
      _layoutLog.error(
        'selection_save_failed selected=${style.name}',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _setLayoutStyleFromMenu(
    Host4EmulatorControlLayoutStyle style,
  ) async {
    await _setLayoutStyle(style);
    await _actions?.resume();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_persistSram(reportErrors: false));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_persistSram(reportErrors: false));
    super.dispose();
  }

  Future<void> _pickRom() async {
    setState(() {
      _loadingRom = true;
      _status = '正在读取 ROM...';
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const <String>['gb', 'gbc', 'gba', 'zip'],
        withData: true,
      );
      final file = result?.files.single;
      if (file == null) {
        if (mounted) {
          setState(() {
            _loadingRom = false;
            _status = '已取消选择。';
          });
        }
        return;
      }

      final path = file.path;
      final bytes =
          file.bytes ??
          (path == null
              ? throw StateError('无法读取所选 ROM。')
              : await File(path).readAsBytes());
      var system = Host4WebEmulatorSystem.tryFromRomFileName(file.name);
      if (system == null) {
        if (!Host4WebEmulatorSystem.isZipFile(file.name)) {
          throw ArgumentError('不支持的文件类型：${file.name}');
        }
        if (!mounted) return;
        system = await _pickSystemForZip();
        if (system == null) {
          if (mounted) {
            setState(() {
              _loadingRom = false;
              _status = '已取消选择平台。';
            });
          }
          return;
        }
      }

      await _shutdownCurrentSession();
      final gameKey = sha256OfBytes(bytes);
      final documents = await getApplicationDocumentsDirectory();
      final repository = WebEmulatorSaveRepository(
        rootDirectory: Directory('${documents.path}/host4_web_emulator'),
        gameKey: gameKey,
      );
      final sram = await repository.readSram();
      final config = Host4WebEmulatorLaunchConfig(
        system: system,
        romName: file.name,
        romBase64: base64Encode(bytes),
        sramBase64: sram == null ? null : base64Encode(sram),
      );

      if (!mounted) return;
      setState(() {
        _launchConfig = config;
        _repository = repository;
        _gameKey = gameKey;
        _controller = null;
        _actions = null;
        _loadingRom = false;
        _launched = false;
        _overlay = _WebEmulatorOverlay.none;
        _status =
            '已加载 ${file.name}，系统 ${system!.name.toUpperCase()}，等待 WebView 启动。';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingRom = false;
        _status = '读取失败：$error';
      });
    }
  }

  Future<Host4WebEmulatorSystem?> _pickSystemForZip() {
    return showDialog<Host4WebEmulatorSystem>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('ZIP 内的 ROM 是什么平台？'),
        children: <Widget>[
          for (final system in Host4WebEmulatorSystem.values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, system),
              child: Text(system.name.toUpperCase()),
            ),
        ],
      ),
    );
  }

  Future<void> _shutdownCurrentSession() async {
    try {
      await _persistSram(reportErrors: false);
      await _controller?.exit();
    } catch (error) {
      debugPrint('[WebEmulatorDemo] shutdown failed: $error');
    }
  }

  Future<void> _persistSram({required bool reportErrors}) async {
    final actions = _actions;
    if (!_launched || actions == null || _sramSaveInFlight) return;
    _sramSaveInFlight = true;
    try {
      await actions.persistSram();
    } catch (error) {
      debugPrint('[WebEmulatorDemo] SRAM save failed: $error');
      if (reportErrors && mounted) {
        setState(() => _status = 'SRAM 保存失败：$error');
      }
    } finally {
      _sramSaveInFlight = false;
    }
  }

  void _onControllerReady(Host4WebEmulatorController controller) {
    final repository = _repository;
    if (repository == null) return;
    final actions = WebEmulatorSessionActions(
      runtime: Host4WebEmulatorRuntime(controller),
      repository: repository,
      onChanged: _refresh,
      onReturnToGame: _returnToGame,
      onExit: _finishSession,
    );
    if (!mounted) return;
    setState(() {
      _controller = controller;
      _actions = actions;
    });
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _returnToGame() async {
    if (!mounted) return;
    setState(() => _overlay = _WebEmulatorOverlay.none);
  }

  Future<void> _finishSession() async {
    if (!mounted) return;
    setState(() {
      _launchConfig = null;
      _controller = null;
      _repository = null;
      _actions = null;
      _gameKey = null;
      _launched = false;
      _overlay = _WebEmulatorOverlay.none;
      _status = '游戏已退出，请选择 ROM。';
    });
  }

  Future<void> _openMenu() async {
    await _openPausedOverlay(_WebEmulatorOverlay.menu);
  }

  Future<void> _openKeyLocator() async {
    await _openPausedOverlay(_WebEmulatorOverlay.keyLocator);
  }

  Future<void> _openPausedOverlay(_WebEmulatorOverlay overlay) async {
    final controller = _controller;
    if (controller == null || _overlay != _WebEmulatorOverlay.none) return;
    try {
      await controller.pause();
      if (mounted) setState(() => _overlay = overlay);
    } catch (error) {
      if (mounted) setState(() => _status = '暂停失败：$error');
    }
  }

  Future<void> _closeOverlayFromSet() async {
    final actions = _actions;
    if (actions == null) return;
    try {
      await actions.resume();
    } catch (error) {
      if (mounted) setState(() => _status = '恢复失败：$error');
    }
  }

  void _onInput(Host4EmulatorInputEvent event) {
    final controller = _controller;
    if (controller == null) return;
    unawaited(
      controller.keyEvent(event.input, action: event.phase).catchError((error) {
        debugPrint('[WebEmulatorDemo] input failed: $error');
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = _launchConfig;

    // 游戏启动后全屏显示模拟器，匹配 Pantas 行为
    if (_launched && config != null) {
      return _buildEmulator(config);
    }

    // 未启动时显示 ROM 选择 UI + 导航栏
    return _buildRomPicker(config);
  }

  Widget _buildRomPicker(Host4WebEmulatorLaunchConfig? config) {
    final theme = context.host4Theme;
    return Host4PageScaffold(
      useSafeArea: false,
      body: Column(
        children: <Widget>[
          SafeArea(
            bottom: false,
            child: Host4NavigationBar(
              title: 'Web 模拟器',
              subtitle: '选择本地 GB / GBC / GBA ROM 并在 WebView 启动',
              leading: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: theme.components.navigationBar.icon,
                  size: 20,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              theme.spacing.page,
              theme.spacing.md,
              theme.spacing.page,
              theme.spacing.md,
            ),
            child: Host4Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Host4Text(_status, colorRole: Host4TextColorRole.secondary),
                  SizedBox(height: theme.spacing.md),
                  WebEmulatorLayoutSelector(
                    value: _layoutStyle,
                    onChanged: (style) => unawaited(_setLayoutStyle(style)),
                  ),
                  SizedBox(height: theme.spacing.md),
                  Host4Button(
                    label: _loadingRom ? '读取中...' : '选择 ROM',
                    expanded: true,
                    onPressed: _loadingRom ? null : _pickRom,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: config == null
                ? const SizedBox.shrink()
                : _buildEmulator(config),
          ),
        ],
      ),
    );
  }

  Widget _buildEmulator(Host4WebEmulatorLaunchConfig config) {
    final actions = _actions;
    final repository = _repository;
    Widget? overlay;
    if (_overlay == _WebEmulatorOverlay.menu && actions != null) {
      overlay = Host4EmulatorMenuOverlay(
        actions: actions,
        layoutStyle: _layoutStyle,
        onLayoutChanged: _setLayoutStyleFromMenu,
        onOpenSaveManager: () {
          setState(() => _overlay = _WebEmulatorOverlay.saves);
        },
      );
    } else if (_overlay == _WebEmulatorOverlay.saves &&
        actions != null &&
        repository != null) {
      overlay = Host4EmulatorSaveManager(
        actions: actions,
        dataSource: repository,
        onBack: () {
          setState(() => _overlay = _WebEmulatorOverlay.menu);
        },
      );
    } else if (_overlay == _WebEmulatorOverlay.keyLocator) {
      overlay = const Host4EmulatorKeyLocatorOverlay();
    }

    final controls = _launched
        ? IgnorePointer(
            ignoring: _overlay != _WebEmulatorOverlay.none,
            child: Host4EmulatorControlsLayer(
              profile: _profileFor(config.system),
              layoutStyle: _layoutStyle,
              onInput: _onInput,
              onMenuTap: _openMenu,
              onLocateTap: _openKeyLocator,
            ),
          )
        : const SizedBox.shrink();

    return WebEmulatorOverlayLayers(
      game: Host4WebEmulatorView(
        key: ValueKey<String>(_gameKey!),
        launchConfig: config,
        onControllerReady: _onControllerReady,
        onBridgeMessage: (method, payload) {
          debugPrint('[WebEmulatorDemo] bridge: $method $payload');
          if (!mounted || method != 'launched') return;
          _layoutLog.info(
            'controls_shown layout=${_layoutStyle.name} '
            'system=${config.system.name}',
          );
          setState(() {
            _launched = true;
            _status = '模拟器已启动';
          });
        },
        onWebError: (error) {
          debugPrint('[WebEmulatorDemo] web error: $error');
          if (mounted) setState(() => _status = '模拟器错误：$error');
        },
      ),
      controls: controls,
      overlay: overlay,
      activeMenuButton: _launched && _overlay != _WebEmulatorOverlay.none
          ? Host4EmulatorActiveMenuButton(
              layoutStyle: _layoutStyle,
              onTap: () => unawaited(_closeOverlayFromSet()),
            )
          : null,
    );
  }

  static Host4EmulatorControlProfile _profileFor(
    Host4WebEmulatorSystem system,
  ) {
    return switch (system) {
      Host4WebEmulatorSystem.gb => Host4EmulatorControlProfile.gb,
      Host4WebEmulatorSystem.gbc => Host4EmulatorControlProfile.gbc,
      Host4WebEmulatorSystem.gba => Host4EmulatorControlProfile.gba,
    };
  }
}
