import 'package:flutter/widgets.dart';

import '../../l10n/generated/emulator_ui_localizations.dart';

enum Host4EmulatorSiliconeLayoutVariant {
  silicone,
  modernSymmetric,
  modernAsymmetric,
  retroTraditional,
}

const List<Host4EmulatorSiliconeLayoutVariant>
host4EmulatorSiliconeLayoutPickerOrder = <Host4EmulatorSiliconeLayoutVariant>[
  Host4EmulatorSiliconeLayoutVariant.retroTraditional,
  Host4EmulatorSiliconeLayoutVariant.silicone,
  Host4EmulatorSiliconeLayoutVariant.modernSymmetric,
  Host4EmulatorSiliconeLayoutVariant.modernAsymmetric,
];

extension Host4EmulatorSiliconeLayoutVariantPresentation
    on Host4EmulatorSiliconeLayoutVariant {
  String get wireName => switch (this) {
    Host4EmulatorSiliconeLayoutVariant.silicone => 'silicone',
    Host4EmulatorSiliconeLayoutVariant.modernSymmetric => 'modern_symmetric',
    Host4EmulatorSiliconeLayoutVariant.modernAsymmetric => 'modern_asymmetric',
    Host4EmulatorSiliconeLayoutVariant.retroTraditional => 'retro_traditional',
  };

  String title(BuildContext context) => switch (this) {
    Host4EmulatorSiliconeLayoutVariant.silicone => EmulatorUiLocalizations.of(
      context,
    ).layoutSilicone,
    Host4EmulatorSiliconeLayoutVariant.modernSymmetric =>
      EmulatorUiLocalizations.of(context).layoutModernSymmetric,
    Host4EmulatorSiliconeLayoutVariant.modernAsymmetric =>
      EmulatorUiLocalizations.of(context).layoutModernAsymmetric,
    Host4EmulatorSiliconeLayoutVariant.retroTraditional =>
      EmulatorUiLocalizations.of(context).layoutRetroClassic,
  };
}
