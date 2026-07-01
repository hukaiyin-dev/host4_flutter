import 'package:display_metrics/display_metrics.dart';
import 'package:flutter/widgets.dart';

/// Injects display metrics into the widget tree so that
/// [resolvePhysicalMetricsProvider] can return real device PPI.
///
/// Wrap the page (or a subtree) that contains [PhysicalOverlayPreview]
/// with this widget. The child does not need to know about [display_metrics]
/// directly.
class PhysicalOverlayScope extends StatelessWidget {
  const PhysicalOverlayScope({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DisplayMetricsWidget(child: child);
  }
}
