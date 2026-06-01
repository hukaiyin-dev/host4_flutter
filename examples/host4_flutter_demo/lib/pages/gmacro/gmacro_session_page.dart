import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:host4_flutter_gmacro/host4_flutter_gmacro.dart';
import 'package:host4_flutter_protocol/host4_flutter_protocol.dart';
import 'package:host4_flutter_transport/host4_flutter_transport.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';
import 'package:host4_flutter_log/host4_flutter_log.dart';

import '../../widgets/sub_page_scaffold.dart';
import 'gmacro_placeholder_values.dart';

// ─── section / action data model ────────────────────────────────────────────

class _Action {
  const _Action(this.title, this.invoke);
  final String title;
  final Future<void> Function() invoke;
}

class _Section {
  _Section({required this.title, required this.actions});
  final String title;
  final List<_Action> actions;
  bool expanded = false;
}

// ─── page ────────────────────────────────────────────────────────────────────

class GmacroSessionPage extends StatefulWidget {
  const GmacroSessionPage({
    required this.transport,
    this.transportInitiallyReady = false,
    super.key,
  });

  final TransportSession transport;

  /// When true (e.g. USB connect page already reached [TransportReady]),
  /// transport events will not replay on a new listener.
  final bool transportInitiallyReady;

  @override
  State<GmacroSessionPage> createState() => _GmacroSessionPageState();
}

class _GmacroSessionPageState extends State<GmacroSessionPage> {
  final _log = Host4Logger('GMacroSession');
  final _gmacro = Host4Gmacro(config: GmacroPlaceholderValues.config);

  GmacroSession? _session;
  bool _isAttaching = true;
  bool _isConnected = false;
  bool _isProtocolReady = false;

  // OTA
  bool _isOtaRunning = false;
  double _otaProgress = 0;
  String _otaStatusMessage = '';

  // tip label (replaces the log list)
  String _tipText = '';

  static const _nativeLogChannel = EventChannel(
    'host4_flutter_device_native/native_log',
  );

  StreamSubscription<TransportEvent>? _transportSub;
  StreamSubscription<ProtocolEvent>? _protocolSub;
  StreamSubscription<dynamic>? _nativeLogSub;

  late List<_Section> _sections;
  String? _selectedTitle;

  @override
  void initState() {
    super.initState();
    _log.info('Init session for transport: ${widget.transport.id}');
    if (widget.transportInitiallyReady) {
      _isConnected = true;
    }
    _subscribeTransport();
    _subscribeNativeLog();
    _attach();
    // sections depend on _session — rebuild when session is ready
    _sections = _buildSections();
    _sections.first.expanded = true;
  }

  @override
  void dispose() {
    _log.info('Disposing session page');
    _transportSub?.cancel();
    _protocolSub?.cancel();
    _nativeLogSub?.cancel();
    _session?.close();
    if (widget.transport.device.kind != TransportKind.usb) {
      widget.transport.disconnect();
    }
    super.dispose();
  }

  // ── section data ────────────────────────────────────────────────────────

  List<_Section> _buildSections() {
    return [
      _Section(
        title: '设备',
        actions: [
          _Action('查询设备版本', _fetchDeviceVersion),
          _Action('查询设备信息', _fetchMobapadDeviceInfo),
          _Action('恢复默认设置', _resetDevice),
          _Action('切换普通模式', _switchToNormalMode),
          _Action('切换配置模式', _switchToConfigMode),
          _Action('查询上报率', _fetchReportRate),
          _Action('设置上报率 (1000Hz)', _updateReportRate),
          _Action('OTA 升级', _startOta),
        ],
      ),
      _Section(
        title: '键值',
        actions: [
          _Action('查询可映射按键', _queryMappableKeys),
          _Action('查询当前映射', _queryCurrentMapping),
          _Action('查询所有多映射', _queryAllMultiMappings),
        ],
      ),
      _Section(
        title: '摇杆',
        actions: [
          _Action('摇杆线性设置', _updateRockerLinear),
          _Action('左摇杆曲线设置', _updateLeftRocker3DCurve),
          _Action('右摇杆曲线设置', _updateRightRocker3DCurve),
          _Action('摇杆死区补偿', _rockerDeadZoneCompensation),
          _Action('曲线触发方式', _rockerTriggerType),
          _Action('摇杆输出轨迹', _rockerOutputGraphics),
          _Action('开始摇杆校准', _startRockerCalibration),
          _Action('结束摇杆校准', _endRockerCalibration),
        ],
      ),
      _Section(
        title: '扳机',
        actions: [
          _Action('设置扳机死区', _trigger),
          _Action('左扳机曲线', _leftTriggerCurve),
          _Action('右扳机曲线', _rightTriggerCurve),
          _Action('快速扳机 开', _triggerQuickSwitchOn),
          _Action('快速扳机 关', _triggerQuickSwitchOff),
          _Action('查询快速扳机', _getTriggerQuickSwitch),
          _Action('扳机线性输出', _triggerLinearOutput),
          _Action('开始扳机校准', _startTriggerCalibration),
          _Action('结束扳机校准', _endTriggerCalibration),
        ],
      ),
      _Section(
        title: '振动',
        actions: [
          _Action('设置振动等级 (left:50, right:50)', _setVibrationLevel),
          _Action('测试振动 (left:128, right:128)', _testVibration),
        ],
      ),
      _Section(
        title: '连发',
        actions: [
          _Action('查询支持连发的按键', _querySupportedTurboKeys),
          _Action('设置连发速率', _setTurboDatas),
        ],
      ),
      _Section(
        title: '按键映射',
        actions: [
          _Action('设置手柄按键映射', _setKeyMappings),
          _Action('设置鼠标按键映射', _setMouseKeyMappings),
          _Action('设置键盘按键映射', _setKeyboardKeyMappings),
          _Action('设置多类型映射', _setMultiKeyMapping),
        ],
      ),
      _Section(
        title: '宏设置',
        actions: [
          _Action('查询宏按键', _queryMacroKeys),
          _Action('查询宏时间范围', _queryMacroTimeRange),
          _Action('查询宏最大组数', _queryMacroMaxGroups),
          _Action('设置宏间隔', _setMacroInterval),
          _Action('设置宏子按键', _setMacroKeys),
          _Action('开始录制宏', _startRecord),
          _Action('结束录制宏', _endRecord),
        ],
      ),
      _Section(
        title: '体感',
        actions: [
          _Action('查询体感触发按键', _queryGyroTriggerKeys),
          _Action('查询体感映射模式', _queryGyroMappingModes),
          _Action('设置体感参数', _setMotion),
          _Action('设置体感二级灵敏度', _setMotionSecondary),
          _Action('XY 轴反转 (x:true, y:false)', _setGyroXYInvert),
          _Action('设置陀螺仪 XY 比例', _updateGyroXYRatio),
          _Action('设置映射类型', _updateGyroMappingType),
          _Action('开始陀螺仪校准', _startGyroCalibration),
          _Action('结束陀螺仪校准', _endGyroCalibration),
        ],
      ),
      _Section(
        title: '休眠时间',
        actions: [
          _Action('查询睡眠时间', _getSleepTime),
          _Action('设置睡眠时间 (300s)', _setSleepTime),
        ],
      ),
      _Section(
        title: '灯光',
        actions: [
          _Action('查询灯光状态', _fetchLight),
          _Action('查询灯光位置', _fetchLightPosition),
          _Action('查询支持特效', _fetchSupportedLightEffects),
          _Action('查询当前特效', _fetchCurrentLightEffect),
          _Action('设置灯组颜色 (home, 红色)', _setLightColor),
          _Action('设置灯光特效 (home, 呼吸)', _setLightEffect),
          _Action('设置灯效配置', _setLightConfig),
        ],
      ),
      _Section(
        title: '充电',
        actions: [
          _Action('查询充电底座开关', _fetchChargingDock),
          _Action('开启充电底座', _updateChargingDockOn),
          _Action('关闭充电底座', _updateChargingDockOff),
        ],
      ),
      _Section(
        title: '回报率',
        actions: [
          _Action('查询上报率', _fetchReportRate),
          _Action('设置上报率 (1000Hz)', _updateReportRate),
        ],
      ),
    ];
  }

  // ── lifecycle ────────────────────────────────────────────────────────────

  void _subscribeNativeLog() {
    _nativeLogSub = _nativeLogChannel.receiveBroadcastStream().listen((message) {
      if (!mounted) return;
      _log.debug('[Native] $message');
    });
  }

  void _subscribeTransport() {
    _transportSub = widget.transport.events.listen((event) {
      if (!mounted) return;
      final label = switch (event) {
        TransportConnecting() => '📡 Transport: Connecting',
        TransportConnected() => '📡 Transport: Connected',
        TransportReady() => '📡 Transport: Ready',
        TransportDisconnected(cause: final c) =>
          '📡 Transport: Disconnected${c != null ? ' (${c.code})' : ''}',
        TransportError(failure: final f) =>
          '📡 Transport: Error ${f.code} - ${f.message}',
      };

      setState(() {
        _isConnected = event is! TransportDisconnected && event is! TransportError;
        _tipText = label;
      });

      if (event is TransportError) {
        _log.error(label, error: event.failure.message);
      } else if (event is TransportDisconnected) {
        _log.warn(label);
      } else {
        _log.info(label);
      }
    });
  }

  Future<void> _attach() async {
    _log.info('Attaching GMacro protocol...');
    _setTip('⏳ 正在挂载 GMacro 协议…');
    try {
      final session = await _gmacro.attach(widget.transport);
      if (!mounted) {
        session.close();
        return;
      }
      setState(() {
        _session = session;
        _isAttaching = true;
        // rebuild section closures now that _session is set
        _sections = _buildSections();
        _sections.first.expanded = true;
      });
      _log.info('GMacro protocol session created: ${session.id}');
      _setTip('✅ GMacro 协议已挂载 (id: ${session.id})');
      _subscribeProtocol(session);

      final attachTimeout = widget.transport.device.kind == TransportKind.usb
          ? const Duration(seconds: 30)
          : const Duration(seconds: 5);
      Future.delayed(attachTimeout, () {
        if (mounted && _isAttaching && _session?.id == session.id) {
          _log.error('Protocol attachment timeout');
          setState(() => _isAttaching = false);
          _setTip('❌ 挂载超时：设备未响应');
        }
      });
    } catch (e, s) {
      _log.error('Attach failed', error: e, stackTrace: s);
      if (!mounted) return;
      setState(() => _isAttaching = false);
      _setTip('❌ 挂载失败: $e');
    }
  }

  void _subscribeProtocol(GmacroSession session) {
    _protocolSub = session.events.listen((event) {
      if (!mounted) return;
      _log.debug('Protocol event: $event');
      switch (event) {
        case ProtocolReady():
          _log.info('Protocol Ready');
          if (mounted) {
            setState(() {
              _isProtocolReady = true;
              _isAttaching = false;
              if (_isOtaRunning) {
                _isOtaRunning = false;
                _otaProgress = 1.0;
                _otaStatusMessage = 'OTA 升级成功！';
              }
            });
          }
          _setTip('🟢 Protocol Ready');
        case ProtocolBusy(reason: final r, payload: final p):
          _log.debug('Protocol Busy: $r, payload: $p');
          if (mounted && _isOtaRunning) {
            setState(() {
              if (r == 'progress') {
                final progress = p['progress'];
                if (progress is num) {
                  _otaProgress = progress.toDouble();
                  _otaStatusMessage = '升级中: ${(_otaProgress * 100).toStringAsFixed(1)}%';
                }
              } else if (r == 'success') {
                _otaProgress = 1.0;
                _isOtaRunning = false;
                _otaStatusMessage = 'OTA 升级成功！';
              }
            });
          }
          _setTip('🟡 Protocol Busy — $r');
        case ProtocolError(failure: final f):
          _log.error('Protocol Error: ${f.code} - ${f.message}');
          if (mounted) {
            setState(() {
              _isAttaching = false;
              if (_isOtaRunning) {
                _isOtaRunning = false;
                _otaStatusMessage = 'OTA 失败: ${f.message}';
              }
            });
          }
          _setTip('🔴 Protocol Error ${f.code} - ${f.message}');
      }
    });
  }

  void _setTip(String text) {
    if (!mounted) return;
    setState(() => _tipText = text);
  }

  // ── action helpers ───────────────────────────────────────────────────────

  Future<void> _invoke(
    String label,
    Future<Map<String, Object?>> Function() call,
  ) async {
    final session = _session;
    if (session == null) {
      _setTip('⚠ 协议未挂载，请稍候或返回重连');
      return;
    }
    if (!_canOperate) {
      _setTip('⚠ 尚未就绪（传输或协议未 Ready），请稍候');
      return;
    }
    _setTip('▶ $label');
    try {
      final result = await call();
      _log.info('$label result: $result');
      _setTip('◀ $label → $result');
    } catch (e, s) {
      _log.error('$label failed', error: e, stackTrace: s);
      _setTip('◀ 错误: $e');
    }
  }

  // 设备
  Future<void> _fetchDeviceVersion() =>
      _invoke('查询设备版本', () => _session!.fetchDeviceVersion());

  Future<void> _fetchMobapadDeviceInfo() =>
      _invoke('查询设备信息', () => _session!.fetchMobapadDeviceInfo(profile: 0));

  Future<void> _resetDevice() =>
      _invoke('恢复默认设置', () => _session!.resetDevice());

  Future<void> _switchToNormalMode() =>
      _invoke('切换普通模式', () => _session!.switchToNormalMode());

  Future<void> _switchToConfigMode() =>
      _invoke('切换配置模式', () => _session!.switchToConfigMode());

  Future<void> _fetchReportRate() =>
      _invoke('查询上报率', () => _session!.fetchReportRate());

  Future<void> _updateReportRate() =>
      _invoke('设置上报率', () => _session!.updateReportRate(rate: 1000));

  // 键值
  Future<void> _queryMappableKeys() =>
      _invoke('查询可映射按键', () => _session!.queryMappableKeys(profile: 0));

  Future<void> _queryCurrentMapping() =>
      _invoke('查询当前映射', () => _session!.queryCurrentMapping(profile: 0));

  Future<void> _queryAllMultiMappings() =>
      _invoke('查询所有多映射', () => _session!.queryAllMultiMappings());

  // 摇杆
  Future<void> _updateRockerLinear() => _invoke(
    '摇杆线性设置',
    () => _session!.updateRockerLinear(
      leftMin: 0,
      leftMax: 100,
      leftXFlip: false,
      leftYFlip: false,
      rightMin: 0,
      rightMax: 100,
      rightXFlip: false,
      rightYFlip: false,
    ),
  );

  Future<void> _updateLeftRocker3DCurve() => _invoke(
    '左摇杆曲线设置',
    () => _session!.updateLeftRocker3DCurve(
      cgPoints: const [
        GmacroCurvePoint(x: 0, y: 0),
        GmacroCurvePoint(x: 50, y: 50),
        GmacroCurvePoint(x: 100, y: 100),
      ],
    ),
  );

  Future<void> _updateRightRocker3DCurve() => _invoke(
    '右摇杆曲线设置',
    () => _session!.updateRightRocker3DCurve(
      cgPoints: const [
        GmacroCurvePoint(x: 0, y: 0),
        GmacroCurvePoint(x: 50, y: 50),
        GmacroCurvePoint(x: 100, y: 100),
      ],
    ),
  );

  Future<void> _rockerDeadZoneCompensation() => _invoke(
    '摇杆死区补偿',
    () => _session!.rockerDeadZoneCompensation(left: 0, right: 0),
  );

  Future<void> _rockerTriggerType() => _invoke(
    '曲线触发方式',
    () => _session!.rockerTriggerType(
      leftTriggerMode: CurveTriggerMode.continuous,
      leftGamepadKey: GamepadKey.a,
      rightTriggerMode: CurveTriggerMode.continuous,
      rightGamepadKey: GamepadKey.b,
    ),
  );

  Future<void> _rockerOutputGraphics() => _invoke(
    '摇杆输出轨迹',
    () => _session!.rockerOutputGraphics(
      left: OutputGraphics.circle,
      right: OutputGraphics.circle,
    ),
  );

  Future<void> _startRockerCalibration() =>
      _invoke('开始摇杆校准', () => _session!.startRockerCalibration());

  Future<void> _endRockerCalibration() =>
      _invoke('结束摇杆校准', () => _session!.endRockerCalibration());

  // 扳机
  Future<void> _trigger() => _invoke(
    '设置扳机死区',
    () => _session!.trigger(
      leftMin: 0,
      leftMax: 255,
      rightMin: 0,
      rightMax: 255,
    ),
  );

  Future<void> _leftTriggerCurve() => _invoke(
    '左扳机曲线',
    () => _session!.leftTriggerCurve(
      cgPoints: const [
        GmacroCurvePoint(x: 0, y: 0),
        GmacroCurvePoint(x: 100, y: 100),
      ],
    ),
  );

  Future<void> _rightTriggerCurve() => _invoke(
    '右扳机曲线',
    () => _session!.rightTriggerCurve(
      cgPoints: const [
        GmacroCurvePoint(x: 0, y: 0),
        GmacroCurvePoint(x: 100, y: 100),
      ],
    ),
  );

  Future<void> _triggerQuickSwitchOn() => _invoke(
    '快速扳机 开',
    () => _session!.triggerQuickSwitch(leftOn: true, rightOn: true),
  );

  Future<void> _triggerQuickSwitchOff() => _invoke(
    '快速扳机 关',
    () => _session!.triggerQuickSwitch(leftOn: false, rightOn: false),
  );

  Future<void> _getTriggerQuickSwitch() =>
      _invoke('查询快速扳机', () => _session!.getTriggerQuickSwitch());

  Future<void> _triggerLinearOutput() => _invoke(
    '扳机线性输出',
    () => _session!.triggerLinearOutput(
      leftMode: 1,
      leftThreshold: 128,
      rightMode: 1,
      rightThreshold: 128,
    ),
  );

  Future<void> _startTriggerCalibration() =>
      _invoke('开始扳机校准', () => _session!.startTriggerCalibration());

  Future<void> _endTriggerCalibration() =>
      _invoke('结束扳机校准', () => _session!.endTriggerCalibration());

  // 振动
  Future<void> _setVibrationLevel() => _invoke(
    '设置振动等级',
    () => _session!.setVibrationLevel(left: 50, right: 50),
  );

  Future<void> _testVibration() => _invoke(
    '测试振动',
    () => _session!.testVibration(
      left: 128,
      right: 128,
      position: VibrationPosition.both,
    ),
  );

  // 连发
  Future<void> _querySupportedTurboKeys() =>
      _invoke('查询连发按键', () => _session!.querySupportedTurboKeys(profile: 0));

  Future<void> _setTurboDatas() => _invoke(
    '设置连发速率',
    () => _session!.setTurboDatas(
      keyTurbos: [
        KeyTurboPayload(
          key: GamepadKey.a,
          turbo: TurboMode.fullAuto,
          speed: 10,
        ),
      ],
    ),
  );

  // 按键映射
  Future<void> _setKeyMappings() => _invoke(
    '设置手柄按键映射',
    () => _session!.setKeyMappings(
      keyMappings: [
        GamepadKeyMappingPayload(
          original: GamepadKey.a,
          mapped: GamepadKey.b,
        ),
      ],
    ),
  );

  Future<void> _setMouseKeyMappings() => _invoke(
    '设置鼠标按键映射',
    () => _session!.setMouseKeyMappings(
      keyMappings: [MouseKeyMappingPayload(original: GamepadKey.a, mapped: 1)],
    ),
  );

  Future<void> _setKeyboardKeyMappings() => _invoke(
    '设置键盘按键映射',
    () => _session!.setKeyboardKeyMappings(
      keyMappings: [
        KeyboardKeyMappingPayload(original: GamepadKey.a, mapped: 0x04),
      ],
    ),
  );

  Future<void> _setMultiKeyMapping() => _invoke(
    '设置多类型映射',
    () => _session!.setMultiKeyMapping(
      original: GamepadKey.a,
      mappedKeys: [MappedKeyPayload.gamepad(values: [GamepadKey.b])],
    ),
  );

  // 宏设置
  Future<void> _queryMacroKeys() =>
      _invoke('查询宏按键', () => _session!.queryMacroKeys(profile: 0));

  Future<void> _queryMacroTimeRange() =>
      _invoke('查询宏时间范围', () => _session!.queryMacroTimeRange(profile: 0));

  Future<void> _queryMacroMaxGroups() =>
      _invoke('查询宏最大组数', () => _session!.queryMacroMaxGroups(profile: 0));

  Future<void> _setMacroInterval() => _invoke(
    '设置宏间隔',
    () => _session!.setMacroInterval(
      profile: 0,
      key: GamepadKey.m1,
      intervalTime: 100,
    ),
  );

  Future<void> _setMacroKeys() => _invoke(
    '设置宏子按键',
    () => _session!.setMacroKeys(
      macroKey: MacroKeyPayload(
        value: GamepadKey.m1,
        cycle: MacroCycleMode.loop,
        intervalTime: 0,
        comKeys: [
          MacroComKeyPayload(
            keys: [GamepadKey.l2],
            keepTime: 59999,
            intervalTime: 50,
          ),
        ],
      ),
    ),
  );

  Future<void> _startRecord() =>
      _invoke('开始录制宏', () => _session!.startRecord());

  Future<void> _endRecord() =>
      _invoke('结束录制宏', () => _session!.endRecord());

  // 体感
  Future<void> _queryGyroTriggerKeys() =>
      _invoke('查询体感触发按键', () => _session!.queryGyroTriggerKeys(profile: 0));

  Future<void> _queryGyroMappingModes() =>
      _invoke('查询体感映射模式', () => _session!.queryGyroMappingModes(profile: 0));

  Future<void> _setMotion() => _invoke(
    '设置体感参数',
    () => _session!.setMotion(
      motionEnabled: true,
      mappingEnabled: false,
      triggerMode: MotionTriggerMode.continuous,
      triggerKey: GamepadKey.a,
      deadZone: 10,
      sensitivity: 500,
      mappingMode: MotionMappingMode.rightStick,
    ),
  );

  Future<void> _setMotionSecondary() => _invoke(
    '设置体感二级灵敏度',
    () => _session!.setMotionSecondary(
      isOn: false,
      triggerMode: MotionTriggerMode.continuous,
      triggerKey: GamepadKey.a,
      sensitivity: 300,
    ),
  );

  Future<void> _setGyroXYInvert() =>
      _invoke('XY 轴反转', () => _session!.setGyroXYInvert(xOn: true, yOn: false));

  Future<void> _updateGyroXYRatio() =>
      _invoke('设置 XY 比例', () => _session!.updateGyroXYRatio(gyroXYRatio: 50));

  Future<void> _updateGyroMappingType() => _invoke(
    '设置映射类型',
    () => _session!.updateGyroMappingType(
      gyroMappingType: GyroMappingType.continuous,
    ),
  );

  Future<void> _startGyroCalibration() =>
      _invoke('开始陀螺仪校准', () => _session!.startGyroCalibration());

  Future<void> _endGyroCalibration() =>
      _invoke('结束陀螺仪校准', () => _session!.endGyroCalibration());

  // 休眠时间
  Future<void> _getSleepTime() =>
      _invoke('查询睡眠时间', () => _session!.getSleepTime(profile: 0));

  Future<void> _setSleepTime() =>
      _invoke('设置睡眠时间', () => _session!.setSleepTime(time: 300));

  // 灯光
  Future<void> _fetchLight() =>
      _invoke('查询灯光状态', () => _session!.fetchLight());

  Future<void> _fetchLightPosition() =>
      _invoke('查询灯光位置', () => _session!.fetchLightPosition());

  Future<void> _fetchSupportedLightEffects() =>
      _invoke('查询支持特效', () => _session!.fetchSupportedLightEffects());

  Future<void> _fetchCurrentLightEffect() =>
      _invoke('查询当前特效', () => _session!.fetchCurrentLightEffect());

  Future<void> _setLightColor() => _invoke(
    '设置灯组颜色',
    () => _session!.setLightColor(
      position: LightPosition.home,
      groupCount: 1,
      colors: [const LightColorPayload(red: 255, green: 0, blue: 0)],
    ),
  );

  Future<void> _setLightEffect() => _invoke(
    '设置灯光特效',
    () => _session!.setLightEffect(
      position: LightPosition.home,
      groupCount: 1,
      isOn: true,
      light: 80,
      speed: 50,
      mode: LightMajorMode.breath,
      subMode: 1,
      colors: [const LightColorPayload(red: 0, green: 0, blue: 255)],
    ),
  );

  Future<void> _setLightConfig() => _invoke(
    '设置灯效配置',
    () => _session!.setLightConfig(
      effect: 2,
      colorR: 0,
      colorG: 255,
      colorB: 0,
      light: 80,
      speed: 50,
      profile: 0,
    ),
  );

  // 充电
  Future<void> _fetchChargingDock() =>
      _invoke('查询充电底座开关', () => _session!.fetchChargingDock());

  Future<void> _updateChargingDockOn() =>
      _invoke('开启充电底座', () => _session!.updateChargingDock(isOn: true));

  Future<void> _updateChargingDockOff() =>
      _invoke('关闭充电底座', () => _session!.updateChargingDock(isOn: false));

  // OTA
  Future<void> _startOta() async {
    final session = _session;
    if (session == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('OTA 测试'),
        content: const Text(
          '点击确认后选择本地 .bin 固件文件，\n'
          'Flutter 会将固件字节传给原生层执行 OTA。\n\n'
          'OTA 进度通过 ProtocolBusy 事件上报，\n'
          '完成后收到 ProtocolReady。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('选择固件'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['bin'],
      withData: true,
    );
    if (!mounted) return;
    final bytes = picked?.files.firstOrNull?.bytes;
    if (bytes == null) {
      _log.warn('No firmware file selected, OTA cancelled');
      _setTip('⚠ 未选择固件文件，已取消');
      return;
    }

    _log.info('Starting OTA with firmware size: ${bytes.length} bytes');
    _setTip('▶ startOta（固件 ${bytes.length} bytes）');
    try {
      setState(() {
        _isOtaRunning = true;
        _otaProgress = 0;
        _otaStatusMessage = '正在初始化 OTA...';
      });
      await session.startOta(bytes);
      _log.info('OTA command initiated');
      _setTip('◀ OTA 已启动');
    } catch (e, s) {
      _log.error('OTA failed to start', error: e, stackTrace: s);
      setState(() {
        _isOtaRunning = false;
        _otaStatusMessage = 'OTA 启动失败: $e';
      });
      _setTip('◀ 错误: $e');
    }
  }

  // ── build ────────────────────────────────────────────────────────────────

  bool get _canOperate =>
      _session != null &&
      !_isAttaching &&
      !_isOtaRunning &&
      (_isProtocolReady || _isConnected);

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    final device = widget.transport.device;

    return SubPageScaffold(
      title: device.name.isEmpty ? '设备会话' : device.name,
      subtitle: '${device.kind.name.toUpperCase()} · ${device.id}',
      child: Column(
        children: [
          // OTA 进度
          if (_isOtaRunning || _otaStatusMessage.isNotEmpty)
            Container(
              width: double.infinity,
              color: theme.colors.brandPrimary.withValues(alpha: 0.1),
              padding: EdgeInsets.all(theme.spacing.md),
              child: Column(
                children: [
                  Host4Text(_otaStatusMessage, role: Host4TextRole.heading),
                  SizedBox(height: theme.spacing.sm),
                  Slider(
                    value: _otaProgress,
                    onChanged: null,
                    min: 0,
                    max: 1,
                  ),
                  if (!_isOtaRunning && _otaStatusMessage.contains('成功'))
                    TextButton(
                      onPressed: () => setState(() => _otaStatusMessage = ''),
                      child: const Text('确定'),
                    ),
                ],
              ),
            ),

          // tip label (60px fixed height)
          _TipLabel(
            text: _tipText.isEmpty
                ? (_isAttaching ? '正在挂载协议…' : '点击下方操作项执行调用')
                : _tipText,
            isConnected: _isConnected,
            isAttaching: _isAttaching,
          ),

          // 可展开的 section 列表
          Expanded(
            child: ListView.builder(
              itemCount: _sections.fold<int>(
                0,
                (sum, s) => sum + 1 + (s.expanded ? s.actions.length : 0),
              ),
              itemBuilder: (context, index) {
                int cursor = 0;
                for (final section in _sections) {
                  if (index == cursor) {
                    return _SectionHeader(
                      title: section.title,
                      expanded: section.expanded,
                      onTap: () => setState(() => section.expanded = !section.expanded),
                    );
                  }
                  cursor++;
                  if (section.expanded) {
                    for (final action in section.actions) {
                      if (index == cursor) {
                        final selected = _selectedTitle == action.title;
                        return _ActionRow(
                          title: action.title,
                          selected: selected,
                          enabled: _canOperate,
                          onTap: () async {
                            setState(() => _selectedTitle = action.title);
                            await action.invoke();
                          },
                        );
                      }
                      cursor++;
                    }
                  }
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── sub-widgets ─────────────────────────────────────────────────────────────

class _TipLabel extends StatelessWidget {
  const _TipLabel({
    required this.text,
    required this.isConnected,
    required this.isAttaching,
  });

  final String text;
  final bool isConnected;
  final bool isAttaching;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    return Container(
      height: 60,
      width: double.infinity,
      color: theme.colors.surfaceMuted,
      padding: EdgeInsets.symmetric(horizontal: theme.spacing.page),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isConnected && !isAttaching
                  ? theme.colors.success
                  : theme.colors.warning,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: theme.spacing.sm),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.caption.toTextStyle(theme.colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.expanded,
    required this.onTap,
  });

  final String title;
  final bool expanded;
  final VoidCallback onTap;

  static const _headerColor = Color(0xFF80B1DA);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        color: _headerColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              expanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.title,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  static const _selectedColor = Color(0xFF3674B5);

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.page,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.colors.borderDefault, width: 0.5),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: !enabled
                ? theme.colors.textSecondary
                : selected
                    ? _selectedColor
                    : theme.colors.textPrimary,
          ),
        ),
      ),
    );
  }
}
