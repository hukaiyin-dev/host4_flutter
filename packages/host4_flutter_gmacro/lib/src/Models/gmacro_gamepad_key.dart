/// Keep aligned with iOS / Android native key definitions.
enum GamepadKey {
  none(0x00),

  m1(0x01),
  m2(0x02),
  m3(0x03),
  m4(0x04),
  m5(0x05),
  m6(0x06),

  slL(0x11),
  srL(0x12),
  slR(0x13),
  srR(0x14),
  setL(0x21),
  setR(0x22),

  a(0xA0),
  b(0xA1),
  x(0xA2),
  y(0xA3),
  l1(0xA4),
  l2(0xA5),
  l3(0xA6),
  r1(0xA7),
  r2(0xA8),
  r3(0xA9),

  back(0xAA),
  start(0xAB),
  menu(0xAC),
  home(0xAD),
  keyI(0xAE),
  select(0xAF),

  cross(0xD0),
  left(0xD1),
  right(0xD2),
  up(0xD3),
  down(0xD4),
  leftUp(0xD5),
  rightUp(0xD6),
  leftDown(0xD7),
  rightDown(0xD8),

  j1(0xE0),
  lrLeft(0xE1),
  lrRight(0xE2),
  lrUp(0xE3),
  lrDown(0xE4),
  lrLeftUp(0xE5),
  lrRightUp(0xE6),
  lrLeftDown(0xE7),
  lrRightDown(0xE8),

  j2(0xF0),
  rrLeft(0xF1),
  rrRight(0xF2),
  rrUp(0xF3),
  rrDown(0xF4),
  rrLeftUp(0xF5),
  rrRightUp(0xF6),
  rrLeftDown(0xF7),
  rrRightDown(0xF8);

  const GamepadKey(this.value);

  final int value;

  static final Map<int, GamepadKey> _valueMap = {
    for (final key in GamepadKey.values) key.value: key,
  };

  static GamepadKey? fromValue(int value) => _valueMap[value];

  static GamepadKey? fromName(String name) {
    for (final key in GamepadKey.values) {
      if (key.name == name) return key;
    }
    return null;
  }
}
