import 'package:flutter/material.dart';
import 'package:host4_flutter_physical_overlay/host4_flutter_physical_overlay.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';

class SiliconeOverlayPage extends StatelessWidget {
  const SiliconeOverlayPage({super.key});

  // All coordinates from A4 PDF scan in Figma (node 2122-5).
  // Outer: 62.31 x 29.91 mm, capsule/stadium shape (corner radius ≈ half height).
  // Button coords: center x/y converted to left/top = center - size/2.
  // Tolerance: ±0.5–1.0 mm (scan estimate).
  static const _spec = PhysicalOverlaySpec(
    size: PhysicalSizeMm(width: 62.31, height: 29.91),
    borderRadiusMm: 14.95,
    hotZones: [
      // D-pad — rounded rect, fixed 2.1 mm radius (Figma: 21px at 1mm=10px)
      PhysicalHotZoneSpec(
        id: 'up',
        label: 'UP',
        rect: PhysicalRectMm(left: 11.84, top: 4.83, width: 5.83, height: 7.20),
        shape: HotZoneShape.dpad,
        borderRadiusMm: 2.1,
      ),
      PhysicalHotZoneSpec(
        id: 'down',
        label: 'DOWN',
        rect: PhysicalRectMm(left: 11.92, top: 17.88, width: 5.66, height: 7.20),
        shape: HotZoneShape.dpad,
        borderRadiusMm: 2.1,
      ),
      PhysicalHotZoneSpec(
        id: 'left',
        label: 'LEFT',
        rect: PhysicalRectMm(left: 4.74, top: 12.04, width: 7.10, height: 5.85),
        shape: HotZoneShape.dpad,
        borderRadiusMm: 2.1,
      ),
      PhysicalHotZoneSpec(
        id: 'right',
        label: 'RIGHT',
        rect: PhysicalRectMm(left: 17.59, top: 12.12, width: 7.19, height: 5.76),
        shape: HotZoneShape.dpad,
        borderRadiusMm: 2.1,
      ),
      // Start / Select — rounded-rect, 1.7mm radius (Figma: 17px at 1mm=10px)
      PhysicalHotZoneSpec(
        id: 'start',
        label: 'START',
        rect: PhysicalRectMm(left: 26.88, top: 4.07, width: 8.54, height: 3.39),
        shape: HotZoneShape.dpad,
        borderRadiusMm: 1.7,
      ),
      PhysicalHotZoneSpec(
        id: 'select',
        label: 'SELECT',
        rect: PhysicalRectMm(left: 26.88, top: 22.38, width: 8.54, height: 3.47),
        shape: HotZoneShape.dpad,
        borderRadiusMm: 1.7,
      ),
      // Face buttons — circle
      PhysicalHotZoneSpec(
        id: 'y',
        label: 'Y',
        rect: PhysicalRectMm(left: 36.44, top: 11.36, width: 7.19, height: 7.20),
      ),
      PhysicalHotZoneSpec(
        id: 'x',
        label: 'X',
        rect: PhysicalRectMm(left: 43.88, top: 3.81, width: 7.19, height: 7.20),
      ),
      PhysicalHotZoneSpec(
        id: 'a',
        label: 'A',
        rect: PhysicalRectMm(left: 51.32, top: 11.36, width: 7.10, height: 7.20),
      ),
      PhysicalHotZoneSpec(
        id: 'b',
        label: 'B',
        rect: PhysicalRectMm(left: 43.96, top: 18.90, width: 7.02, height: 7.12),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return PhysicalOverlayScope(child: Builder(builder: _buildContent));
  }

  Widget _buildContent(BuildContext context) {
    final theme = context.host4Theme;
    final provider = resolvePhysicalMetricsProvider(context);
    final logicalSize = _spec.size.toLogicalSize(provider);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SizedBox.expand(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset + 40),
          child: SizedBox(
            width: double.infinity,
            height: logicalSize.height,
            child: ClipRect(
              child: OverflowBox(
                minWidth: logicalSize.width,
                maxWidth: logicalSize.width,
                minHeight: logicalSize.height,
                maxHeight: logicalSize.height,
                alignment: Alignment.center,
                child: PhysicalOverlayPreview(
                  spec: _spec,
                  metricsProvider: provider,
                  showLabels: false,
                  borderColor: theme.colors.brandPrimary,
                  hotZoneBorderColor: theme.colors.brandPrimary,
                  backgroundColor: theme.colors.brandPrimary.withValues(
                    alpha: 0.08,
                  ),
                  hotZoneColor: theme.colors.brandPrimary.withValues(
                    alpha: 0.14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
