import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'ships every control asset required by the shared emulator UI',
    () async {
      const assets = <String>[
        'dpad_up.svg',
        'dpad_down.svg',
        'dpad_left.svg',
        'dpad_right.svg',
        'btn_a.svg',
        'btn_b.svg',
        'landscape_shoulder_l1.svg',
        'landscape_shoulder_r1.svg',
        'landscape_button_start.svg',
        'landscape_button_select.svg',
        'logo_group.svg',
      ];

      for (final asset in assets) {
        final data = await rootBundle.load(
          'packages/host4_flutter_emulator_ui/assets/controls/$asset',
        );
        expect(data.lengthInBytes, greaterThan(0), reason: asset);
      }
    },
  );
}
