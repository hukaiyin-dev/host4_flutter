import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';
import 'package:host4_flutter_web_emulator/host4_flutter_web_emulator.dart';

class WebEmulatorPocPage extends StatefulWidget {
  const WebEmulatorPocPage({super.key});

  @override
  State<WebEmulatorPocPage> createState() => _WebEmulatorPocPageState();
}

class _WebEmulatorPocPageState extends State<WebEmulatorPocPage> {
  Host4WebEmulatorLaunchConfig? _launchConfig;
  Host4WebEmulatorController? _controller;
  String _status = '请选择一个 .gb / .gbc / .gba / .zip ROM。';
  bool _loadingRom = false;

  @override
  void dispose() {
    _controller?.exit();
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
        allowedExtensions: const ['gb', 'gbc', 'gba', 'zip'],
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

      final bytes = file.bytes ?? await File(file.path!).readAsBytes();
      var system = Host4WebEmulatorSystem.tryFromRomFileName(file.name);

      // ZIP 文件无法从文件名推断 system，需要用户选择
      if (system == null) {
        if (Host4WebEmulatorSystem.isZipFile(file.name)) {
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
        } else {
          throw ArgumentError('不支持的文件类型：${file.name}');
        }
      }

      // 退出上一个 emulator
      _controller?.exit();

      final config = Host4WebEmulatorLaunchConfig(
        system: system,
        romName: file.name,
        romBase64: base64Encode(bytes),
      );

      if (!mounted) return;
      setState(() {
        _launchConfig = config;
        _loadingRom = false;
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

  Future<Host4WebEmulatorSystem?> _pickSystemForZip() async {
    return showDialog<Host4WebEmulatorSystem>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('ZIP 内的 ROM 是什么平台？'),
        children: [
          for (final system in Host4WebEmulatorSystem.values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, system),
              child: Text(system.name.toUpperCase()),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    final config = _launchConfig;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            theme.spacing.page,
            0,
            theme.spacing.page,
            theme.spacing.md,
          ),
          child: Host4Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Host4Text('Web 模拟器 POC', role: Host4TextRole.heading),
                SizedBox(height: theme.spacing.sm),
                Host4Text(_status, colorRole: Host4TextColorRole.secondary),
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
              ? Center(
                  child: Host4Text(
                    '选择 ROM 后会在这里启动 Nostalgist + mGBA。',
                    colorRole: Host4TextColorRole.secondary,
                  ),
                )
              : Host4WebEmulatorView(
                  launchConfig: config,
                  onControllerReady: (controller) {
                    _controller = controller;
                  },
                  onBridgeMessage: (method, payload) {
                    if (!mounted) return;
                    setState(() => _status = '$method: $payload');
                  },
                  onWebError: (error) {
                    if (!mounted) return;
                    setState(() => _status = 'WebView 错误：$error');
                  },
                ),
        ),
      ],
    );
  }
}
