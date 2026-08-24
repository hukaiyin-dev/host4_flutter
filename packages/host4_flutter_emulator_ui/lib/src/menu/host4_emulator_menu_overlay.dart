import 'dart:async';

import 'package:flutter/material.dart';

import '../session/host4_emulator_session_actions.dart';

class Host4EmulatorMenuOverlay extends StatefulWidget {
  const Host4EmulatorMenuOverlay({
    required this.actions,
    required this.onOpenSaveManager,
    super.key,
  });

  final Host4EmulatorSessionActions actions;
  final VoidCallback onOpenSaveManager;

  @override
  State<Host4EmulatorMenuOverlay> createState() =>
      _Host4EmulatorMenuOverlayState();
}

class _Host4EmulatorMenuOverlayState extends State<Host4EmulatorMenuOverlay> {
  bool _busy = false;
  String? _error;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleRate() async {
    final next = widget.actions.rate == 1 ? 2.0 : 1.0;
    await widget.actions.setRate(next);
  }

  @override
  Widget build(BuildContext context) {
    final items = <_MenuItem>[
      _MenuItem(
        keyName: 'menu.quick_save',
        icon: Icons.save_outlined,
        label: '快速存档',
        onTap: () => _run(widget.actions.quickSave),
      ),
      _MenuItem(
        keyName: 'menu.quick_load',
        icon: Icons.restore,
        label: '快速读档',
        onTap: () => _run(widget.actions.quickLoad),
      ),
      _MenuItem(
        keyName: 'menu.save_manager',
        icon: Icons.folder_open_outlined,
        label: '存档管理',
        onTap: widget.onOpenSaveManager,
      ),
      _MenuItem(
        keyName: 'menu.speed',
        icon: Icons.speed,
        label: '${widget.actions.rate.toStringAsFixed(0)}× 倍速',
        onTap: () => _run(_toggleRate),
      ),
      _MenuItem(
        keyName: 'menu.restart',
        icon: Icons.refresh,
        label: '重新开始',
        onTap: () => _run(widget.actions.restart),
      ),
      _MenuItem(
        keyName: 'menu.exit',
        icon: Icons.logout,
        label: '退出游戏',
        onTap: () => _run(widget.actions.exit),
      ),
      _MenuItem(
        keyName: 'menu.continue',
        icon: Icons.play_arrow_rounded,
        label: '继续游戏',
        highlighted: true,
        onTap: () => _run(widget.actions.resume),
      ),
    ];

    return Material(
      color: const Color(0xCC10131A),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    '游戏菜单',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  IgnorePointer(
                    ignoring: _busy,
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: items,
                    ),
                  ),
                  if (_busy) ...<Widget>[
                    const SizedBox(height: 16),
                    const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                  if (_error != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      key: const ValueKey<String>('menu.error'),
                      style: const TextStyle(color: Color(0xFFFF7B7B)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.keyName,
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final String keyName;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey<String>(keyName),
      width: 132,
      height: 82,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: highlighted
                ? const Color(0xFFED3D69)
                : const Color(0xFF292E38),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
