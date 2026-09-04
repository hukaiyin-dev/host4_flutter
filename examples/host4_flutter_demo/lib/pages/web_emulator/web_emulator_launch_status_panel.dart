import 'package:flutter/material.dart';

import 'web_emulator_launch_state.dart';

class WebEmulatorLaunchStatusPanel extends StatelessWidget {
  const WebEmulatorLaunchStatusPanel({
    super.key,
    required this.state,
    this.onRetry,
    this.onSelectRom,
  });

  final WebEmulatorLaunchState state;
  final VoidCallback? onRetry;
  final VoidCallback? onSelectRom;

  @override
  Widget build(BuildContext context) {
    if (state.phase == WebEmulatorLaunchPhase.running) {
      return const SizedBox.shrink();
    }

    final failed = state.phase == WebEmulatorLaunchPhase.failed;
    final colorScheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colorScheme.surface,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (failed)
                      Icon(
                        Icons.error_outline_rounded,
                        size: 40,
                        color: colorScheme.error,
                      )
                    else
                      const SizedBox.square(
                        dimension: 40,
                        child: CircularProgressIndicator(),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      failed ? '模拟器启动失败' : '正在启动模拟器…',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (failed) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        state.error ?? '未知错误',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: <Widget>[
                          FilledButton(
                            onPressed: onRetry,
                            child: const Text('重新启动'),
                          ),
                          OutlinedButton(
                            onPressed: onSelectRom,
                            child: const Text('重新选择 ROM'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
