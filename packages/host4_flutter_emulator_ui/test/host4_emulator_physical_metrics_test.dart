import 'package:display_metrics/display_metrics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_emulator_ui/host4_flutter_emulator_ui.dart';

void main() {
  testWidgets('display zoom keeps the portrait GamePatch at 63.9 mm', (
    tester,
  ) async {
    const screenWidthMm = 66.0;
    final display = DisplayMetricsData(
      displays: [
        ExtendedPhysicalDisplayData(
          physicalSize: const Size(screenWidthMm / 25.4, 144 / 25.4),
          resolution: const Size(1170, 2553),
          isPrimary: true,
          devicePixelRatio: 3,
        ),
      ],
    );

    Future<Rect> padAtWidth(double width) async {
      late Rect bounds;
      await tester.pumpWidget(
        DisplayMetrics(
          data: display,
          child: MediaQuery(
            data: MediaQueryData(size: Size(width, 844), devicePixelRatio: 3),
            child: Builder(
              builder: (context) {
                final layout = Host4EmulatorSiliconeLayoutResolver.portrait(
                  screenSize: Size(width, 844),
                  metrics: Host4EmulatorSiliconeMetrics.of(context),
                );
                bounds = layout.padBounds[Host4EmulatorSiliconePadSide.single]!;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      return bounds;
    }

    final normal = await padAtWidth(390);
    final zoomed = await padAtWidth(360);

    expect(normal.width / 390 * screenWidthMm, closeTo(63.9, 0.01));
    expect(zoomed.width / 360 * screenWidthMm, closeTo(63.9, 0.01));
    expect(zoomed.left, greaterThanOrEqualTo(0));
    expect(zoomed.right, lessThanOrEqualTo(360));
  });
}
