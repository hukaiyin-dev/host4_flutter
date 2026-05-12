import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'gmacro_ble_scan_page.dart';

class GmacroEntryPage extends StatelessWidget {
  const GmacroEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final reservedTitle = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'MFi',
      _ => 'USB',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('GMacro 调试')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('请选择传输链路', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('一期只验证 BLE + GMacro 主链路，其他入口先做占位展示。'),
          const SizedBox(height: 16),
          _EntryCard(
            icon: Icons.bluetooth_searching,
            title: 'BLE',
            description: '扫描设备、连接 transport，并自动附着 GMacro 协议。',
            actionLabel: '进入',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const GmacroBleScanPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _EntryCard(
            icon: Icons.usb_outlined,
            title: reservedTitle,
            description: '当前 example 仅展示入口，原生链路待接入。',
            actionLabel: '即将支持',
          ),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(description),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.tonal(onPressed: onTap, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
