import 'package:flutter/material.dart';
import 'package:host4_flutter_physical_overlay/host4_flutter_physical_overlay.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';

import '../widgets/sub_page_scaffold.dart';
import 'silicone_overlay_edit_page.dart';

class SiliconeOverlayPage extends StatelessWidget {
  const SiliconeOverlayPage({super.key});

  // All coordinates from the rescanned A4 PDF and physical calibration in
  // Figma (node 2122-5).
  // Outer: 63.9 x 30.5 mm, capsule/stadium shape (corner radius ≈ half height).
  // Button coords: center x/y converted to left/top = center - size/2.
  // Width and horizontal distances are physically verified; height is the
  // scanned 31.5mm corrected to 30.5mm after physical calibration.
  static const _spec = PhysicalOverlaySpec(
    size: PhysicalSizeMm(width: 63.9, height: 30.5),
    borderRadiusMm: 15.25,
    modules: [
      PhysicalModuleSpec(
        id: 'dpad',
        buttonIds: ['up', 'down', 'left', 'right'],
      ),
      PhysicalModuleSpec(id: 'start', buttonIds: ['start']),
      PhysicalModuleSpec(id: 'select', buttonIds: ['select']),
      PhysicalModuleSpec(id: 'face', buttonIds: ['a', 'b', 'x', 'y']),
    ],
    hotZones: [
      // D-pad — rounded rect, fixed 2.1 mm radius (Figma: 21px at 1mm=10px)
      PhysicalHotZoneSpec(
        id: 'up',
        label: '↑',
        rect: PhysicalRectMm(left: 12.38, top: 4.52, width: 6.22, height: 7.49),
        shape: HotZoneShape.dpad,
        borderRadiusMm: 2.1,
      ),
      PhysicalHotZoneSpec(
        id: 'down',
        label: '↓',
        rect: PhysicalRectMm(
          left: 12.13,
          top: 17.60,
          width: 6.10,
          height: 7.49,
        ),
        shape: HotZoneShape.dpad,
        borderRadiusMm: 2.1,
      ),
      PhysicalHotZoneSpec(
        id: 'left',
        label: '←',
        rect: PhysicalRectMm(left: 4.89, top: 11.50, width: 7.62, height: 6.22),
        shape: HotZoneShape.dpad,
        borderRadiusMm: 2.1,
      ),
      PhysicalHotZoneSpec(
        id: 'right',
        label: '→',
        rect: PhysicalRectMm(
          left: 18.10,
          top: 11.88,
          width: 7.62,
          height: 6.10,
        ),
        shape: HotZoneShape.dpad,
        borderRadiusMm: 2.1,
      ),
      // Start / Select — rounded-rect, 1.7mm radius (Figma: 17px at 1mm=10px)
      PhysicalHotZoneSpec(
        id: 'start',
        label: 'START',
        rect: PhysicalRectMm(left: 27.62, top: 4.01, width: 9.02, height: 3.94),
        shape: HotZoneShape.dpad,
        borderRadiusMm: 1.7,
      ),
      PhysicalHotZoneSpec(
        id: 'select',
        label: 'SELECT',
        rect: PhysicalRectMm(
          left: 27.24,
          top: 22.42,
          width: 9.02,
          height: 3.94,
        ),
        shape: HotZoneShape.dpad,
        borderRadiusMm: 1.7,
      ),
      // Face buttons — circle
      PhysicalHotZoneSpec(
        id: 'y',
        label: 'Y',
        rect: PhysicalRectMm(
          left: 37.28,
          top: 11.63,
          width: 7.49,
          height: 7.62,
        ),
      ),
      PhysicalHotZoneSpec(
        id: 'x',
        label: 'X',
        rect: PhysicalRectMm(left: 44.90, top: 4.26, width: 7.49, height: 7.62),
      ),
      PhysicalHotZoneSpec(
        id: 'a',
        label: 'A',
        rect: PhysicalRectMm(
          left: 52.26,
          top: 12.01,
          width: 7.62,
          height: 7.62,
        ),
      ),
      PhysicalHotZoneSpec(
        id: 'b',
        label: 'B',
        rect: PhysicalRectMm(
          left: 44.64,
          top: 19.38,
          width: 7.49,
          height: 7.62,
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return SubPageScaffold(
      title: '硅胶贴片',
      subtitle: '物理尺寸热区预研',
      trailing: TextButton(
        child: const Text('编辑'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SubPageScaffold(
              title: '调整热区',
              subtitle: '拖动热区调整位置',
              child: SiliconeOverlayEditPage(spec: _spec),
            ),
          ),
        ),
      ),
      child: PhysicalOverlayScope(child: Builder(builder: _buildContent)),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = context.host4Theme;
    final provider = resolvePhysicalMetricsProvider(context);
    final logicalSize = _spec.size.toLogicalSize(provider);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Stack(
      children: [
        SizedBox.expand(
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
                      showLabels: true,
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
        ),
      ],
    );
  }
}
