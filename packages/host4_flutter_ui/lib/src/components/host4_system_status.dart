import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../foundation/host4_icon_assets.dart';
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

/// 静态系统状态数据源。
///
/// 适合页面只拿到一份 [Host4SystemStatusData] 快照的场景。
class Host4StaticSystemStatusSource implements Host4SystemStatusSource {
  const Host4StaticSystemStatusSource(this.data);

  final Host4SystemStatusData data;

  @override
  String get currentTime => data.timeLabel;

  @override
  bool get currentWifi => data.wifiEnabled;

  @override
  int get currentBatteryLevel => data.batteryLevel;

  @override
  bool get currentCharging => data.batteryCharging;

  @override
  Stream<String> get timeStream => const Stream.empty();

  @override
  Stream<bool> get wifiStream => const Stream.empty();

  @override
  Stream<int> get batteryLevelStream => const Stream.empty();

  @override
  Stream<bool> get chargingStream => const Stream.empty();

  @override
  void dispose() {}
}

/// [ValueListenable] 系统状态数据源。
///
/// 监听 [ValueListenable<Host4SystemStatusData>]，仅在对应字段变化时
/// 推送更新，避免无关字段触发不必要的状态栏重建。
class Host4ValueListenableSystemStatusSource
    implements Host4SystemStatusSource {
  Host4ValueListenableSystemStatusSource(this.listenable) {
    _previous = listenable.value;
    listenable.addListener(_onStatusChanged);
  }

  final ValueListenable<Host4SystemStatusData> listenable;
  late Host4SystemStatusData _previous;

  final _timeController = StreamController<String>.broadcast();
  final _wifiController = StreamController<bool>.broadcast();
  final _batteryController = StreamController<int>.broadcast();
  final _chargingController = StreamController<bool>.broadcast();

  void _onStatusChanged() {
    final next = listenable.value;
    if (next.timeLabel != _previous.timeLabel) {
      _timeController.add(next.timeLabel);
    }
    if (next.wifiEnabled != _previous.wifiEnabled) {
      _wifiController.add(next.wifiEnabled);
    }
    if (next.batteryLevel != _previous.batteryLevel) {
      _batteryController.add(next.batteryLevel);
    }
    if (next.batteryCharging != _previous.batteryCharging) {
      _chargingController.add(next.batteryCharging);
    }
    _previous = next;
  }

  @override
  String get currentTime => listenable.value.timeLabel;

  @override
  bool get currentWifi => listenable.value.wifiEnabled;

  @override
  int get currentBatteryLevel => listenable.value.batteryLevel;

  @override
  bool get currentCharging => listenable.value.batteryCharging;

  @override
  Stream<String> get timeStream => _timeController.stream;

  @override
  Stream<bool> get wifiStream => _wifiController.stream;

  @override
  Stream<int> get batteryLevelStream => _batteryController.stream;

  @override
  Stream<bool> get chargingStream => _chargingController.stream;

  @override
  void dispose() {
    listenable.removeListener(_onStatusChanged);
    _timeController.close();
    _wifiController.close();
    _batteryController.close();
    _chargingController.close();
  }
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
    super.key,
  });

  final Host4SystemStatusSource source;
  final Color? color;

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
        Text(_time, style: theme.typography.label.toTextStyle(color)),
        SizedBox(width: gap),
        _WifiIcon(enabled: _wifi, color: color),
        SizedBox(width: gap),
        _BatteryIcon(level: _batteryLevel, color: color),
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
    return Opacity(
      opacity: enabled ? 1.0 : 0.35,
      child: SizedBox(
        width: 24,
        height: 24,
        child: Center(
          child: SvgPicture.asset(
            Host4IconAssets.wifiStrong,
            width: 16,
            height: 16,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}

// ─── Battery ──────────────────────────────────────────────────────────────────

class _BatteryIcon extends StatelessWidget {
  const _BatteryIcon({required this.level, required this.color});

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
