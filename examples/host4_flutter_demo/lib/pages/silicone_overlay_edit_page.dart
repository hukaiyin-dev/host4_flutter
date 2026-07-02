import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:host4_flutter_physical_overlay/host4_flutter_physical_overlay.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';

class SiliconeOverlayEditPage extends StatefulWidget {
  const SiliconeOverlayEditPage({required this.spec, super.key});

  final PhysicalOverlaySpec spec;

  @override
  State<SiliconeOverlayEditPage> createState() =>
      _SiliconeOverlayEditPageState();
}

class _SiliconeOverlayEditPageState extends State<SiliconeOverlayEditPage> {
  OverlayEditMode _mode = OverlayEditMode.overall;
  OverlayCalibration _calibration = OverlayCalibration.identity;

  // Module mode: which module is selected for display purposes (all modules
  // respond to pan, but scale sliders target the selected one).
  String? _selectedModuleId;

  // Button mode: which button is selected for scale sliders.
  String? _selectedButtonId;

  // ── Scale slider helpers ──────────────────────────────────────────────────

  double get _scaleX {
    switch (_mode) {
      case OverlayEditMode.overall:
        return _calibration.patchScaleX;
      case OverlayEditMode.module:
        return _calibration.moduleScaleX[_selectedModuleId ?? ''] ?? 1.0;
      case OverlayEditMode.button:
        return _calibration.buttonScaleX[_selectedButtonId ?? ''] ?? 1.0;
    }
  }

  double get _scaleY {
    switch (_mode) {
      case OverlayEditMode.overall:
        return _calibration.patchScaleY;
      case OverlayEditMode.module:
        return _calibration.moduleScaleY[_selectedModuleId ?? ''] ?? 1.0;
      case OverlayEditMode.button:
        return _calibration.buttonScaleY[_selectedButtonId ?? ''] ?? 1.0;
    }
  }

  void _setScaleX(double v, PhysicalMetricsProvider provider) {
    setState(() {
      switch (_mode) {
        case OverlayEditMode.overall:
          _calibration = _normalizeCalibration(
            _calibration.copyWith(patchScaleX: v),
            provider,
          );
        case OverlayEditMode.module:
          if (_selectedModuleId == null) return;
          final next = _calibration.copyWith(
            moduleScaleX: {..._calibration.moduleScaleX, _selectedModuleId!: v},
          );
          final normalized = _normalizeButtonsInModule(
            _selectedModuleId!,
            next,
            provider,
          );
          if (_isModuleLayoutValid(_selectedModuleId!, normalized, provider)) {
            _calibration = normalized;
          }
        case OverlayEditMode.button:
          if (_selectedButtonId == null) return;
          final next = _calibration.copyWith(
            buttonScaleX: {..._calibration.buttonScaleX, _selectedButtonId!: v},
          );
          final moduleId = widget.spec.moduleIdForButton(_selectedButtonId!);
          if (moduleId == null) return;
          final normalized = _normalizeButtonsInModule(
            moduleId,
            next,
            provider,
          );
          if (!_buttonsOverlapInModule(moduleId, normalized, provider)) {
            _calibration = normalized;
          }
      }
    });
  }

  void _setScaleY(double v, PhysicalMetricsProvider provider) {
    setState(() {
      switch (_mode) {
        case OverlayEditMode.overall:
          _calibration = _normalizeCalibration(
            _calibration.copyWith(patchScaleY: v),
            provider,
          );
        case OverlayEditMode.module:
          if (_selectedModuleId == null) return;
          final next = _calibration.copyWith(
            moduleScaleY: {..._calibration.moduleScaleY, _selectedModuleId!: v},
          );
          final normalized = _normalizeButtonsInModule(
            _selectedModuleId!,
            next,
            provider,
          );
          if (_isModuleLayoutValid(_selectedModuleId!, normalized, provider)) {
            _calibration = normalized;
          }
        case OverlayEditMode.button:
          if (_selectedButtonId == null) return;
          final next = _calibration.copyWith(
            buttonScaleY: {..._calibration.buttonScaleY, _selectedButtonId!: v},
          );
          final moduleId = widget.spec.moduleIdForButton(_selectedButtonId!);
          if (moduleId == null) return;
          final normalized = _normalizeButtonsInModule(
            moduleId,
            next,
            provider,
          );
          if (!_buttonsOverlapInModule(moduleId, normalized, provider)) {
            _calibration = normalized;
          }
      }
    });
  }

  Iterable<PhysicalModuleSpec> get _editableModules =>
      widget.spec.modules.where((m) => m.buttonIds.length > 1);

  // ── Geometry constraints ─────────────────────────────────────────────────

  Rect _buttonRect(
    PhysicalHotZoneSpec zone,
    OverlayCalibration calibration,
    PhysicalMetricsProvider provider, {
    bool includeButtonOffset = true,
  }) {
    final base = zone.rect.toLogicalRect(provider);
    final sx = calibration.buttonScaleX[zone.id] ?? 1.0;
    final sy = calibration.buttonScaleY[zone.id] ?? 1.0;
    var rect = Rect.fromCenter(
      center: base.center,
      width: base.width * sx,
      height: base.height * sy,
    );
    if (includeButtonOffset) {
      final offset = calibration.buttonOffsets[zone.id] ?? Offset.zero;
      rect = rect.translate(offset.dx, offset.dy);
    }
    return rect;
  }

  Rect _moduleBaseBounds(
    String moduleId,
    OverlayCalibration calibration,
    PhysicalMetricsProvider provider,
  ) {
    final zones = widget.spec.hotZonesInModule(moduleId);
    Rect? bounds;
    for (final zone in zones) {
      final rect = _buttonRect(
        zone,
        calibration,
        provider,
        includeButtonOffset: false,
      );
      bounds = bounds == null ? rect : bounds.expandToInclude(rect);
    }
    return _expandSingleButtonModuleBounds(bounds!, zones.length, provider);
  }

  Rect _expandSingleButtonModuleBounds(
    Rect bounds,
    int zoneCount,
    PhysicalMetricsProvider provider,
  ) {
    if (zoneCount != 1) return bounds;
    return bounds.inflate(provider.mmToLogicalPixels(2));
  }

  Size _moduleMinimumSize(
    String moduleId,
    OverlayCalibration calibration,
    PhysicalMetricsProvider provider,
  ) {
    var width = 0.0;
    var height = 0.0;
    for (final zone in widget.spec.hotZonesInModule(moduleId)) {
      final rect = _buttonRect(
        zone,
        calibration,
        provider,
        includeButtonOffset: false,
      );
      width = math.max(width, rect.width);
      height = math.max(height, rect.height);
    }
    return Size(width, height);
  }

  Rect _moduleFrame(
    String moduleId,
    OverlayCalibration calibration,
    PhysicalMetricsProvider provider,
  ) {
    final bounds = _moduleBaseBounds(moduleId, calibration, provider);
    final minSize = _moduleMinimumSize(moduleId, calibration, provider);
    final offset = calibration.moduleOffsets[moduleId] ?? Offset.zero;
    return Rect.fromCenter(
      center: bounds.center + offset,
      width: math.max(
        bounds.width * (calibration.moduleScaleX[moduleId] ?? 1.0),
        minSize.width,
      ),
      height: math.max(
        bounds.height * (calibration.moduleScaleY[moduleId] ?? 1.0),
        minSize.height,
      ),
    );
  }

  static Rect _clampRect(Rect rect, Rect bounds) {
    final maxLeft = math.max(bounds.left, bounds.right - rect.width);
    final maxTop = math.max(bounds.top, bounds.bottom - rect.height);
    return Rect.fromLTWH(
      rect.left.clamp(bounds.left, maxLeft),
      rect.top.clamp(bounds.top, maxTop),
      rect.width,
      rect.height,
    );
  }

  Size _minimumPatchSize(
    OverlayCalibration calibration,
    PhysicalMetricsProvider provider,
  ) {
    Rect? allModules;
    for (final module in _editableModules) {
      final frame = _moduleFrame(module.id, calibration, provider);
      allModules = allModules == null
          ? frame
          : allModules.expandToInclude(frame);
    }

    var horizontalModuleWidth = allModules?.width ?? 0.0;
    final ids = _editableModules.map((m) => m.id).toSet();
    if (ids.contains('dpad') && ids.contains('face')) {
      horizontalModuleWidth =
          _moduleFrame('dpad', calibration, provider).width +
          _moduleFrame('face', calibration, provider).width;
    }

    var maxModuleHeight = 0.0;
    for (final module in _editableModules) {
      maxModuleHeight = math.max(
        maxModuleHeight,
        _moduleFrame(module.id, calibration, provider).height,
      );
    }
    return Size(horizontalModuleWidth, maxModuleHeight);
  }

  bool _isModuleLayoutValid(
    String moduleId,
    OverlayCalibration calibration,
    PhysicalMetricsProvider provider,
  ) {
    final patchSize = widget.spec.size.toLogicalSize(provider);
    final patchBounds = Rect.fromLTWH(
      0,
      0,
      patchSize.width * calibration.patchScaleX,
      patchSize.height * calibration.patchScaleY,
    );
    final target = _moduleFrame(moduleId, calibration, provider);
    if (!patchBounds.contains(target.topLeft) ||
        !patchBounds.contains(target.bottomRight)) {
      return false;
    }
    if (_buttonsOverlapInModule(moduleId, calibration, provider)) {
      return false;
    }
    for (final module in _editableModules) {
      if (module.id == moduleId) continue;
      if (target.overlaps(_moduleFrame(module.id, calibration, provider))) {
        return false;
      }
    }
    return true;
  }

  bool _buttonsOverlapInModule(
    String moduleId,
    OverlayCalibration calibration,
    PhysicalMetricsProvider provider,
  ) {
    final zones = widget.spec.hotZonesInModule(moduleId);
    for (var i = 0; i < zones.length; i++) {
      final a = _buttonRectInModule(zones[i], calibration, provider);
      for (var j = i + 1; j < zones.length; j++) {
        final b = _buttonRectInModule(zones[j], calibration, provider);
        if (a.overlaps(b)) return true;
      }
    }
    return false;
  }

  Rect _buttonRectInModule(
    PhysicalHotZoneSpec zone,
    OverlayCalibration calibration,
    PhysicalMetricsProvider provider,
  ) {
    final moduleId = widget.spec.moduleIdForButton(zone.id)!;
    final moduleOffset = calibration.moduleOffsets[moduleId] ?? Offset.zero;
    final moduleBounds = _moduleFrame(moduleId, calibration, provider);
    final offset = calibration.buttonOffsets[zone.id] ?? Offset.zero;
    final raw = _buttonRect(
      zone,
      calibration,
      provider,
      includeButtonOffset: false,
    ).translate(moduleOffset.dx + offset.dx, moduleOffset.dy + offset.dy);
    return _clampRect(raw, moduleBounds);
  }

  OverlayCalibration _normalizeCalibration(
    OverlayCalibration calibration,
    PhysicalMetricsProvider provider,
  ) {
    final patchSize = widget.spec.size.toLogicalSize(provider);
    final patchBounds = Rect.fromLTWH(
      0,
      0,
      patchSize.width * calibration.patchScaleX,
      patchSize.height * calibration.patchScaleY,
    );
    var next = calibration;
    final moduleOffsets = Map<String, Offset>.from(next.moduleOffsets);

    for (final module in _editableModules) {
      final frame = _moduleFrame(module.id, next, provider);
      final clamped = _clampRect(frame, patchBounds);
      if (clamped.topLeft != frame.topLeft) {
        final currentOffset = moduleOffsets[module.id] ?? Offset.zero;
        moduleOffsets[module.id] =
            currentOffset + (clamped.topLeft - frame.topLeft);
      }
    }

    next = next.copyWith(moduleOffsets: moduleOffsets);
    for (final module in widget.spec.modules) {
      next = _normalizeButtonsInModule(module.id, next, provider);
    }
    return next;
  }

  OverlayCalibration _normalizeButtonsInModule(
    String moduleId,
    OverlayCalibration calibration,
    PhysicalMetricsProvider provider,
  ) {
    final moduleBounds = _moduleFrame(moduleId, calibration, provider);
    final moduleOffset = calibration.moduleOffsets[moduleId] ?? Offset.zero;
    final buttonOffsets = Map<String, Offset>.from(calibration.buttonOffsets);

    for (final zone in widget.spec.hotZonesInModule(moduleId)) {
      final current = buttonOffsets[zone.id] ?? Offset.zero;
      final baseRect = _buttonRect(
        zone,
        calibration,
        provider,
        includeButtonOffset: false,
      ).translate(moduleOffset.dx, moduleOffset.dy);
      final rawRect = baseRect.translate(current.dx, current.dy);
      final clamped = _clampRect(rawRect, moduleBounds);
      if (clamped.topLeft != rawRect.topLeft) {
        buttonOffsets[zone.id] = current + (clamped.topLeft - rawRect.topLeft);
      }
    }
    return calibration.copyWith(buttonOffsets: buttonOffsets);
  }

  bool get _scaleActive =>
      _mode == OverlayEditMode.overall ||
      (_mode == OverlayEditMode.module && _selectedModuleId != null) ||
      (_mode == OverlayEditMode.button && _selectedButtonId != null);

  void _changeMode(OverlayEditMode mode) {
    setState(() {
      _mode = mode;
      switch (mode) {
        case OverlayEditMode.overall:
          _selectedModuleId = null;
          _selectedButtonId = null;
        case OverlayEditMode.module:
          _selectedModuleId = 'dpad';
          _selectedButtonId = null;
        case OverlayEditMode.button:
          _selectedModuleId = null;
          _selectedButtonId = 'up';
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PhysicalOverlayScope(child: Builder(builder: _buildContent));
  }

  Widget _buildContent(BuildContext context) {
    final theme = context.host4Theme;
    final provider = resolvePhysicalMetricsProvider(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
        const minimumPatchTop = 220.0;
        final baseSize = widget.spec.size.toLogicalSize(provider);
        final minPatchSize = _minimumPatchSize(_calibration, provider);
        final minOverallScaleX = math.max(
          _ScalePanel.minScale,
          minPatchSize.width / baseSize.width,
        );
        final minOverallScaleY = math.max(
          _ScalePanel.minScale,
          minPatchSize.height / baseSize.height,
        );
        final maxOverallScaleX = math.max(
          minOverallScaleX,
          math.min(_ScalePanel.maxScale, canvasSize.width / baseSize.width),
        );
        final maxOverallScaleY = math.max(
          minOverallScaleY,
          math.min(
            _ScalePanel.maxScale,
            (canvasSize.height - minimumPatchTop) / baseSize.height,
          ),
        );
        final maxScaleX = _mode == OverlayEditMode.overall
            ? maxOverallScaleX
            : _ScalePanel.maxScale;
        final maxScaleY = _mode == OverlayEditMode.overall
            ? maxOverallScaleY
            : _ScalePanel.maxScale;
        final minScaleX = _minScaleX(provider, minOverallScaleX);
        final minScaleY = _minScaleY(provider, minOverallScaleY);

        return Stack(
          children: [
            Positioned.fill(
              child: PhysicalOverlayEditor(
                spec: widget.spec,
                metricsProvider: provider,
                mode: _mode,
                calibration: _calibration,
                canvasSize: canvasSize,
                bottomPadding: bottomInset + 40,
                minimumTop: minimumPatchTop,
                selectedModuleId: _selectedModuleId,
                selectedButtonId: _selectedButtonId,
                onModuleSelected: (id) => setState(() {
                  _selectedModuleId = id;
                  _selectedButtonId = null;
                }),
                onButtonSelected: (id) => setState(() {
                  _selectedButtonId = id;
                  _selectedModuleId = null;
                }),
                onCalibrationChanged: (c) => setState(() => _calibration = c),
                borderColor: theme.colors.brandPrimary,
                hotZoneBorderColor: theme.colors.brandPrimary,
                backgroundColor: theme.colors.brandPrimary.withValues(
                  alpha: 0.08,
                ),
                hotZoneColor: theme.colors.brandPrimary.withValues(alpha: 0.14),
                selectedColor: Colors.red.withValues(alpha: 0.22),
                selectedBorderColor: Colors.red,
              ),
            ),
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ModeSegmentedControl(
                        mode: _mode,
                        onChanged: _changeMode,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            // TODO: 使用 shared_preferences 做设备本地校准数据保存和读取。
                            onPressed: () => Navigator.of(context).maybePop(),
                            child: const Text('保存'),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => setState(() {
                              _calibration = OverlayCalibration.identity;
                              if (_mode == OverlayEditMode.module) {
                                _selectedModuleId = 'dpad';
                              }
                              if (_mode == OverlayEditMode.button) {
                                _selectedButtonId = 'up';
                              }
                            }),
                            child: const Text('重置'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _ScalePanel(
                        label: _scalePanelLabel(),
                        active: _scaleActive,
                        scaleX: _scaleX,
                        scaleY: _scaleY,
                        minScaleX: minScaleX,
                        minScaleY: minScaleY,
                        maxScaleX: maxScaleX,
                        maxScaleY: maxScaleY,
                        onScaleXChanged: (v) => _setScaleX(v, provider),
                        onScaleYChanged: (v) => _setScaleY(v, provider),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _scalePanelLabel() {
    switch (_mode) {
      case OverlayEditMode.overall:
        return '整体缩放';
      case OverlayEditMode.module:
        return _selectedModuleId != null
            ? '模块缩放：$_selectedModuleId'
            : '模块缩放（选中模块后可调）';
      case OverlayEditMode.button:
        return _selectedButtonId != null
            ? '按钮缩放：$_selectedButtonId'
            : '按钮缩放（选中按钮后可调）';
    }
  }

  double _minScaleX(PhysicalMetricsProvider provider, double minOverallScaleX) {
    if (_mode == OverlayEditMode.overall) return minOverallScaleX;
    if (_mode != OverlayEditMode.module || _selectedModuleId == null) {
      return _ScalePanel.minScale;
    }
    final baseBounds = _moduleBaseBounds(
      _selectedModuleId!,
      _calibration,
      provider,
    );
    final minSize = _moduleMinimumSize(
      _selectedModuleId!,
      _calibration,
      provider,
    );
    return math.max(_ScalePanel.minScale, minSize.width / baseBounds.width);
  }

  double _minScaleY(PhysicalMetricsProvider provider, double minOverallScaleY) {
    if (_mode == OverlayEditMode.overall) return minOverallScaleY;
    if (_mode != OverlayEditMode.module || _selectedModuleId == null) {
      return _ScalePanel.minScale;
    }
    final baseBounds = _moduleBaseBounds(
      _selectedModuleId!,
      _calibration,
      provider,
    );
    final minSize = _moduleMinimumSize(
      _selectedModuleId!,
      _calibration,
      provider,
    );
    return math.max(_ScalePanel.minScale, minSize.height / baseBounds.height);
  }
}

// ── Mode segmented control ──────────────────────────────────────────────────

class _ModeSegmentedControl extends StatelessWidget {
  const _ModeSegmentedControl({required this.mode, required this.onChanged});

  final OverlayEditMode mode;
  final void Function(OverlayEditMode) onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<OverlayEditMode>(
      segments: const [
        ButtonSegment(value: OverlayEditMode.overall, label: Text('整体')),
        ButtonSegment(value: OverlayEditMode.module, label: Text('模块')),
        ButtonSegment(value: OverlayEditMode.button, label: Text('按钮')),
      ],
      selected: {mode},
      onSelectionChanged: (s) => onChanged(s.first),
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
    );
  }
}

// ── Scale slider panel ──────────────────────────────────────────────────────

class _ScalePanel extends StatelessWidget {
  const _ScalePanel({
    required this.label,
    required this.active,
    required this.scaleX,
    required this.scaleY,
    required this.minScaleX,
    required this.minScaleY,
    required this.maxScaleX,
    required this.maxScaleY,
    required this.onScaleXChanged,
    required this.onScaleYChanged,
  });

  final String label;
  final bool active;
  final double scaleX;
  final double scaleY;
  final double minScaleX;
  final double minScaleY;
  final double maxScaleX;
  final double maxScaleY;
  final void Function(double) onScaleXChanged;
  final void Function(double) onScaleYChanged;

  static const minScale = 0.5;
  static const maxScale = 2.0;
  static const _step = 0.01;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          _ScaleRow(
            label: '宽',
            value: scaleX,
            enabled: active,
            onChanged: onScaleXChanged,
            min: minScaleX,
            max: maxScaleX,
            step: _step,
          ),
          _ScaleRow(
            label: '高',
            value: scaleY,
            enabled: active,
            onChanged: onScaleYChanged,
            min: minScaleY,
            max: maxScaleY,
            step: _step,
          ),
        ],
      ),
    );
  }
}

class _ScaleRow extends StatelessWidget {
  const _ScaleRow({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.min,
    required this.max,
    required this.step,
  });

  final String label;
  final double value;
  final bool enabled;
  final void Function(double) onChanged;
  final double min;
  final double max;
  final double step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ),
        _ScaleStepButton(
          icon: Icons.remove_rounded,
          enabled: enabled,
          onStep: () => onChanged((value - step).clamp(min, max)),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: enabled ? onChanged : null,
          ),
        ),
        _ScaleStepButton(
          icon: Icons.add_rounded,
          enabled: enabled,
          onStep: () => onChanged((value + step).clamp(min, max)),
        ),
      ],
    );
  }
}

class _ScaleStepButton extends StatefulWidget {
  const _ScaleStepButton({
    required this.icon,
    required this.enabled,
    required this.onStep,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onStep;

  @override
  State<_ScaleStepButton> createState() => _ScaleStepButtonState();
}

class _ScaleStepButtonState extends State<_ScaleStepButton> {
  Timer? _timer;

  void _step() {
    if (widget.enabled) widget.onStep();
  }

  void _startRepeat() {
    if (!widget.enabled) return;
    _step();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 80), (_) => _step());
  }

  void _stopRepeat() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didUpdateWidget(covariant _ScaleStepButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) _stopRepeat();
  }

  @override
  void dispose() {
    _stopRepeat();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.enabled
        ? IconTheme.of(context).color
        : Theme.of(context).disabledColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.enabled ? _step : null,
      onLongPressStart: widget.enabled ? (_) => _startRepeat() : null,
      onLongPressEnd: widget.enabled ? (_) => _stopRepeat() : null,
      onLongPressCancel: widget.enabled ? _stopRepeat : null,
      child: SizedBox.square(
        dimension: 36,
        child: Icon(widget.icon, size: 18, color: color),
      ),
    );
  }
}
