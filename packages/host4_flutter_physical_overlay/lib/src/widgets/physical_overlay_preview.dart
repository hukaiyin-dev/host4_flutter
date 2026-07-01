import 'package:flutter/widgets.dart';

import '../metrics/physical_metrics_provider.dart';
import '../model/physical_overlay_spec.dart';

class PhysicalOverlayPreview extends StatelessWidget {
  const PhysicalOverlayPreview({
    required this.spec,
    required this.metricsProvider,
    this.showLabels = false,
    this.backgroundColor = const Color(0x1A4C8DFF),
    this.borderColor = const Color(0xFF4C8DFF),
    this.hotZoneColor = const Color(0x334C8DFF),
    this.hotZoneBorderColor = const Color(0xCC4C8DFF),
    super.key,
  });

  static const rootKey = ValueKey('physical-overlay-root');

  static Key hotZoneKey(String id) {
    return ValueKey('physical-overlay-hot-zone-$id');
  }

  final PhysicalOverlaySpec spec;
  final PhysicalMetricsProvider metricsProvider;
  final bool showLabels;
  final Color backgroundColor;
  final Color borderColor;
  final Color hotZoneColor;
  final Color hotZoneBorderColor;

  @override
  Widget build(BuildContext context) {
    final size = spec.size.toLogicalSize(metricsProvider);
    final radius = spec.borderRadiusLogical(metricsProvider);

    return SizedBox.fromSize(
      key: rootKey,
      size: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: borderColor, width: 1.5),
            ),
          ),
          for (final zone in spec.hotZones)
            _HotZoneView(
              key: hotZoneKey(zone.id),
              zone: zone,
              metricsProvider: metricsProvider,
              showLabel: showLabels,
              color: hotZoneColor,
              borderColor: hotZoneBorderColor,
            ),
        ],
      ),
    );
  }
}

class _HotZoneView extends StatelessWidget {
  const _HotZoneView({
    required this.zone,
    required this.metricsProvider,
    required this.showLabel,
    required this.color,
    required this.borderColor,
    super.key,
  });

  final PhysicalHotZoneSpec zone;
  final PhysicalMetricsProvider metricsProvider;
  final bool showLabel;
  final Color color;
  final Color borderColor;

  BorderRadius _borderRadius(Rect rect) {
    if (zone.borderRadiusMm != null) {
      return BorderRadius.circular(
        metricsProvider.mmToLogicalPixels(zone.borderRadiusMm!),
      );
    }
    switch (zone.shape) {
      case HotZoneShape.circle:
      case HotZoneShape.pill:
        return BorderRadius.circular(rect.shortestSide / 2);
      case HotZoneShape.dpad:
        return BorderRadius.circular(rect.shortestSide / 2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rect = zone.rect.toLogicalRect(metricsProvider);

    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: _borderRadius(rect),
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: showLabel
              ? Padding(
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
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
