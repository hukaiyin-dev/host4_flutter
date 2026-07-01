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

class PhysicalModuleSpec {
  const PhysicalModuleSpec({required this.id, required this.buttonIds});

  final String id;
  final List<String> buttonIds;
}

class PhysicalOverlaySpec {
  const PhysicalOverlaySpec({
    required this.size,
    required this.borderRadiusMm,
    required this.hotZones,
    required this.modules,
  });

  final PhysicalSizeMm size;
  final double borderRadiusMm;
  final List<PhysicalHotZoneSpec> hotZones;
  final List<PhysicalModuleSpec> modules;

  double borderRadiusLogical(PhysicalMetricsProvider provider) {
    return provider.mmToLogicalPixels(borderRadiusMm);
  }

  /// Returns the module ID for the given button id, or null if not found.
  String? moduleIdForButton(String buttonId) {
    for (final m in modules) {
      if (m.buttonIds.contains(buttonId)) return m.id;
    }
    return null;
  }

  /// Returns all hot zones belonging to the given module.
  List<PhysicalHotZoneSpec> hotZonesInModule(String moduleId) {
    final module = modules.firstWhere((m) => m.id == moduleId);
    return hotZones.where((z) => module.buttonIds.contains(z.id)).toList();
  }
}
