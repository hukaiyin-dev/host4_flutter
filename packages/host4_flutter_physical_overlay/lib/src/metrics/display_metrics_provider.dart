import 'package:display_metrics/display_metrics.dart';
import 'package:flutter/widgets.dart';

import 'physical_metrics_provider.dart';

/// Resolves a [PhysicalMetricsProvider] from the nearest [DisplayMetricsWidget]
/// in the widget tree.
///
/// Returns a [FixedPhysicalMetricsProvider] backed by the device's real PPI
/// when [DisplayMetrics] data is available, otherwise falls back to
/// [FallbackPhysicalMetricsProvider].
PhysicalMetricsProvider resolvePhysicalMetricsProvider(BuildContext context) {
  final data = DisplayMetrics.maybeOf(context);
  if (data != null) {
    final lpPerInch = data.inchesToLogicalPixelRatio;
    if (lpPerInch > 0) {
      return FixedPhysicalMetricsProvider(
        logicalPixelsPerMillimeter: lpPerInch / 25.4,
        source: 'display_metrics(ppi=${data.ppi.toStringAsFixed(0)})',
      );
    }
  }
  return const FallbackPhysicalMetricsProvider();
}
