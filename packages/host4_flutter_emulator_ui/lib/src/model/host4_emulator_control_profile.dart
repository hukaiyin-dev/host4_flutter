enum Host4EmulatorControlProfile {
  nes(hasShoulderButtons: false),
  megaDrive(hasShoulderButtons: true, hasFourFaceButtons: true),
  gb(hasShoulderButtons: false),
  gbc(hasShoulderButtons: false),
  gba(hasShoulderButtons: true, hasFourFaceButtons: true),
  snes(hasShoulderButtons: true, hasFourFaceButtons: true);

  const Host4EmulatorControlProfile({
    required this.hasShoulderButtons,
    this.hasFourFaceButtons = false,
  });

  final bool hasShoulderButtons;
  final bool hasFourFaceButtons;

  Set<String> get inputs => <String>{
    'up',
    'down',
    'left',
    'right',
    'a',
    'b',
    if (hasFourFaceButtons) ...<String>{'x', 'y'},
    'start',
    'select',
    if (hasShoulderButtons) ...<String>{'l', 'r'},
  };
}
