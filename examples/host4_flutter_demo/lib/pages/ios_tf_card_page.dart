import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';

import '../platform/ios_tf_card_channel.dart';
import '../widgets/debug_row.dart';

class IosTfCardPage extends StatefulWidget {
  const IosTfCardPage({super.key});

  @override
  State<IosTfCardPage> createState() => _IosTfCardPageState();
}

class _IosTfCardPageState extends State<IosTfCardPage> {
  bool _scanning = false;
  IosTfCardScanResult? _result;

  Future<void> _scan({bool forcePick = false}) async {
    if (!Platform.isIOS) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('当前功能仅支持 iOS 真机。')));
      return;
    }

    setState(() => _scanning = true);
    try {
      final result = await scanIosTfCard(forcePick: forcePick);
      if (!mounted) return;
      setState(() => _result = result);
    } on PlatformException catch (error) {
      if (!mounted || error.code == 'cancelled') return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('扫描失败：${error.message ?? error.code}')),
      );
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    final result = _result;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        theme.spacing.page,
        0,
        theme.spacing.page,
        theme.spacing.page,
      ),
      children: [
        Host4Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Host4Text('实验目标', role: Host4TextRole.heading),
              SizedBox(height: theme.spacing.sm),
              const Host4Text(
                '在 iOS 上选择 TF 卡根目录或 roms 目录，由原生按 Android 规则扫描可识别平台下的游戏文件，并把结果返回 Flutter 展示。',
                colorRole: Host4TextColorRole.secondary,
              ),
              SizedBox(height: theme.spacing.md),
              Host4Button(
                label: _scanning ? '扫描中...' : '扫描上次目录或选择 TF 卡',
                expanded: true,
                onPressed: _scanning ? null : _scan,
              ),
              if (result != null) ...[
                SizedBox(height: theme.spacing.sm),
                Host4Button(
                  label: '重新选择目录',
                  variant: Host4ButtonVariant.secondary,
                  expanded: true,
                  onPressed: _scanning ? null : () => _scan(forcePick: true),
                ),
              ],
            ],
          ),
        ),
        if (result != null) ...[
          SizedBox(height: theme.spacing.md),
          _ScanSummaryCard(result: result),
          SizedBox(height: theme.spacing.md),
          _PlatformSummaryCard(result: result),
          SizedBox(height: theme.spacing.md),
          _GamesCard(result: result),
        ],
      ],
    );
  }
}

class _ScanSummaryCard extends StatelessWidget {
  const _ScanSummaryCard({required this.result});

  final IosTfCardScanResult result;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return Host4Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Host4Text('扫描结果', role: Host4TextRole.heading),
          SizedBox(height: theme.spacing.md),
          DebugRow(label: 'TF 卡根目录', value: result.rootPath, theme: theme),
          DebugRow(label: 'roms 目录', value: result.romsPath, theme: theme),
          DebugRow(
            label: '识别平台',
            value: '${result.platformCount}',
            theme: theme,
          ),
          DebugRow(label: '游戏数量', value: '${result.gameCount}', theme: theme),
        ],
      ),
    );
  }
}

class _PlatformSummaryCard extends StatelessWidget {
  const _PlatformSummaryCard({required this.result});

  final IosTfCardScanResult result;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return Host4Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Host4Text('平台分布', role: Host4TextRole.heading),
          SizedBox(height: theme.spacing.md),
          if (result.platforms.isEmpty)
            const Host4Text(
              '未识别到 Android 规则支持的平台目录。',
              colorRole: Host4TextColorRole.secondary,
            )
          else
            for (final platform in result.platforms) ...[
              DebugRow(
                label: platform.name,
                value: '${platform.gameCount} 个游戏',
                theme: theme,
              ),
            ],
        ],
      ),
    );
  }
}

class _GamesCard extends StatelessWidget {
  const _GamesCard({required this.result});

  final IosTfCardScanResult result;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    final games = result.games;

    return Host4Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Host4Text('游戏列表', role: Host4TextRole.heading),
          SizedBox(height: theme.spacing.sm),
          Host4Text(
            games.isEmpty ? '暂无游戏。' : '按原生扫描返回顺序展示。',
            colorRole: Host4TextColorRole.secondary,
          ),
          SizedBox(height: theme.spacing.md),
          for (var index = 0; index < games.length; index++) ...[
            if (index > 0) Divider(color: theme.colors.borderDefault),
            _GameRow(game: games[index]),
          ],
        ],
      ),
    );
  }
}

class _GameRow extends StatelessWidget {
  const _GameRow({required this.game});

  final IosTfCardGame game;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    final metadata = <String>[
      game.platform,
      game.relativePath,
      if (game.image != null) '图：${game.image}',
      if (game.video != null) '视频：${game.video}',
    ].join('  |  ');

    return Padding(
      padding: EdgeInsets.symmetric(vertical: theme.spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Host4Text(game.name),
          SizedBox(height: theme.spacing.xs),
          Text(
            metadata,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.typography.caption.toTextStyle(
              theme.colors.textSecondary,
            ),
          ),
          if (game.desc != null) ...[
            SizedBox(height: theme.spacing.xs),
            Text(
              game.desc!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.caption.toTextStyle(
                theme.colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
