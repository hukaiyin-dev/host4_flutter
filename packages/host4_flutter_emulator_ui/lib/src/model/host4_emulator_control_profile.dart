enum Host4EmulatorControlProfile {
  gb(hasShoulderButtons: false),
  gbc(hasShoulderButtons: false),
  gba(hasShoulderButtons: true);

  const Host4EmulatorControlProfile({required this.hasShoulderButtons});

  final bool hasShoulderButtons;

  Set<String> get inputs => <String>{
    'up',
    'down',
    'left',
    'right',
    'a',
    'b',
    'start',
    'select',
    if (hasShoulderButtons) ...<String>{'l', 'r'},
  };
}
