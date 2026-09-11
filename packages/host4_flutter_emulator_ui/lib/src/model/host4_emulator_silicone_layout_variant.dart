import '../l10n/emulator_ui_strings.dart';

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

  String get title => switch (this) {
    Host4EmulatorSiliconeLayoutVariant.silicone =>
      EmulatorUiStrings.t('layout.silicone'),
    Host4EmulatorSiliconeLayoutVariant.modernSymmetric =>
      EmulatorUiStrings.t('layout.modernSymmetric'),
    Host4EmulatorSiliconeLayoutVariant.modernAsymmetric =>
      EmulatorUiStrings.t('layout.modernAsymmetric'),
    Host4EmulatorSiliconeLayoutVariant.retroTraditional =>
      EmulatorUiStrings.t('layout.retroClassic'),
  };
}
