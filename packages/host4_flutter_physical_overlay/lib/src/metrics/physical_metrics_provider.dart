/// Converts physical millimeters to Flutter logical pixels.
abstract interface class PhysicalMetricsProvider {
  double mmToLogicalPixels(double mm);

  String get source;
}

/// Deterministic provider for tests and fixed-device experiments.
class FixedPhysicalMetricsProvider implements PhysicalMetricsProvider {
  const FixedPhysicalMetricsProvider({
    required this.logicalPixelsPerMillimeter,
    required this.source,
  });

  final double logicalPixelsPerMillimeter;

  @override
  final String source;

  @override
  double mmToLogicalPixels(double mm) => mm * logicalPixelsPerMillimeter;
}

/// Fallback estimate based on the common 160 logical pixels per inch baseline.
class FallbackPhysicalMetricsProvider implements PhysicalMetricsProvider {
  const FallbackPhysicalMetricsProvider({this.logicalPixelsPerInch = 160});

  final double logicalPixelsPerInch;

  @override
  String get source => 'fallback-160ppi-logical';

  @override
  double mmToLogicalPixels(double mm) {
    return mm * logicalPixelsPerInch / 25.4;
  }
}
