import 'dart:io';

import 'package:flutter/material.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';

import '../../widgets/sub_page_scaffold.dart';
import 'gmacro_ble_scan_page.dart';

class GmacroEntryPage extends StatelessWidget {
  const GmacroEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    final isMfiPlatform = Platform.isIOS;

    return SubPageScaffold(
      title: 'GMacro 调试',
      subtitle: '选择传输方式开始链路测试',
      child: ListView(
        padding: EdgeInsets.all(theme.spacing.page),
        children: [
          _TransportTile(
            label: 'BLE 连接',
            description: '通过蓝牙低功耗扫描并连接设备，测试 GMacro 主链路',
            icon: Icons.bluetooth_rounded,
            color: theme.colors.brandPrimary,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GmacroBleScanPage()),
            ),
          ),
          SizedBox(height: theme.spacing.md),
          _TransportTile(
            label: isMfiPlatform ? 'MFi 连接' : 'USB 连接',
            description: isMfiPlatform
                ? '通过 MFi 有线连接设备，需完成 iAP2 握手后测试 GMacro'
                : 'USB 有线连接（Android），暂未接入',
            icon: isMfiPlatform ? Icons.cable_rounded : Icons.usb_rounded,
            color: theme.colors.brandSecondary,
            badge: '即将支持',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('MFi / USB 接入进行中，暂不可用')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TransportTile extends StatelessWidget {
  const _TransportTile({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
  });

  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(theme.radius.card),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colors.surface,
            borderRadius: BorderRadius.circular(theme.radius.card),
            border: Border.all(color: theme.colors.borderDefault),
          ),
          child: Padding(
            padding: EdgeInsets.all(theme.spacing.lg),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(theme.radius.lg),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                SizedBox(width: theme.spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Host4Text(label, role: Host4TextRole.heading),
                          if (badge != null) ...[
                            SizedBox(width: theme.spacing.sm),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: theme.spacing.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colors.surfaceMuted,
                                borderRadius:
                                    BorderRadius.circular(theme.radius.pill),
                              ),
                              child: Text(
                                badge!,
                                style: theme.typography.caption.toTextStyle(
                                  theme.colors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: theme.spacing.xs),
                      Host4Text(
                        description,
                        colorRole: Host4TextColorRole.secondary,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: theme.spacing.sm),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: theme.colors.textSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
