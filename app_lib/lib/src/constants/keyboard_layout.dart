/// Keyboard layout configuration - Apple Magic Keyboard style (6 rows)
class KeyboardLayout {
  KeyboardLayout._();

  /// Function key row (ESC + F1-F12 + Delete)
  static const List<String> functionRow = [
    'ESC', 'F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8', 'F9', 'F10', 'F11', 'F12', 'DEL',
  ];

  /// Number row (with tilde/backtick)
  static const List<String> numberRow = [
    '`', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', 'BACKSPACE',
  ];

  /// Symbol row (shifted number keys)
  static const List<String> symbolRow = [
    '~', '!', '@', '#', r'$', '%', '^', '&', '*', '(', ')', '_', '+', 'BACKSPACE',
  ];

  /// QWERTY row (Tab + letters + brackets + backslash)
  static const List<String> qwertyRow = [
    'TAB', 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '[', ']', r'\',
  ];

  /// ASDF row (CapsLock + letters + semicolon + quote + Enter)
  static const List<String> asdfRow = [
    'CAPS', 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ';', "'", 'ENTER',
  ];

  /// ZXCV row (Shift + letters + comma + period + slash + Shift)
  static const List<String> zxcvRow = [
    'SHIFT', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', ',', '.', '/', 'SHIFT',
  ];

  /// Bottom row (modifiers + space + arrows)
  static const List<String> modifierRow = [
    'CTRL', 'ALT', 'SUPER', 'SPACE', 'FN', 'ALT', 'LEFT', 'UP', 'DOWN', 'RIGHT',
  ];

  /// All rows in order (for iteration)
  static const List<List<String>> allRows = [
    functionRow,
    numberRow,
    qwertyRow,
    asdfRow,
    zxcvRow,
    modifierRow,
  ];

  /// Special key identifiers
  static const String backspaceKey = 'BACKSPACE';
  static const String spaceKey = 'SPACE';
  static const String enterKey = 'ENTER';
  static const String shiftKey = 'SHIFT';
  static const String clearKey = 'CLEAR';
  static const String tabKey = 'TAB';
  static const String escKey = 'ESC';
  static const String capsKey = 'CAPS';
  static const String ctrlKey = 'CTRL';
  static const String altKey = 'ALT';
  static const String superKey = 'SUPER';
  static const String fnKey = 'FN';
  static const String deleteKey = 'DEL';

  /// Arrow keys
  static const String leftKey = 'LEFT';
  static const String rightKey = 'RIGHT';
  static const String upKey = 'UP';
  static const String downKey = 'DOWN';

  /// Key flex values (relative widths)
  static const Map<String, double> keyFlex = {
    'ESC': 1.0,
    'TAB': 1.5,
    'CAPS': 1.8,
    'SHIFT': 2.2,
    'CTRL': 1.3,
    'ALT': 1.3,
    'SUPER': 1.3,
    'FN': 1.3,
    'SPACE': 5.0,
    'ENTER': 2.0,
    'BACKSPACE': 2.0,
    'LEFT': 1.0,
    'RIGHT': 1.0,
    'UP': 1.0,
    'DOWN': 1.0,
  };
}
