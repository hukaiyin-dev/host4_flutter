import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../foundation/theme/host4_theme_scope.dart';

// ─── Data ─────────────────────────────────────────────────────────────────────

/// 系统状态快照：时间、WiFi、电量。
class Host4SystemStatusData {
  const Host4SystemStatusData({
    required this.timeLabel,
    required this.wifiEnabled,
    required this.batteryLevel,
    required this.batteryCharging,
  });

  final String timeLabel;
  final bool wifiEnabled;
  final int batteryLevel;
  final bool batteryCharging;
}

// ─── Source Interface ─────────────────────────────────────────────────────────

/// 系统状态数据源抽象接口。
///
/// UI 包只依赖此接口，不依赖任何平台插件。
/// 具体实现（如 `host4_flutter_system_status` 包中的
/// `Host4DefaultSystemStatusSource`）由调用方注入。
///
/// 实现须保证：
/// - `currentXxx` 可同步读取（首帧无闪烁）
/// - stream 在数据变化时 emit 新值
/// - [dispose] 中释放所有内部资源（timer、subscription 等）
abstract class Host4SystemStatusSource {
  /// 当前时间字符串，格式如 `"14:51"`。
  String get currentTime;

  /// 当前 WiFi 是否已连接。
  bool get currentWifi;

  /// 当前电量百分比，0–100。
  int get currentBatteryLevel;

  /// 当前是否正在充电。
  bool get currentCharging;

  /// 时间变化流，每分钟 emit 一次新的时间字符串。
  Stream<String> get timeStream;

  /// WiFi 状态变化流。
  Stream<bool> get wifiStream;

  /// 电量变化流。
  Stream<int> get batteryLevelStream;

  /// 充电状态变化流。
  Stream<bool> get chargingStream;

  /// 释放内部资源。由 [Host4SystemStatus] 在 dispose 时调用。
  void dispose();
}

// ─── Widget ───────────────────────────────────────────────────────────────────

/// 系统状态栏：时间 + WiFi + 电量。
///
/// 独立控件，可嵌入 [Host4TopBar] 的 [status] 参数，也可单独使用。
/// 间距与颜色均从主题 token 读取，不硬编码。
///
/// 数据由 [source] 提供；[source] 由调用方注入，通常来自
/// `host4_flutter_system_status` 包的 `Host4DefaultSystemStatusSource`。
class Host4SystemStatus extends StatefulWidget {
  const Host4SystemStatus({
    required this.source,

    /// 强制使用指定颜色，不跟随主题 textPrimary。
    /// 适用于背景固定为浅色的场景（如 launcher 主页），
    /// 避免系统切换 dark mode 时图标变白。
    this.color,
    this.keyPrefix,
    super.key,
  });

  final Host4SystemStatusSource source;
  final Color? color;
  final String? keyPrefix;

  @override
  State<Host4SystemStatus> createState() => _Host4SystemStatusState();
}

class _Host4SystemStatusState extends State<Host4SystemStatus> {
  late String _time;
  late bool _wifi;
  late int _batteryLevel;

  final List<StreamSubscription<dynamic>> _subs = [];

  @override
  void initState() {
    super.initState();
    _subscribeSource(widget.source);
  }

  @override
  void didUpdateWidget(Host4SystemStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source == widget.source) return;
    _cancelSubs();
    oldWidget.source.dispose();
    _subscribeSource(widget.source);
  }

  void _subscribeSource(Host4SystemStatusSource s) {
    _time = s.currentTime;
    _wifi = s.currentWifi;
    _batteryLevel = s.currentBatteryLevel;
    _subs.add(
      s.timeStream.listen((v) {
        if (mounted) setState(() => _time = v);
      }),
    );
    _subs.add(
      s.wifiStream.listen((v) {
        if (mounted) setState(() => _wifi = v);
      }),
    );
    _subs.add(
      s.batteryLevelStream.listen((v) {
        if (mounted) setState(() => _batteryLevel = v);
      }),
    );
  }

  void _cancelSubs() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
  }

  @override
  void dispose() {
    _cancelSubs();
    widget.source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    final color = widget.color ?? theme.colors.textPrimary;
    final gap = theme.components.navigationBar.paddingBottom;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          _time,
          key: _statusKey('time'),
          style: theme.typography.label.toTextStyle(color),
        ),
        SizedBox(width: gap),
        _WifiIcon(key: _statusKey('wifi'), enabled: _wifi, color: color),
        SizedBox(width: gap),
        _BatteryIcon(
          key: _statusKey('battery'),
          level: _batteryLevel,
          color: color,
        ),
      ],
    );
  }

  Key? _statusKey(String suffix) {
    final prefix = widget.keyPrefix;
    return prefix == null ? null : ValueKey<String>('${prefix}_$suffix');
  }
}

// ─── WiFi ─────────────────────────────────────────────────────────────────────

class _WifiIcon extends StatelessWidget {
  const _WifiIcon({required this.enabled, required this.color, super.key});

  final bool enabled;
  final Color color;

  // Figma: 四号主机通用控件库 / node 423-4050
  static const _svgData = '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M10.2637 14.6002C11.2659 13.7526 12.7341 13.7527 13.7363 14.6002C13.7868 14.6458 13.816 14.711 13.8174 14.7789C13.8187 14.8467 13.7924 14.9121 13.7441 14.9596L12.1748 16.5436C12.1288 16.5901 12.0654 16.6159 12 16.6159C11.9347 16.6158 11.8721 16.59 11.8262 16.5436L10.2568 14.9596C10.2084 14.912 10.1812 14.8459 10.1826 14.778C10.1842 14.7102 10.2134 14.6457 10.2637 14.6002Z" fill="#121A29"/>
<path d="M8.16993 12.4879C10.3293 10.4793 13.6737 10.4793 15.833 12.4879C15.8816 12.535 15.9095 12.5999 15.9102 12.6676C15.9107 12.7351 15.8844 12.8003 15.8369 12.8483L14.9287 13.7653C14.8352 13.8585 14.6847 13.8602 14.5889 13.7692C13.8798 13.1271 12.9566 12.772 12 12.7721C11.0442 12.7726 10.1226 13.1277 9.41407 13.7692C9.31816 13.8603 9.16673 13.8589 9.07325 13.7653L8.167 12.8483C8.11919 12.8003 8.09222 12.7353 8.09278 12.6676C8.09341 12.5999 8.12126 12.535 8.16993 12.4879Z" fill="#121A29"/>
<path d="M6.0752 10.3805C9.38714 7.2065 14.6129 7.2065 17.9248 10.3805C17.9727 10.4276 17.9995 10.4921 18 10.5592C18.0004 10.6264 17.974 10.6912 17.9268 10.7389L17.0186 11.6559C16.925 11.7499 16.7728 11.7513 16.6777 11.6588C15.4159 10.4592 13.7411 9.78976 12 9.78968C10.2589 9.78977 8.58419 10.4592 7.32227 11.6588C7.22729 11.7513 7.07488 11.75 6.98145 11.6559L6.07325 10.7389C6.02596 10.6912 5.99956 10.6264 6.00001 10.5592C6.0005 10.4921 6.02733 10.4276 6.0752 10.3805Z" fill="#121A29"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.35,
      child: SvgPicture.string(
        _svgData,
        width: 16,
        height: 16,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
  }
}

// ─── Battery ──────────────────────────────────────────────────────────────────

class _BatteryIcon extends StatelessWidget {
  const _BatteryIcon({required this.level, required this.color, super.key});

  final int level;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Center(
        child: CustomPaint(
          size: const Size(22, 11),
          painter: _BatteryPainter(level: level / 100.0, color: color),
        ),
      ),
    );
  }
}

class _BatteryPainter extends CustomPainter {
  const _BatteryPainter({required this.level, required this.color});

  final double level; // 0.0–1.0
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final bodyW = size.width - 2.5;
    final bodyH = size.height;
    const radius = Radius.circular(2);

    // 1. 电量填充条（空余区透明，无需背景填充）
    final fillWidth = ((bodyW - 3) * level).clamp(0.0, bodyW - 3);
    if (fillWidth > 0) {
      canvas.drawRRect(
        RRect.fromLTRBR(
          1.5,
          1.5,
          1.5 + fillWidth,
          bodyH - 1.5,
          const Radius.circular(1),
        ),
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }

    // 2. 外壳描边
    canvas.drawRRect(
      RRect.fromLTRBR(0, 0, bodyW, bodyH, radius),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // 3. 正极端子
    canvas.drawRRect(
      RRect.fromLTRBR(
        bodyW + 1,
        bodyH * 0.3,
        bodyW + 2.5,
        bodyH * 0.7,
        const Radius.circular(1),
      ),
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_BatteryPainter old) =>
      old.level != level || old.color != color;
}
