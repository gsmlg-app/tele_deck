/// Represents a keyboard key event to be emulated.
class EmulatedKeyEvent {
  /// Android KeyEvent keyCode (e.g., KeyEvent.KEYCODE_A = 29).
  final int keyCode;

  /// Whether the Shift modifier is pressed.
  final bool shift;

  /// Whether the Ctrl modifier is pressed.
  final bool ctrl;

  /// Whether the Alt modifier is pressed.
  final bool alt;

  /// Whether the Meta (Windows/Command) modifier is pressed.
  final bool meta;

  /// Whether this is a key down event (true) or key up event (false).
  /// If null, both down and up events are sent.
  final bool? isDown;

  const EmulatedKeyEvent({
    required this.keyCode,
    this.shift = false,
    this.ctrl = false,
    this.alt = false,
    this.meta = false,
    this.isDown,
  });

  /// Create a key press event (down + up).
  const EmulatedKeyEvent.press({
    required this.keyCode,
    this.shift = false,
    this.ctrl = false,
    this.alt = false,
    this.meta = false,
  }) : isDown = null;

  /// Create a key down event only.
  const EmulatedKeyEvent.down({
    required this.keyCode,
    this.shift = false,
    this.ctrl = false,
    this.alt = false,
    this.meta = false,
  }) : isDown = true;

  /// Create a key up event only.
  const EmulatedKeyEvent.up({
    required this.keyCode,
    this.shift = false,
    this.ctrl = false,
    this.alt = false,
    this.meta = false,
  }) : isDown = false;

  /// Convert to a map for platform channel communication.
  Map<String, dynamic> toMap() {
    return {
      'keyCode': keyCode,
      'shift': shift,
      'ctrl': ctrl,
      'alt': alt,
      'meta': meta,
      if (isDown != null) 'isDown': isDown,
    };
  }

  @override
  String toString() {
    final modifiers = <String>[];
    if (ctrl) modifiers.add('Ctrl');
    if (alt) modifiers.add('Alt');
    if (shift) modifiers.add('Shift');
    if (meta) modifiers.add('Meta');
    final modStr = modifiers.isEmpty ? '' : '${modifiers.join('+')}+';
    final action = isDown == null ? 'press' : (isDown! ? 'down' : 'up');
    return 'EmulatedKeyEvent($modStr$keyCode, $action)';
  }
}

/// Common Android KeyEvent keycodes.
/// See: https://developer.android.com/reference/android/view/KeyEvent
abstract class AndroidKeyCode {
  // Letters
  static const int keyA = 29;
  static const int keyB = 30;
  static const int keyC = 31;
  static const int keyD = 32;
  static const int keyE = 33;
  static const int keyF = 34;
  static const int keyG = 35;
  static const int keyH = 36;
  static const int keyI = 37;
  static const int keyJ = 38;
  static const int keyK = 39;
  static const int keyL = 40;
  static const int keyM = 41;
  static const int keyN = 42;
  static const int keyO = 43;
  static const int keyP = 44;
  static const int keyQ = 45;
  static const int keyR = 46;
  static const int keyS = 47;
  static const int keyT = 48;
  static const int keyU = 49;
  static const int keyV = 50;
  static const int keyW = 51;
  static const int keyX = 52;
  static const int keyY = 53;
  static const int keyZ = 54;

  // Numbers
  static const int key0 = 7;
  static const int key1 = 8;
  static const int key2 = 9;
  static const int key3 = 10;
  static const int key4 = 11;
  static const int key5 = 12;
  static const int key6 = 13;
  static const int key7 = 14;
  static const int key8 = 15;
  static const int key9 = 16;

  // Function keys
  static const int f1 = 131;
  static const int f2 = 132;
  static const int f3 = 133;
  static const int f4 = 134;
  static const int f5 = 135;
  static const int f6 = 136;
  static const int f7 = 137;
  static const int f8 = 138;
  static const int f9 = 139;
  static const int f10 = 140;
  static const int f11 = 141;
  static const int f12 = 142;

  // Modifiers
  static const int shiftLeft = 59;
  static const int shiftRight = 60;
  static const int ctrlLeft = 113;
  static const int ctrlRight = 114;
  static const int altLeft = 57;
  static const int altRight = 58;
  static const int metaLeft = 117;
  static const int metaRight = 118;
  static const int capsLock = 115;

  // Special keys
  static const int enter = 66;
  static const int escape = 111;
  static const int backspace = 67;
  static const int delete = 112;
  static const int tab = 61;
  static const int space = 62;
  static const int insert = 124;
  static const int home = 122;
  static const int end = 123;
  static const int pageUp = 92;
  static const int pageDown = 93;

  // Arrow keys
  static const int dpadUp = 19;
  static const int dpadDown = 20;
  static const int dpadLeft = 21;
  static const int dpadRight = 22;

  // Symbols
  static const int minus = 69;
  static const int equals = 70;
  static const int leftBracket = 71;
  static const int rightBracket = 72;
  static const int backslash = 73;
  static const int semicolon = 74;
  static const int apostrophe = 75;
  static const int grave = 68;
  static const int comma = 55;
  static const int period = 56;
  static const int slash = 76;

  // Numpad
  static const int numpad0 = 144;
  static const int numpad1 = 145;
  static const int numpad2 = 146;
  static const int numpad3 = 147;
  static const int numpad4 = 148;
  static const int numpad5 = 149;
  static const int numpad6 = 150;
  static const int numpad7 = 151;
  static const int numpad8 = 152;
  static const int numpad9 = 153;
  static const int numpadDivide = 154;
  static const int numpadMultiply = 155;
  static const int numpadSubtract = 156;
  static const int numpadAdd = 157;
  static const int numpadEnter = 160;
  static const int numpadDot = 158;

  // Media keys
  static const int volumeUp = 24;
  static const int volumeDown = 25;
  static const int volumeMute = 164;
  static const int mediaPlayPause = 85;
  static const int mediaNext = 87;
  static const int mediaPrevious = 88;
  static const int mediaStop = 86;
}
