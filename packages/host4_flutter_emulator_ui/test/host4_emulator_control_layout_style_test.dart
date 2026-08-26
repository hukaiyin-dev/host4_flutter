import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_emulator_ui/host4_flutter_emulator_ui.dart';

void main() {
  test('keeps the ROM-level layout choice separate from silicone variants', () {
    expect(
      Host4EmulatorControlLayoutStyle.values.map((style) => style.name),
      <String>['modern', 'silicone'],
    );
  });

  test('exposes four silicone variants in the Pantas picker order', () {
    expect(
      host4EmulatorSiliconeLayoutPickerOrder.map((variant) => variant.wireName),
      <String>[
        'retro_traditional',
        'silicone',
        'modern_symmetric',
        'modern_asymmetric',
      ],
    );
  });
}
