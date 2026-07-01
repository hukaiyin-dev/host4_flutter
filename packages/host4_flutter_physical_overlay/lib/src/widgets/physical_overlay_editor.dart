import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../metrics/physical_metrics_provider.dart';
import '../model/physical_overlay_spec.dart';

enum OverlayEditMode { overall, module, button }

/// Calibration state for the entire overlay.
class OverlayCalibration {
  const OverlayCalibration({
    this.patchOffset = Offset.zero,
    this.patchScaleX = 1.0,
    this.patchScaleY = 1.0,
    this.moduleOffsets = const {},
    this.moduleScaleX = const {},
    this.moduleScaleY = const {},
    this.buttonOffsets = const {},
    this.buttonScaleX = const {},
    this.buttonScaleY = const {},
  });

  final Offset patchOffset;
  final double patchScaleX;
  final double patchScaleY;
  final Map<String, Offset> moduleOffsets;
  final Map<String, double> moduleScaleX;
  final Map<String, double> moduleScaleY;
  final Map<String, Offset> buttonOffsets;
  final Map<String, double> buttonScaleX;
  final Map<String, double> buttonScaleY;

  static const identity = OverlayCalibration();

  OverlayCalibration copyWith({
    Offset? patchOffset,
    double? patchScaleX,
    double? patchScaleY,
    Map<String, Offset>? moduleOffsets,
    Map<String, double>? moduleScaleX,
    Map<String, double>? moduleScaleY,
    Map<String, Offset>? buttonOffsets,
    Map<String, double>? buttonScaleX,
    Map<String, double>? buttonScaleY,
  }) {
    return OverlayCalibration(
      patchOffset: patchOffset ?? this.patchOffset,
      patchScaleX: patchScaleX ?? this.patchScaleX,
      patchScaleY: patchScaleY ?? this.patchScaleY,
      moduleOffsets: moduleOffsets ?? this.moduleOffsets,
      moduleScaleX: moduleScaleX ?? this.moduleScaleX,
      moduleScaleY: moduleScaleY ?? this.moduleScaleY,
      buttonOffsets: buttonOffsets ?? this.buttonOffsets,
      buttonScaleX: buttonScaleX ?? this.buttonScaleX,
      buttonScaleY: buttonScaleY ?? this.buttonScaleY,
    );
  }
}

/// Interactive overlay editor supporting three edit modes.
///
/// - [OverlayEditMode.overall]: drag the whole patch; scale via external sliders.
/// - [OverlayEditMode.module]: drag individual modules; scale via external sliders.
/// - [OverlayEditMode.button]: drag individual buttons; scale via external sliders.
///
/// Calibration state is managed by the caller via [calibration] and
/// [onCalibrationChanged].
class PhysicalOverlayEditor extends StatelessWidget {
  const PhysicalOverlayEditor({
    required this.spec,
    required this.metricsProvider,
    required this.mode,
    required this.calibration,
    required this.onCalibrationChanged,
    required this.canvasSize,
    required this.bottomPadding,
    this.minimumTop = 0,
    this.selectedModuleId,
    this.selectedButtonId,
    this.onModuleSelected,
    this.onButtonSelected,
    this.backgroundColor = const Color(0x1A4C8DFF),
    this.borderColor = const Color(0xFF4C8DFF),
    this.hotZoneColor = const Color(0x334C8DFF),
    this.hotZoneBorderColor = const Color(0xCC4C8DFF),
    this.selectedColor = const Color(0x554C8DFF),
    this.selectedBorderColor = const Color(0xFF4C8DFF),
    super.key,
  });

  final PhysicalOverlaySpec spec;
  final PhysicalMetricsProvider metricsProvider;
  final OverlayEditMode mode;
  final OverlayCalibration calibration;
  final void Function(OverlayCalibration) onCalibrationChanged;

  /// Editable area size. Patch movement is clamped inside this canvas.
  final Size canvasSize;

  /// Distance from the canvas bottom to the patch's initial bottom edge.
  final double bottomPadding;

  /// Minimum patch top in the editable canvas. Used to keep the patch below
  /// controls rendered above the canvas.
  final double minimumTop;

  /// In module mode, the currently selected module id (if any).
  final String? selectedModuleId;

  /// In button mode, the currently selected button id (if any).
  final String? selectedButtonId;

  final void Function(String moduleId)? onModuleSelected;
  final void Function(String buttonId)? onButtonSelected;

  final Color backgroundColor;
  final Color borderColor;
  final Color hotZoneColor;
  final Color hotZoneBorderColor;
  final Color selectedColor;
  final Color selectedBorderColor;

  bool _isEditableModule(String moduleId) {
    return spec.hotZonesInModule(moduleId).length > 1;
  }

  // ── Geometry helpers ──────────────────────────────────────────────────────

  /// Base patch size in logical pixels (before calibration scale).
  Size _baseSize() => spec.size.toLogicalSize(metricsProvider);

  /// Scaled patch size.
  Size _patchSize() {
    final base = _baseSize();
    return Size(
      base.width * calibration.patchScaleX,
      base.height * calibration.patchScaleY,
    );
  }

  /// Computes the bounding rect of a module's buttons in patch-local coords,
  /// after button-level calibration but before module-level calibration.
  Rect _moduleBoundsInPatch(String moduleId) {
    final zones = spec.hotZonesInModule(moduleId);
    assert(zones.isNotEmpty);
    Rect? bounds;
    for (final zone in zones) {
      final r = _buttonRectWithoutOffsets(zone);
      bounds = bounds == null ? r : bounds.expandToInclude(r);
    }
    return _expandSingleButtonModuleBounds(bounds!, zones.length);
  }

  Rect _expandSingleButtonModuleBounds(Rect bounds, int zoneCount) {
    if (zoneCount != 1) return bounds;
    final padding = metricsProvider.mmToLogicalPixels(2);
    return bounds.inflate(padding);
  }

  Rect _moduleFrameInPatch(
    String moduleId, {
    Offset? moduleOffset,
    bool clampToPatch = true,
  }) {
    final baseBounds = _moduleBoundsInPatch(moduleId);
    final minSize = _moduleMinimumSize(moduleId);
    final sx = calibration.moduleScaleX[moduleId] ?? 1.0;
    final sy = calibration.moduleScaleY[moduleId] ?? 1.0;
    final offset =
        moduleOffset ?? calibration.moduleOffsets[moduleId] ?? Offset.zero;
    final patchSize = _patchSize();
    final frame = Rect.fromCenter(
      center: baseBounds.center + offset,
      width: math.max(baseBounds.width * sx, minSize.width),
      height: math.max(baseBounds.height * sy, minSize.height),
    );
    if (!clampToPatch) return frame;
    return _clampRectInBounds(
      frame,
      Rect.fromLTWH(0, 0, patchSize.width, patchSize.height),
    );
  }

  Size _moduleMinimumSize(String moduleId) {
    var width = 0.0;
    var height = 0.0;
    for (final zone in spec.hotZonesInModule(moduleId)) {
      final rect = _buttonRectWithoutOffsets(zone);
      width = math.max(width, rect.width);
      height = math.max(height, rect.height);
    }
    return Size(width, height);
  }

  Rect _buttonRectWithoutOffsets(PhysicalHotZoneSpec zone) {
    final base = zone.rect.toLogicalRect(metricsProvider);
    final bsx = calibration.buttonScaleX[zone.id] ?? 1.0;
    final bsy = calibration.buttonScaleY[zone.id] ?? 1.0;
    return Rect.fromCenter(
      center: base.center,
      width: base.width * bsx,
      height: base.height * bsy,
    );
  }

  /// Computes a button's rect in patch-local coordinates.
  ///
  /// When [applyModuleCalibration] is true, applies module offset and scale.
  Rect _buttonRectInPatch(
    PhysicalHotZoneSpec zone, {
    bool applyModuleCalibration = true,
  }) {
    Rect r = _buttonRectWithoutOffsets(zone);

    // Button offset.
    r = r.translate(
      (calibration.buttonOffsets[zone.id] ?? Offset.zero).dx,
      (calibration.buttonOffsets[zone.id] ?? Offset.zero).dy,
    );

    if (!applyModuleCalibration) return r;

    final moduleId = spec.moduleIdForButton(zone.id)!;
    final mOffset = calibration.moduleOffsets[moduleId] ?? Offset.zero;
    r = r.translate(mOffset.dx, mOffset.dy);
    r = _clampRectInBounds(r, _moduleFrameInPatch(moduleId));

    return r;
  }

  static Rect _clampRectInBounds(Rect rect, Rect bounds) {
    final maxLeft = math.max(bounds.left, bounds.right - rect.width);
    final maxTop = math.max(bounds.top, bounds.bottom - rect.height);
    final left = rect.left.clamp(bounds.left, maxLeft);
    final top = rect.top.clamp(bounds.top, maxTop);
    return Rect.fromLTWH(left, top, rect.width, rect.height);
  }

  // ── Drag handlers ─────────────────────────────────────────────────────────

  Offset _patchBaseOffset(Size patchSize) {
    final left = (canvasSize.width - patchSize.width) / 2;
    final maxTop = math.max(0.0, canvasSize.height - patchSize.height);
    final minTop = math.min(minimumTop, maxTop);
    final top = (canvasSize.height - bottomPadding - patchSize.height).clamp(
      minTop,
      maxTop,
    );
    return Offset(left, top);
  }

  Offset _clampPatchOffset(Offset rawOffset, Size patchSize) {
    final base = _patchBaseOffset(patchSize);
    final maxLeft = math.max(0.0, canvasSize.width - patchSize.width);
    final maxTop = math.max(0.0, canvasSize.height - patchSize.height);
    final minTop = math.min(minimumTop, maxTop);
    final left = (base.dx + rawOffset.dx).clamp(0.0, maxLeft);
    final top = (base.dy + rawOffset.dy).clamp(minTop, maxTop);
    return Offset(left - base.dx, top - base.dy);
  }

  void _onPatchPan(DragUpdateDetails d) {
    final patchSize = _patchSize();
    final offset = _clampPatchOffset(
      calibration.patchOffset + d.delta,
      patchSize,
    );
    onCalibrationChanged(calibration.copyWith(patchOffset: offset));
  }

  void _onModulePan(String moduleId, DragUpdateDetails d) {
    onModuleSelected?.call(moduleId);
    final patchSize = _patchSize();
    final patchBounds = Rect.fromLTWH(0, 0, patchSize.width, patchSize.height);
    final cur = calibration.moduleOffsets[moduleId] ?? Offset.zero;
    final next = _resolveModuleOffset(moduleId, cur + d.delta, patchBounds);
    final newOffsets = Map<String, Offset>.from(calibration.moduleOffsets)
      ..[moduleId] = next;
    onCalibrationChanged(calibration.copyWith(moduleOffsets: newOffsets));
  }

  Offset _resolveModuleOffset(
    String moduleId,
    Offset rawOffset,
    Rect patchBounds,
  ) {
    Offset clampToPatch(Offset offset) {
      final rawFrame = _moduleFrameInPatch(
        moduleId,
        moduleOffset: offset,
        clampToPatch: false,
      );
      final clampedFrame = _clampRectInBounds(rawFrame, patchBounds);
      return Offset(
        offset.dx + clampedFrame.left - rawFrame.left,
        offset.dy + clampedFrame.top - rawFrame.top,
      );
    }

    final current = calibration.moduleOffsets[moduleId] ?? Offset.zero;
    final candidates = [
      clampToPatch(rawOffset),
      clampToPatch(Offset(rawOffset.dx, current.dy)),
      clampToPatch(Offset(current.dx, rawOffset.dy)),
      current,
    ];

    for (final candidate in candidates) {
      final frame = _moduleFrameInPatch(
        moduleId,
        moduleOffset: candidate,
        clampToPatch: false,
      );
      if (!_moduleOverlapsOther(moduleId, frame)) return candidate;
    }
    return current;
  }

  bool _moduleOverlapsOther(String moduleId, Rect frame) {
    for (final module in spec.modules) {
      if (module.id == moduleId) continue;
      if (!_isEditableModule(module.id)) continue;
      if (frame.overlaps(_moduleFrameInPatch(module.id))) return true;
    }
    return false;
  }

  void _onButtonPan(PhysicalHotZoneSpec zone, DragUpdateDetails d) {
    onButtonSelected?.call(zone.id);
    final moduleId = spec.moduleIdForButton(zone.id)!;
    final moduleOffset = calibration.moduleOffsets[moduleId] ?? Offset.zero;
    final moduleBounds = _moduleFrameInPatch(moduleId);
    final baseRect = _buttonRectWithoutOffsets(
      zone,
    ).translate(moduleOffset.dx, moduleOffset.dy);
    final cur = calibration.buttonOffsets[zone.id] ?? Offset.zero;
    final next = _resolveButtonOffset(
      zone,
      baseRect,
      cur + d.delta,
      moduleBounds,
    );
    final newOffsets = Map<String, Offset>.from(calibration.buttonOffsets)
      ..[zone.id] = next;
    onCalibrationChanged(calibration.copyWith(buttonOffsets: newOffsets));
  }

  Offset _resolveButtonOffset(
    PhysicalHotZoneSpec zone,
    Rect baseRect,
    Offset rawOffset,
    Rect moduleBounds,
  ) {
    Offset clampToModule(Offset offset) {
      final rawRect = baseRect.translate(offset.dx, offset.dy);
      final clampedRect = _clampRectInBounds(rawRect, moduleBounds);
      return Offset(
        offset.dx + clampedRect.left - rawRect.left,
        offset.dy + clampedRect.top - rawRect.top,
      );
    }

    final current = calibration.buttonOffsets[zone.id] ?? Offset.zero;
    final candidates = [
      clampToModule(rawOffset),
      clampToModule(Offset(rawOffset.dx, current.dy)),
      clampToModule(Offset(current.dx, rawOffset.dy)),
      current,
    ];

    for (final candidate in candidates) {
      final rect = baseRect.translate(candidate.dx, candidate.dy);
      if (!_buttonOverlapsSibling(zone, rect)) return candidate;
    }
    return current;
  }

  bool _buttonOverlapsSibling(PhysicalHotZoneSpec zone, Rect rect) {
    final moduleId = spec.moduleIdForButton(zone.id)!;
    for (final other in spec.hotZonesInModule(moduleId)) {
      if (other.id == zone.id) continue;
      if (rect.overlaps(_buttonRectInPatch(other))) return true;
    }
    return false;
  }

  OverlayCalibration _clampButtonsInModule(String moduleId) {
    final moduleOffset = calibration.moduleOffsets[moduleId] ?? Offset.zero;
    final moduleBounds = _moduleFrameInPatch(moduleId);
    final buttonOffsets = Map<String, Offset>.from(calibration.buttonOffsets);
    var changed = false;

    for (final zone in spec.hotZonesInModule(moduleId)) {
      final currentOffset = buttonOffsets[zone.id] ?? Offset.zero;
      final baseRect = _buttonRectWithoutOffsets(
        zone,
      ).translate(moduleOffset.dx, moduleOffset.dy);
      final rawRect = baseRect.translate(currentOffset.dx, currentOffset.dy);
      final clampedRect = _clampRectInBounds(rawRect, moduleBounds);
      final newOffset = Offset(
        currentOffset.dx + clampedRect.left - rawRect.left,
        currentOffset.dy + clampedRect.top - rawRect.top,
      );
      if (newOffset != currentOffset) {
        buttonOffsets[zone.id] = newOffset;
        changed = true;
      }
    }

    return changed
        ? calibration.copyWith(buttonOffsets: buttonOffsets)
        : calibration;
  }

  void clampButtonsInModule(String moduleId) {
    final next = _clampButtonsInModule(moduleId);
    if (!identical(next, calibration)) {
      onCalibrationChanged(next);
    }
  }

  OverlayCalibration clampPatchInCanvas() {
    final patchSize = _patchSize();
    final offset = _clampPatchOffset(calibration.patchOffset, patchSize);
    if (offset == calibration.patchOffset) return calibration;
    return calibration.copyWith(patchOffset: offset);
  }

  void clampPatch() {
    final next = clampPatchInCanvas();
    if (!identical(next, calibration)) {
      onCalibrationChanged(next);
    }
  }

  Rect _moduleBoundsWithCalibration(String moduleId) {
    return _moduleFrameInPatch(moduleId);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  BorderRadius _borderRadius(PhysicalHotZoneSpec zone, Rect rect) {
    if (zone.borderRadiusMm != null) {
      return BorderRadius.circular(
        metricsProvider.mmToLogicalPixels(zone.borderRadiusMm!),
      );
    }
    switch (zone.shape) {
      case HotZoneShape.circle:
      case HotZoneShape.pill:
      case HotZoneShape.dpad:
        return BorderRadius.circular(rect.shortestSide / 2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patchSize = _patchSize();
    final patchRadius =
        spec.borderRadiusLogical(metricsProvider) *
        ((calibration.patchScaleX + calibration.patchScaleY) / 2);
    final patchOrigin =
        _patchBaseOffset(patchSize) +
        _clampPatchOffset(calibration.patchOffset, patchSize);

    return SizedBox.fromSize(
      size: canvasSize,
      child: Stack(
        children: [
          Positioned(
            left: patchOrigin.dx,
            top: patchOrigin.dy,
            width: patchSize.width,
            height: patchSize.height,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: mode == OverlayEditMode.overall ? _onPatchPan : null,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(patchRadius),
                      border: Border.all(
                        color: mode == OverlayEditMode.overall
                            ? selectedBorderColor
                            : borderColor,
                        width: mode == OverlayEditMode.overall ? 2.5 : 1.5,
                      ),
                    ),
                  ),
                  for (final zone in spec.hotZones) _buildZone(zone),
                  for (final module in spec.modules)
                    if (_isEditableModule(module.id))
                      _buildModuleOutline(
                        module.id,
                        selected:
                            mode == OverlayEditMode.module &&
                            selectedModuleId == module.id,
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleOutline(String moduleId, {required bool selected}) {
    final bounds = _moduleBoundsWithCalibration(moduleId);
    return Positioned(
      left: bounds.left,
      top: bounds.top,
      width: bounds.width,
      height: bounds.height,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? selectedBorderColor : hotZoneBorderColor,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }

  Widget _buildZone(PhysicalHotZoneSpec zone) {
    final rect = _buttonRectInPatch(zone);
    final moduleId = spec.moduleIdForButton(zone.id)!;
    final isSelectedModule = selectedModuleId == moduleId;
    final isSelectedButton = selectedButtonId == zone.id;

    final selected =
        (mode == OverlayEditMode.module && isSelectedModule) ||
        (mode == OverlayEditMode.button && isSelectedButton);
    final color = selected ? selectedColor : hotZoneColor;
    final borderCol = selected ? selectedBorderColor : hotZoneBorderColor;
    final borderWidth = selected ? 2.0 : 1.0;

    final decoration = DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: _borderRadius(zone, rect),
        border: Border.all(color: borderCol, width: borderWidth),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(1),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              zone.label,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFFFFFFFF),
                fontSize: (rect.shortestSide * 0.32).clamp(5.0, 9.0),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );

    Widget child;
    if (mode == OverlayEditMode.module && _isEditableModule(moduleId)) {
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => onModuleSelected?.call(moduleId),
        onPanStart: (_) => onModuleSelected?.call(moduleId),
        onPanUpdate: (d) => _onModulePan(moduleId, d),
        child: decoration,
      );
    } else if (mode == OverlayEditMode.button) {
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (d) => _onButtonPan(zone, d),
        child: decoration,
      );
    } else {
      child = decoration;
    }

    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: child,
    );
  }
}
