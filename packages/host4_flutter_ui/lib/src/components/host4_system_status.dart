import 'dart:async';

import 'package:flutter/material.dart';

import '../foundation/theme/host4_theme_scope.dart';

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
  const Host4SystemStatus({required this.source, super.key});

  final Host4SystemStatusSource source;

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
    final s = widget.source;
    _time = s.currentTime;
    _wifi = s.currentWifi;
    _batteryLevel = s.currentBatteryLevel;

    _subs.add(s.timeStream.listen((v) {
      if (mounted) setState(() => _time = v);
    }));
    _subs.add(s.wifiStream.listen((v) {
      if (mounted) setState(() => _wifi = v);
    }));
    _subs.add(s.batteryLevelStream.listen((v) {
      if (mounted) setState(() => _batteryLevel = v);
    }));
  }

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    widget.source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    final color = theme.colors.textPrimary;
    final gap = theme.components.navigationBar.paddingBottom;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          _time,
          style: theme.typography.label.toTextStyle(color),
        ),
        SizedBox(width: gap),
        _WifiIcon(enabled: _wifi, color: color),
        SizedBox(width: gap),
        _BatteryIcon(
          level: _batteryLevel,
          color: color,
          emptyColor: color.withValues(alpha: 0.2),
        ),
      ],
    );
  }
}

// ─── WiFi ─────────────────────────────────────────────────────────────────────

class _WifiIcon extends StatelessWidget {
  const _WifiIcon({required this.enabled, required this.color});

  final bool enabled;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Center(
        child: Icon(
          enabled ? Icons.wifi_rounded : Icons.wifi_off_rounded,
          size: 18,
          color: enabled ? color : color.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

// ─── Battery ──────────────────────────────────────────────────────────────────

class _BatteryIcon extends StatelessWidget {
  const _BatteryIcon({
    required this.level,
    required this.color,
    required this.emptyColor,
  });

  final int level;
  final Color color;
  final Color emptyColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Center(
        child: CustomPaint(
          size: const Size(22, 11),
          painter: _BatteryPainter(
            level: level / 100.0,
            color: color,
            emptyColor: emptyColor,
          ),
        ),
      ),
    );
  }
}

class _BatteryPainter extends CustomPainter {
  const _BatteryPainter({
    required this.level,
    required this.color,
    required this.emptyColor,
  });

  final double level; // 0.0–1.0
  final Color color;
  final Color emptyColor; // 空余区：textPrimary @ 20% — 对应 Figma color/navy/950-20

  @override
  void paint(Canvas canvas, Size size) {
    final bodyW = size.width - 2.5;
    final bodyH = size.height;
    const radius = Radius.circular(2);
    const innerRadius = Radius.circular(1.4);

    // 1. 空余区背景（整个电池内腔，半透明）— 设计图 color/navy/950-20
    canvas.drawRRect(
      RRect.fromLTRBR(0.6, 0.6, bodyW - 0.6, bodyH - 0.6, innerRadius),
      Paint()
        ..color = emptyColor
        ..style = PaintingStyle.fill,
    );

    // 2. 电量填充条
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

    // 3. 外壳描边
    canvas.drawRRect(
      RRect.fromLTRBR(0, 0, bodyW, bodyH, radius),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // 4. 正极端子
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
      old.level != level ||
      old.color != color ||
      old.emptyColor != emptyColor;
}
