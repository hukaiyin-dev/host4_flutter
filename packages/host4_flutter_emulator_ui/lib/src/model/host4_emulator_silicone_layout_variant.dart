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
    Host4EmulatorSiliconeLayoutVariant.silicone => '硅胶垫',
    Host4EmulatorSiliconeLayoutVariant.modernSymmetric => '现代对称',
    Host4EmulatorSiliconeLayoutVariant.modernAsymmetric => '现代非对称',
    Host4EmulatorSiliconeLayoutVariant.retroTraditional => '复古传统',
  };
}
