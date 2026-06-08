import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:host4_flutter_gmacro/host4_flutter_gmacro.dart';
import 'package:host4_flutter_protocol/host4_flutter_protocol.dart';

import '../../widgets/sub_page_scaffold.dart';
import 'gmacro_input_debug_page.dart';

class GmacroApiTestPage extends StatefulWidget {
  const GmacroApiTestPage({super.key, this.session});

  final GmacroSession? session;

  @override
  State<GmacroApiTestPage> createState() => _GmacroApiTestPageState();
}

class _GmacroApiTestPageState extends State<GmacroApiTestPage> {
  final Map<String, _TestResult> _results = {};
  StreamSubscription<ProtocolEvent>? _eventSub;
  final List<String> _events = [];

  static const List<GmacroCurvePoint> _demoCurve = [
    GmacroCurvePoint(x: 0, y: 0),
    GmacroCurvePoint(x: 50, y: 60),
    GmacroCurvePoint(x: 100, y: 100),
  ];

  // @override
  // void initState() {
  //   super.initState();
  //   _eventSub = widget.session?.events.listen((event) {
  //     if (!mounted) return;
  //     setState(() {
  //       _events.insert(
  //         0,
  //         '[${DateTime.now().toIso8601String()}] ${event.runtimeType}: $event',
  //       );
  //       if (_events.length > 50) {
  //         _events.removeLast();
  //       }
  //     });
  //   });
  // }

  //2026.6.1修改
  @override
  void initState() {
    super.initState();

    _eventSub = widget.session?.events.listen(_handleProtocolEvent);
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }

  //2026.6.1新增
  void _appendEvent(String message) {
    if (!mounted) return;
    setState(() {
      _events.insert(0, '[${DateTime.now().toIso8601String()}] $message');
      if (_events.length > 50) {
        _events.removeLast();
      }
    });
  }

  void _handleProtocolEvent(ProtocolEvent event) {
    switch (event) {
      case ProtocolReady():
        _appendEvent('ProtocolReady');
      case ProtocolBusy(reason: final reason):
        _appendEvent('ProtocolBusy: $reason');
      case ProtocolError(failure: final failure):
        _appendEvent('ProtocolError: ${failure.code} - ${failure.message}');
    }
  }

  void _openInputDebugPage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const GmacroInputDebugPage()));
  }

  Future<void> _run(
    String key,
    String label,
    Future<Object?> Function() action,
  ) async {
    setState(() => _results[key] = _TestResult.loading());

    try {
      final result = await action();
      final message = _describeResult(key, result);
      if (!mounted) return;

      setState(() => _results[key] = _TestResult.success(message));
      await _showResultSheet(title: label, content: message, isError: false);
    } catch (e) {
      final message = e.toString();
      if (!mounted) return;

      setState(() => _results[key] = _TestResult.error(message));
      await _showResultSheet(title: label, content: message, isError: true);
    }
  }

  Future<void> _showResultSheet({
    required String title,
    required String content,
    required bool isError,
  }) {
    final colors = Theme.of(context).colorScheme;

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Material(
              color: colors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: colors.outlineVariant),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isError
                                ? colors.errorContainer
                                : colors.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isError ? '调用失败' : '调用成功',
                            style: TextStyle(
                              color: isError
                                  ? colors.onErrorContainer
                                  : colors.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SelectableText(
                          content,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.45,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<Map<String, Object?>> _rawInvoke(
    String method, {
    Map<String, Object?> arguments = const {},
  }) {
    return widget.session!.invoke(method, arguments: arguments);
  }

  String _describeResult(String key, Object? result) {
    if (_isAckOnlyResult(result)) {
      final map = _mapOf(result);
      return 'ACK success (result=0)';
    }

    final rawPayload = _unwrapPayload(result);
    final parsedPayload = _coerceResult(key, result);

    final rawText = _formatResultForDisplay(rawPayload);
    final parsedText = _formatResultForDisplay(parsedPayload);

    if (parsedText != rawText) {
      return 'Parsed:\n$parsedText\n\nRaw:\n$rawText';
    }
    return rawText;
  }

  String _formatResultForDisplay(Object? value) {
    if (value == null) {
      return '<null>';
    }

    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? '<empty string>' : trimmed;
    }

    if (value is Map || value is List) {
      try {
        return const JsonEncoder.withIndent('  ').convert(value);
      } catch (_) {
        final text = value.toString();
        return text.trim().isEmpty ? '<empty result>' : text;
      }
    }

    final text = value.toString();
    return text.trim().isEmpty ? '<empty result>' : text;
  }

  bool _isAckOnlyResult(Object? value) {
    final map = _mapOf(value);
    if (map == null || map.length != 1) {
      return false;
    }

    final result = map['result'];
    return result == 0 ||
        result == 0.0 ||
        result == 0x50 ||
        result == 80 ||
        result == 80.0;
  }

  Object? _coerceResult(String key, Object? result) {
    final payload = _unwrapPayload(result);

    try {
      switch (key) {
        case 'querySupportedTurboKeys':
          final map = _mapOf(payload);
          if (map != null) {
            return TurboSupportKeyPayload.fromMap(map);
          }
          final list = _mapListOf(payload);
          if (list != null) {
            return list.map(TurboSupportKeyPayload.fromMap).toList();
          }
          return payload;

        case 'queryMappableKeys':
          final map = _mapOf(payload);
          return map == null ? payload : MappableKeysPayload.fromMap(map);

        case 'queryMappableGamepadKeys':
        case 'queryGyroTriggerKeys':
          final map = _mapOf(payload);
          return map == null ? payload : GamepadKeysPayload.fromMap(map);

        case 'queryCurrentMapping':
          final map = _mapOf(payload);
          return map == null ? payload : CurrentMappingPayload.fromMap(map);

        case 'queryGyroMappingModes':
          final map = _mapOf(payload);
          return map == null ? payload : GyroMappingModesPayload.fromMap(map);

        case 'queryMacroKeys':
        case 'queryMacroRecordableKeys':
          final map = _mapOf(payload);
          return map == null ? payload : MacroKeysPayload.fromMap(map);

        case 'queryMacroTimeRange':
          final map = _mapOf(payload);
          return map == null ? payload : MacroTimeRangePayload.fromMap(map);

        case 'queryCurrentMacro':
          // iOS 返回格式: {"macros": [{value, cycle, intervalTime, comKeys}, ...]}
          final raw = _mapOf(payload);
          final macrosList = raw?['macros'] as List?;
          if (macrosList != null) {
            return macrosList
                .cast<Map<dynamic, dynamic>>()
                .map(MacroKeyPayload.fromMap)
                .toList();
          }
          // Android 兼容格式
          final map = _mapOf(payload);
          if (map != null &&
              map.containsKey('value') &&
              map.containsKey('comKeys')) {
            return MacroKeyPayload.fromMap(map);
          }
          final list = _mapListOf(payload);
          if (list != null) {
            return list.map(MacroKeyPayload.fromMap).toList();
          }
          return payload;

        case 'queryAllMultiMappings':
          return _parseAllMultiMappings(payload);

        case 'queryMultiMapping':
          return _parseSingleMultiMapping(payload);

        default:
          return payload;
      }
    } catch (_) {
      return payload;
    }
  }

  Object? _unwrapPayload(Object? result) {
    final map = _mapOf(result);
    if (map == null) return result;

    for (final key in const ['payload', 'data', 'result', 'value']) {
      final nested = map[key];
      if (_hasVisibleContent(nested)) {
        return nested;
      }
    }
    return result;
  }

  bool _hasVisibleContent(Object? value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is Map) return value.isNotEmpty;
    if (value is List) return value.isNotEmpty;
    return true;
  }

  Map<String, Object?>? _mapOf(Object? value) {
    if (value is Map<String, Object?>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return null;
  }

  List<Map<String, Object?>>? _mapListOf(Object? value) {
    if (value is! List) return null;
    return value.map(_mapOf).whereType<Map<String, Object?>>().toList();
  }

  Object? _parseAllMultiMappings(Object? payload) {
    final map = _mapOf(payload);
    if (map == null) return payload;

    return map.map((key, value) {
      final item = _mapOf(value);
      if (item == null) return MapEntry(key, value);

      final mappedKeys = _mapListOf(
        item['mappedKeys'],
      )?.map(MappedKeyPayload.fromMap).toList();

      return MapEntry(key, {
        'original': item['original'],
        'mappedKeys': mappedKeys ?? item['mappedKeys'],
      });
    });
  }

  Object? _parseSingleMultiMapping(Object? payload) {
    final item = _mapOf(payload);
    if (item == null) return payload;

    final mappedKeys = _mapListOf(
      item['mappedKeys'],
    )?.map(MappedKeyPayload.fromMap).toList();

    return {
      'original': item['original'],
      'mappedKeys': mappedKeys ?? item['mappedKeys'],
    };
  }

  @override
  Widget build(BuildContext context) {
    final sections = _buildSections();
    final isPreview = widget.session == null;

    return SubPageScaffold(
      title: 'GMacro API 测试',
      subtitle: isPreview ? '预览模式（未连接设备）' : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isPreview)
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: _EmptyHint(text: '当前为预览模式，连接设备后可执行接口调用'),
            ),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: _SectionHeader(title: '协议事件流'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: _buildFixedEventPanel(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: OutlinedButton.icon(
              onPressed: _openInputDebugPage,
              icon: const Icon(Icons.gamepad_outlined, size: 16),
              label: const Text('打开统一输入调试页'),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              children: [
                for (final section in sections) ...[
                  _SectionHeader(title: section.title),
                  ...section.items.map(
                    (item) => _ApiTile(
                      label: item.label,
                      result: _results[item.key],
                      onTap: () => _run(item.key, item.label, item.action),
                      enabled: !isPreview,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedEventPanel() {
    if (_events.isEmpty) {
      return const _EmptyHint(text: '暂无事件');
    }

    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: ListView.builder(
        itemCount: _events.length,
        itemBuilder: (_, i) => Text(
          _events[i],
          style: const TextStyle(
            color: Colors.greenAccent,
            fontSize: 11,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }

  List<_Section> _buildSections() {
    final s = widget.session;

    return [
      _Section(
        title: '设备基础',
        items: [
          _Item('fetchDeviceVersion', '查询设备版本', () => s!.fetchDeviceVersion()),
          _Item(
            'fetchMobapadDeviceInfo',
            '查询设备信息 (profile=0)',
            () => s!.fetchMobapadDeviceInfo(profile: 0),
          ),
          _Item('resetDevice', '恢复默认设置', () => s!.resetDevice()),
          _Item('switchToNormalMode', '切换普通模式', () => s!.switchToNormalMode()),
          _Item('switchToTestMode', '切换测试模式', () => s!.switchToTestMode()),
          _Item('switchToConfigMode', '切换配置模式', () => s!.switchToConfigMode()),
        ],
      ),
      _Section(
        title: '上报率 / 底座',
        items: [
          _Item('fetchReportRate', '查询上报率', () => s!.fetchReportRate()),
          _Item(
            'updateReportRate_125',
            '设置上报率 125Hz',
            () => s!.updateReportRate(rate: 125),
          ),
          _Item(
            'updateReportRate_1000',
            '设置上报率 1000Hz',
            () => s!.updateReportRate(rate: 1000),
          ),
          _Item('fetchChargingDock', '查询充电底座开关', () => s!.fetchChargingDock()),
          _Item(
            'updateChargingDock_on',
            '开启充电底座',
            () => s!.updateChargingDock(isOn: true),
          ),
          _Item(
            'updateChargingDock_off',
            '关闭充电底座',
            () => s!.updateChargingDock(isOn: false),
          ),
        ],
      ),
      _Section(
        title: '灯光',
        items: [
          _Item('fetchLight', '查询灯光状态', () => s!.fetchLight()),
          _Item(
            'fetchLightPosition',
            '查询灯光位置及组数',
            () => s!.fetchLightPosition(),
          ),
          _Item(
            'fetchSupportedLightEffects',
            '查询支持的灯光特效',
            () => s!.fetchSupportedLightEffects(),
          ),
          _Item(
            'fetchCurrentLightEffect',
            '查询当前灯光特效',
            () => s!.fetchCurrentLightEffect(),
          ),
          _Item(
            'fetchCurrentLightConfig',
            '查询当前灯效配置',
            () => s!.fetchCurrentLightConfig(),
          ),
          _Item(
            'setLightConfig',
            '设置红色单色灯效',
            () => s!.setLightConfig(
              effect: 1,
              colorR: 255,
              colorG: 0,
              colorB: 0,
              light: 80,
              speed: 50,
              profile: 0,
            ),
          ),
          _Item(
            'setLightColor',
            '设置左摇杆光圈颜色',
            () => s!.setLightColor(
              position: LightPosition.leftStickRing,
              groupCount: 1,
              colors: const [LightColorPayload(red: 0, green: 120, blue: 255)],
            ),
          ),
          _Item(
            'setLightEffect',
            '设置左摇杆常亮特效',
            () => s!.setLightEffect(
              position: LightPosition.leftStickRing,
              groupCount: 1,
              isOn: true,
              light: 80,
              speed: 50,
              mode: LightMajorMode.steady,
              subMode: 0,
              colors: const [LightColorPayload(red: 255, green: 255, blue: 0)],
            ),
          ),
        ],
      ),
      _Section(
        title: '扳机',
        items: [
          _Item(
            'trigger',
            '设置扳机行程',
            () => s!.trigger(
              leftMin: 0,
              leftMax: 100,
              rightMin: 0,
              rightMax: 100,
            ),
          ),
          _Item(
            'leftTriggerCurve',
            '设置左扳机曲线',
            () => s!.leftTriggerCurve(cgPoints: _demoCurve),
          ),
          _Item(
            'rightTriggerCurve',
            '设置右扳机曲线',
            () => s!.rightTriggerCurve(cgPoints: _demoCurve),
          ),
          _Item(
            'triggerQuickSwitch',
            '设置快速扳机开关',
            () => s!.triggerQuickSwitch(leftOn: true, rightOn: true),
          ),
          _Item(
            'getTriggerQuickSwitch',
            '查询快速扳机开关',
            () => s!.getTriggerQuickSwitch(),
          ),
          _Item(
            'triggerLinearOutput',
            '设置线性输出',
            () => s!.triggerLinearOutput(
              leftMode: 1,
              leftThreshold: 50,
              rightMode: 2,
              rightThreshold: 50,
            ),
          ),
          _Item(
            'updateTriggerTestVibrationSwitch',
            '设置扳机测试震动开关',
            () =>
                s!.updateTriggerTestVibrationSwitch(triggerTestVibration: true),
          ),
          _Item(
            'fetchTriggerTestVibrationSwitch',
            '查询扳机测试震动开关',
            () => s!.fetchTriggerTestVibrationSwitch(),
          ),
          _Item(
            'updateTriggerVibration',
            '设置扳机震动开关',
            () => s!.updateTriggerVibration(triggerVibration: true),
          ),
          _Item(
            'fetchTriggerVibration',
            '查询扳机震动',
            () => s!.fetchTriggerVibration(),
          ),
          _Item(
            'startTriggerCalibration',
            '开始扳机校准',
            () => s!.startTriggerCalibration(),
          ),
          _Item(
            'endTriggerCalibration',
            '结束扳机校准',
            () => s!.endTriggerCalibration(),
          ),
        ],
      ),
      _Section(
        title: '摇杆',
        items: [
          _Item(
            'updateRockerLinear',
            '设置摇杆线性',
            () => s!.updateRockerLinear(
              leftMin: 0,
              leftMax: 100,
              leftXFlip: false,
              leftYFlip: false,
              rightMin: 0,
              rightMax: 100,
              rightXFlip: false,
              rightYFlip: false,
            ),
          ),
          _Item(
            'updateLeftRocker3DCurve',
            '设置左摇杆曲线',
            () => s!.updateLeftRocker3DCurve(cgPoints: _demoCurve),
          ),
          _Item(
            'updateRightRocker3DCurve',
            '设置右摇杆曲线',
            () => s!.updateRightRocker3DCurve(cgPoints: _demoCurve),
          ),
          _Item(
            'rockerDeadZoneCompensation',
            '设置摇杆死区补偿',
            () => s!.rockerDeadZoneCompensation(left: 500, right: 500),
          ),
          _Item(
            'rockerDeadZoneRegressionComp',
            '设置摇杆死区回归补偿',
            () => s!.rockerDeadZoneRegressionComp(left: 500, right: 500),
          ),
          _Item(
            'rockerTriggerType',
            '设置摇杆曲线触发方式',
            () => s!.rockerTriggerType(
              leftTriggerMode: CurveTriggerMode.click,
              leftGamepadKey: GamepadKey.a,
              rightTriggerMode: CurveTriggerMode.hold,
              rightGamepadKey: GamepadKey.b,
            ),
          ),
          _Item(
            'rockerOutputGraphics',
            '设置摇杆输出轨迹',
            () => s!.rockerOutputGraphics(
              left: OutputGraphics.circle,
              right: OutputGraphics.roundedRect,
            ),
          ),
          _Item(
            'updateRockerAdditional',
            '设置摇杆附加功能',
            () => s!.updateRockerAdditional(
              leftDeadZone: 5,
              leftOutMax: 100,
              leftCurveApply: 0,
              leftCurveApplyKey: GamepadKey.a,
              leftLineCorrection: 0,
              rightDeadZone: 5,
              rightOutMax: 100,
              rightCurveApply: 1,
              rightCurveApplyKey: GamepadKey.b,
              rightLineCorrection: 1,
            ),
          ),
          _Item(
            'startRockerCalibration',
            '开始摇杆校准',
            () => s!.startRockerCalibration(),
          ),
          _Item(
            'endRockerCalibration',
            '结束摇杆校准',
            () => s!.endRockerCalibration(),
          ),
        ],
      ),
      _Section(
        title: '震动',
        items: [
          _Item(
            'setVibrationLevel',
            '设置震动等级',
            () => s!.setVibrationLevel(left: 50, right: 50),
          ),
          _Item(
            'testVibration',
            '测试双侧震动',
            () => s!.testVibration(
              left: 128,
              right: 128,
              position: VibrationPosition.both,
            ),
          ),
        ],
      ),
      _Section(
        title: 'Other / 新增接口',
        items: [
          _Item(
            'queryVibrateOpen',
            '查询马达开关状态',
            () => s!.queryVibrateOpen(),
          ),
          _Item(
            'switchVibrateOpen_on',
            '设置马达开关状态：开(status=1)',
            () => s!.switchVibrateOpen(status: 1),
          ),
          _Item(
            'switchVibrateOpen_off',
            '设置马达开关状态：关(status=0)',
            () => s!.switchVibrateOpen(status: 0),
          ),
          _Item(
            'queryWorkStyle',
            '查询手柄工作模式',
            () => s!.queryWorkStyle(),
          ),
          _Item(
            'switchWorkStyle',
            '设置手柄工作模式(mode=1)',
            () => s!.switchWorkStyle(mode: 1),
          ),
          _Item(
            'queryOutputMode',
            '查询当前手柄模式',
            () => s!.queryOutputMode(),
          ),
          _Item(
            'switchOutputMode',
            '设置当前手柄模式(mode=1)',
            () => s!.switchOutputMode(mode: 1),
          ),
          _Item(
            'sendHandleBeta',
            '测试模式切换配置页(profile=0)',
            () => s!.sendHandleBeta(profile: 0),
          ),
          _Item(
            'switchHandleConfig',
            '切换手柄配置页(profile=0)',
            () => s!.switchHandleConfig(profile: 0),
          ),
          _Item(
            'switchHandleCallbacks',
            '开关手柄功能以及回调(method=1)',
            () => s!.switchHandleCallbacks(method: 1),
          ),
          _Item(
            'queryLinerTrigger',
            '查询左右扳机线性输出',
            () => s!.queryLinerTrigger(),
          ),
          _Item(
            'switchLinerTrigger',
            '设置左右扳机线性输出(mode=1)',
            () => s!.switchLinerTrigger(mode: 1),
          ),
          _Item(
            'queryLightingEffectPantas',
            '查询当前灯效（Pantas）',
            () => s!.queryLightingEffectPantas(),
          ),
          _Item(
            'setLightGroupEffectPantas',
            '设置当前灯效（Pantas）',
            () => s!.setLightGroupEffectPantas(
              open: true,
              mode: 1,
              brightness: 80,
              colorR: 255,
              colorG: 80,
              colorB: 0,
            ),
          ),
        ],
      ),
      _Section(
        title: '宏',
        items: [
          _Item(
            'queryCurrentMacro',
            '查询当前宏 (profile=0)',
            () => s!.queryCurrentMacro(profile: 0),
          ),
          _Item(
            'queryMacroKeys',
            '查询宏按键 (profile=0)',
            () => s!.queryMacroKeys(profile: 0),
          ),
          _Item(
            'queryMacroRecordableKeys',
            '查询可录制按键 (profile=0)',
            () => s!.queryMacroRecordableKeys(profile: 0),
          ),
          _Item(
            'queryMacroTimeRange',
            '查询宏时间范围 (profile=0)',
            () => s!.queryMacroTimeRange(profile: 0),
          ),
          _Item(
            'queryMacroMaxGroups',
            '查询宏最大组数 (profile=0)',
            () => s!.queryMacroMaxGroups(profile: 0),
          ),
          _Item(
            'setMacroInterval',
            '设置宏循环间隔',
            () => s!.setMacroInterval(
              profile: 0,
              key: GamepadKey.m1,
              intervalTime: 60,
            ),
          ),
          _Item(
            'setMacroKeys',
            '设置宏定义子按键',
            () => s!.setMacroKeys(
              macroKey: const MacroKeyPayload(
                value: GamepadKey.m1,
                cycle: MacroCycleMode.loop,
                intervalTime: 60,
                comKeys: [
                  MacroComKeyPayload(
                    keys: [GamepadKey.a],
                    keepTime: 100,
                    intervalTime: 40,
                  ),
                  MacroComKeyPayload(
                    keys: [GamepadKey.b],
                    keepTime: 100,
                    intervalTime: 40,
                  ),
                ],
              ),
            ),
          ),
          _Item('startRecord', '开始录制宏', () => s!.startRecord()),
          _Item('endRecord', '结束录制宏', () => s!.endRecord()),
        ],
      ),
      _Section(
        title: '按键映射',
        items: [
          _Item(
            'queryMappableKeys',
            '查询可映射按键 (profile=0)',
            () => s!.queryMappableKeys(profile: 0),
          ),
          _Item(
            'queryMappableGamepadKeys',
            '查询可映射手柄按键 (profile=0)',
            () => s!.queryMappableGamepadKeys(profile: 0),
          ),
          _Item(
            'setKeyMappings',
            '设置手柄按键映射',
            () => s!.setKeyMappings(
              keyMappings: const [
                GamepadKeyMappingPayload(
                  original: GamepadKey.a,
                  mapped: GamepadKey.b,
                ),
              ],
            ),
          ),
          _Item(
            'setMouseKeyMappings',
            '设置鼠标按键映射',
            () => s!.setMouseKeyMappings(
              keyMappings: const [
                MouseKeyMappingPayload(original: GamepadKey.m1, mapped: 1),
              ],
            ),
          ),
          _Item(
            'setKeyboardKeyMappings',
            '设置键盘按键映射',
            () => s!.setKeyboardKeyMappings(
              keyMappings: const [
                KeyboardKeyMappingPayload(original: GamepadKey.m2, mapped: 4),
              ],
            ),
          ),
          _Item(
            'queryCurrentMapping',
            '查询当前映射 (profile=0)',
            () => s!.queryCurrentMapping(profile: 0),
          ),
          _Item(
            'setMultiKeyMapping',
            '设置多映射',
            () => s!.setMultiKeyMapping(
              original: GamepadKey.m3,
              mappedKeys: [
                MappedKeyPayload.gamepad(values: [GamepadKey.a]),
                MappedKeyPayload.mouse(values: [1]),
                MappedKeyPayload.keyboard(values: [4]),
              ],
            ),
          ),
          _Item(
            'queryAllMultiMappings',
            '查询全部多映射',
            () => s!.queryAllMultiMappings(),
          ),
          _Item(
            'queryMultiMapping',
            '查询单个多映射 (M3)',
            () => s!.queryMultiMapping(original: GamepadKey.m3),
          ),
        ],
      ),
      _Section(
        title: 'Turbo / 连发',
        items: [
          _Item(
            'querySupportedTurboKeys',
            '查询支持连发的按键 (profile=0)',
            () => s!.querySupportedTurboKeys(profile: 0),
          ),
          _Item(
            'setTurboDatas',
            '设置连发数据',
            () => s!.setTurboDatas(
              keyTurbos: const [
                KeyTurboPayload(
                  key: GamepadKey.a,
                  turbo: TurboMode.fullAuto,
                  speed: 10,
                ),
              ],
            ),
          ),
        ],
      ),
      _Section(
        title: '陀螺仪 / 体感',
        items: [
          _Item(
            'queryGyroTriggerKeys',
            '查询体感触发键 (profile=0)',
            () => s!.queryGyroTriggerKeys(profile: 0),
          ),
          _Item(
            'queryGyroMappingModes',
            '查询体感映射模式 (profile=0)',
            () => s!.queryGyroMappingModes(profile: 0),
          ),
          _Item(
            'setMotion',
            '设置体感参数',
            () => s!.setMotion(
              motionEnabled: true,
              mappingEnabled: true,
              triggerMode: MotionTriggerMode.click,
              triggerKey: GamepadKey.l2,
              deadZone: 10,
              sensitivity: 100,
              mappingMode: MotionMappingMode.rightStick,
            ),
          ),
          _Item(
            'setMotionSecondary',
            '设置体感二级灵敏度',
            () => s!.setMotionSecondary(
              isOn: true,
              triggerMode: MotionTriggerMode.hold,
              triggerKey: GamepadKey.l2,
              sensitivity: 120,
            ),
          ),
          _Item(
            'setMotionHorizontalAxis',
            '设置体感水平轴',
            () => s!.setMotionHorizontalAxis(axis: GyroAxis.zAxis),
          ),
          _Item(
            'fetchMotionHorizontalAxis',
            '查询体感水平轴',
            () => s!.fetchMotionHorizontalAxis(),
          ),
          _Item(
            'fetchGyroDeadZoneComp',
            '查询陀螺仪死区补偿',
            () => s!.fetchGyroDeadZoneComp(),
          ),
          _Item(
            'fetchGyroSensitivityCurve',
            '查询陀螺仪灵敏度曲线',
            () => s!.fetchGyroSensitivityCurve(),
          ),
          _Item(
            'fetchGyroSensitivity2',
            '查询陀螺仪二级灵敏度',
            () => s!.fetchGyroSensitivity2(),
          ),
          _Item(
            'setGyroXYInvert',
            '设置陀螺仪XY反转',
            () => s!.setGyroXYInvert(xOn: false, yOn: true),
          ),
          _Item('fetchGyroXYInvert', '查询陀螺仪XY反转', () => s!.fetchGyroXYInvert()),
          _Item(
            'setGyroDeadZone',
            '设置陀螺仪死区补偿',
            () => s!.setGyroDeadZone(compensate: 5),
          ),
          _Item(
            'setGyroSensitivityCurve',
            '设置陀螺仪灵敏度曲线',
            () => s!.setGyroSensitivityCurve(
              x1: 20,
              y1: 20,
              x2: 50,
              y2: 60,
              x3: 100,
              y3: 100,
            ),
          ),
          _Item(
            'updateGyroOuterDeadZone',
            '设置陀螺仪外圈死区',
            () => s!.updateGyroOuterDeadZone(gyroOuterDeadZone: 8),
          ),
          _Item(
            'fetchGyroOuterDeadZone',
            '查询陀螺仪外圈死区',
            () => s!.fetchGyroOuterDeadZone(),
          ),
          _Item(
            'startGyroCalibration',
            '开始陀螺仪校准',
            () => s!.startGyroCalibration(),
          ),
          _Item('endGyroCalibration', '结束陀螺仪校准', () => s!.endGyroCalibration()),
          _Item(
            'updateGyroXYRatio',
            '设置陀螺仪XY比例',
            () => s!.updateGyroXYRatio(gyroXYRatio: 50),
          ),
          _Item('fetchGyroXYRatio', '查询陀螺仪XY比例', () => s!.fetchGyroXYRatio()),
          _Item(
            'updateGyroMappingType',
            '设置陀螺仪映射类型',
            () => s!.updateGyroMappingType(
              gyroMappingType: GyroMappingType.instant,
            ),
          ),
          _Item(
            'fetchGyroMappingType',
            '查询陀螺仪映射类型',
            () => s!.fetchGyroMappingType(),
          ),
        ],
      ),
      _Section(
        title: '睡眠',
        items: [
          _Item(
            'getSleepTime',
            '查询睡眠时间 (profile=0)',
            () => s!.getSleepTime(profile: 0),
          ),
          _Item(
            'setSleepTime',
            '设置睡眠时间 300s',
            () => s!.setSleepTime(time: 300),
          ),
        ],
      ),
      _Section(
        title: '扩展 / 原生直通',
        items: [
          _Item(
            'fetchSupportCalibration',
            '查询是否支持校准',
            () => _rawInvoke('fetchSupportCalibration'),
          ),
          _Item(
            'fetchCalibrationKey',
            '查询校准按键',
            () => _rawInvoke('fetchCalibrationKey'),
          ),
          _Item(
            'updateSwitchLayout',
            '设置 ABXY 互换',
            () => _rawInvoke(
              'updateSwitchLayout',
              arguments: {'isOpen': true, 'locking': false, 'exchange': true},
            ),
          ),
          _Item(
            'startOta',
            '开始 OTA（空数据示例）',
            () => _rawInvoke('startOta', arguments: {'data': Uint8List(0)}),
          ),
        ],
      ),
    ];
  }
}

class _Section {
  const _Section({required this.title, required this.items});

  final String title;
  final List<_Item> items;
}

class _Item {
  const _Item(this.key, this.label, this.action);

  final String key;
  final String label;
  final Future<Object?> Function() action;
}

class _TestResult {
  _TestResult._({required this.state, this.message});

  factory _TestResult.loading() => _TestResult._(state: _State.loading);

  factory _TestResult.success(String msg) =>
      _TestResult._(state: _State.success, message: msg);

  factory _TestResult.error(String msg) =>
      _TestResult._(state: _State.error, message: msg);

  final _State state;
  final String? message;
}

enum _State { loading, success, error }

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.count});

  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            count != null ? '$title ($count)' : title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }
}

class _ApiTile extends StatelessWidget {
  const _ApiTile({
    required this.label,
    required this.result,
    required this.onTap,
    required this.enabled,
  });

  final String label;
  final _TestResult? result;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final r = result;

    Color? tileColor;
    Widget trailing;

    if (r == null) {
      trailing = enabled
          ? const Icon(Icons.chevron_right)
          : Icon(Icons.lock_outline, color: colors.outline, size: 18);
      if (!enabled) {
        tileColor = colors.surfaceContainerHighest.withOpacity(0.35);
      }
    } else if (r.state == _State.loading) {
      tileColor = colors.surfaceContainerHighest;
      trailing = const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (r.state == _State.success) {
      tileColor = colors.primaryContainer.withOpacity(0.4);
      trailing = const Icon(Icons.check_circle, color: Colors.green);
    } else {
      tileColor = colors.errorContainer.withOpacity(0.4);
      trailing = const Icon(Icons.error_outline, color: Colors.red);
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      color: tileColor,
      child: ListTile(
        dense: true,
        enabled: enabled,
        title: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: enabled ? null : colors.outline,
          ),
        ),
        subtitle: r != null
            ? Text(
                (r.message == null || r.message!.trim().isEmpty)
                    ? '<no display result>'
                    : r.message!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: r.state == _State.error
                      ? colors.error
                      : colors.onSurfaceVariant,
                ),
              )
            : (!enabled
                  ? Text(
                      '未连接设备，仅预览',
                      style: TextStyle(fontSize: 11, color: colors.outline),
                    )
                  : null),
        trailing: trailing,
        onTap: (!enabled || r?.state == _State.loading) ? null : onTap,
      ),
    );
  }
}
