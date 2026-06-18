import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';

/// 默认系统状态数据源。
///
/// - 时间：每分钟在整点更新，与系统时钟对齐
/// - WiFi：通过 [Connectivity] stream 实时响应
/// - 电量值：每分钟 poll 一次（`battery_plus` 无电量变化 stream）
/// - 充电状态：通过 [Battery.onBatteryStateChanged] 实时响应
class Host4DefaultSystemStatusSource implements Host4SystemStatusSource {
  Host4DefaultSystemStatusSource() {
    _init();
  }

  final _battery = Battery();
  final _connectivity = Connectivity();

  final _timeCtrl = StreamController<String>.broadcast();
  final _wifiCtrl = StreamController<bool>.broadcast();
  final _batteryLevelCtrl = StreamController<int>.broadcast();
  final _chargingCtrl = StreamController<bool>.broadcast();

  Timer? _minuteTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  StreamSubscription<BatteryState>? _batterySub;

  String _time = _formatTime(DateTime.now());
  bool _wifi = false;
  int _batteryLevel = 100;
  bool _charging = false;

  // ── 公开同步值 ──────────────────────────────────────────────────────────────

  @override
  String get currentTime => _time;
  @override
  bool get currentWifi => _wifi;
  @override
  int get currentBatteryLevel => _batteryLevel;
  @override
  bool get currentCharging => _charging;

  // ── Streams ─────────────────────────────────────────────────────────────────

  @override
  Stream<String> get timeStream => _timeCtrl.stream;
  @override
  Stream<bool> get wifiStream => _wifiCtrl.stream;
  @override
  Stream<int> get batteryLevelStream => _batteryLevelCtrl.stream;
  @override
  Stream<bool> get chargingStream => _chargingCtrl.stream;

  // ── 初始化 ──────────────────────────────────────────────────────────────────

  void _init() {
    _initTime();
    _initConnectivity();
    _initBattery();
  }

  void _initTime() {
    final now = DateTime.now();
    // 等到下一分钟整点再触发，之后每分钟 tick，与系统时钟对齐
    final waitSeconds = 60 - now.second;
    final waitMs = waitSeconds * 1000 - now.millisecond;
    Future.delayed(Duration(milliseconds: waitMs), () {
      if (_timeCtrl.isClosed) return; // dispose 可能在 delay 期间发生
      _updateTime();
      _minuteTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        _updateTime();
        _updateBatteryLevel(); // 顺带刷新电量（避免多 timer）
      });
    });
  }

  void _updateTime() {
    if (_timeCtrl.isClosed) return;
    _time = _formatTime(DateTime.now());
    _timeCtrl.add(_time);
  }

  void _initConnectivity() {
    // 先读一次当前状态，拿到后 emit 到流，让已挂载的 widget 及时更新
    _connectivity.checkConnectivity().then((results) {
      final wifi = _isWifi(results);
      if (wifi != _wifi) {
        _wifi = wifi;
        if (!_wifiCtrl.isClosed) _wifiCtrl.add(_wifi);
      }
    });

    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      if (_wifiCtrl.isClosed) return;
      final wifi = _isWifi(results);
      if (wifi != _wifi) {
        _wifi = wifi;
        _wifiCtrl.add(_wifi);
      }
    });
  }

  void _initBattery() {
    // 先读一次，拿到后 emit 到流
    Future.wait([
      _battery.batteryLevel,
      _battery.batteryState,
    ]).then((results) {
      final level = results[0] as int;
      final charging = _isCharging(results[1] as BatteryState);
      if (level != _batteryLevel) {
        _batteryLevel = level;
        if (!_batteryLevelCtrl.isClosed) _batteryLevelCtrl.add(_batteryLevel);
      }
      if (charging != _charging) {
        _charging = charging;
        if (!_chargingCtrl.isClosed) _chargingCtrl.add(_charging);
      }
    });

    // 充电状态变化流（实时）
    _batterySub = _battery.onBatteryStateChanged.listen((state) {
      if (_chargingCtrl.isClosed) return;
      final charging = _isCharging(state);
      if (charging != _charging) {
        _charging = charging;
        _chargingCtrl.add(_charging);
      }
    });
  }

  Future<void> _updateBatteryLevel() async {
    final level = await _battery.batteryLevel;
    if (level != _batteryLevel && !_batteryLevelCtrl.isClosed) {
      _batteryLevel = level;
      _batteryLevelCtrl.add(_batteryLevel);
    }
  }

  // ── Dispose ──────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _minuteTimer?.cancel();
    _connectivitySub?.cancel();
    _batterySub?.cancel();
    _timeCtrl.close();
    _wifiCtrl.close();
    _batteryLevelCtrl.close();
    _chargingCtrl.close();
  }

  // ── 工具函数 ─────────────────────────────────────────────────────────────────

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static bool _isWifi(List<ConnectivityResult> results) =>
      results.contains(ConnectivityResult.wifi);

  static bool _isCharging(BatteryState state) =>
      state == BatteryState.charging || state == BatteryState.full;
}
