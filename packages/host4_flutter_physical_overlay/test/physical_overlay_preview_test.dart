import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_physical_overlay/host4_flutter_physical_overlay.dart';

void main() {
  test('converts millimeter overlay size through metrics provider', () {
    const provider = FixedPhysicalMetricsProvider(
      logicalPixelsPerMillimeter: 2,
      source: 'test',
    );
    final spec = _tenKeySpec();

    expect(spec.size.toLogicalSize(provider), const Size(128, 60));
    expect(spec.borderRadiusLogical(provider), 8);
  });

  testWidgets('renders overlay and ten physical hot zones', (tester) async {
    const provider = FixedPhysicalMetricsProvider(
      logicalPixelsPerMillimeter: 2,
      source: 'test',
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: PhysicalOverlayPreview(
            spec: _tenKeySpec(),
            metricsProvider: provider,
          ),
        ),
      ),
    );

    expect(find.byKey(PhysicalOverlayPreview.rootKey), findsOneWidget);
    expect(
      tester.getSize(find.byKey(PhysicalOverlayPreview.rootKey)),
      const Size(128, 60),
    );

    for (final id in [
      'up',
      'down',
      'left',
      'right',
      'start',
      'select',
      'a',
      'b',
      'x',
      'y',
    ]) {
      expect(find.byKey(PhysicalOverlayPreview.hotZoneKey(id)), findsOneWidget);
    }
    expect(find.text('UP'), findsNothing);
  });
}

PhysicalOverlaySpec _tenKeySpec() {
  return const PhysicalOverlaySpec(
    size: PhysicalSizeMm(width: 64, height: 30),
    borderRadiusMm: 4,
    hotZones: [
      PhysicalHotZoneSpec(
        id: 'up',
        label: 'UP',
        rect: PhysicalRectMm(left: 10, top: 3, width: 8, height: 8),
      ),
      PhysicalHotZoneSpec(
        id: 'down',
        label: 'DOWN',
        rect: PhysicalRectMm(left: 10, top: 19, width: 8, height: 8),
      ),
      PhysicalHotZoneSpec(
        id: 'left',
        label: 'LEFT',
        rect: PhysicalRectMm(left: 2, top: 11, width: 8, height: 8),
      ),
      PhysicalHotZoneSpec(
        id: 'right',
        label: 'RIGHT',
        rect: PhysicalRectMm(left: 18, top: 11, width: 8, height: 8),
      ),
      PhysicalHotZoneSpec(
        id: 'start',
        label: 'START',
        rect: PhysicalRectMm(left: 29, top: 6, width: 7, height: 7),
      ),
      PhysicalHotZoneSpec(
        id: 'select',
        label: 'SELECT',
        rect: PhysicalRectMm(left: 29, top: 17, width: 7, height: 7),
      ),
      PhysicalHotZoneSpec(
        id: 'x',
        label: 'X',
        rect: PhysicalRectMm(left: 48, top: 3, width: 8, height: 8),
      ),
      PhysicalHotZoneSpec(
        id: 'y',
        label: 'Y',
        rect: PhysicalRectMm(left: 40, top: 11, width: 8, height: 8),
      ),
      PhysicalHotZoneSpec(
        id: 'a',
        label: 'A',
        rect: PhysicalRectMm(left: 56, top: 11, width: 8, height: 8),
      ),
      PhysicalHotZoneSpec(
        id: 'b',
        label: 'B',
        rect: PhysicalRectMm(left: 48, top: 19, width: 8, height: 8),
      ),
    ],
  );
}
