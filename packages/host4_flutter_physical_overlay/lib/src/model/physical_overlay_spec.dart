import 'dart:ui';

import '../metrics/physical_metrics_provider.dart';

class PhysicalSizeMm {
  const PhysicalSizeMm({required this.width, required this.height});

  final double width;
  final double height;

  Size toLogicalSize(PhysicalMetricsProvider provider) {
    return Size(
      provider.mmToLogicalPixels(width),
      provider.mmToLogicalPixels(height),
    );
  }
}

class PhysicalRectMm {
  const PhysicalRectMm({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;

  Rect toLogicalRect(PhysicalMetricsProvider provider) {
    return Rect.fromLTWH(
      provider.mmToLogicalPixels(left),
      provider.mmToLogicalPixels(top),
      provider.mmToLogicalPixels(width),
      provider.mmToLogicalPixels(height),
    );
  }
}

enum HotZoneShape {
  /// Fully circular — default for face buttons (A/B/X/Y).
  circle,

  /// Rounded rectangle — for directional pad buttons (up/down/left/right).
  dpad,

  /// Wide pill / stadium shape — for small auxiliary buttons (Start/Select).
  pill,
}

class PhysicalHotZoneSpec {
  const PhysicalHotZoneSpec({
    required this.id,
    required this.label,
    required this.rect,
    this.shape = HotZoneShape.circle,
    this.borderRadiusMm,
  });

  final String id;
  final String label;
  final PhysicalRectMm rect;
  final HotZoneShape shape;

  /// Optional fixed corner radius in mm. When set, overrides the shape-based
  /// default radius in the renderer.
  final double? borderRadiusMm;
}

class PhysicalOverlaySpec {
  const PhysicalOverlaySpec({
    required this.size,
    required this.borderRadiusMm,
    required this.hotZones,
  });

  final PhysicalSizeMm size;
  final double borderRadiusMm;
  final List<PhysicalHotZoneSpec> hotZones;

  double borderRadiusLogical(PhysicalMetricsProvider provider) {
    return provider.mmToLogicalPixels(borderRadiusMm);
  }
}
