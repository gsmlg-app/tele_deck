// TeleDeck IPC Constants
// Shared between Main Screen and Keyboard Screen

/// IPC port name for communication between screens
const String kIpcPortName = 'teledeck_ipc_port';

/// Cyberpunk Theme Colors
class TeleDeckColors {
  TeleDeckColors._();

  /// Dark background
  static const int darkBackground = 0xFF0F0F1A;

  /// Secondary background
  static const int secondaryBackground = 0xFF1A1A2E;

  /// Neon cyan accent
  static const int neonCyan = 0xFF00FFFF;

  /// Neon magenta accent
  static const int neonMagenta = 0xFFFF00FF;

  /// Neon purple
  static const int neonPurple = 0xFF8B5CF6;

  /// Key surface color
  static const int keySurface = 0xFF2A2A4A;

  /// Key pressed color
  static const int keyPressed = 0xFF3A3A6A;

  /// Text primary
  static const int textPrimary = 0xFFE0E0E0;

  /// Cursor color
  static const int cursorColor = 0xFF00FFFF;
}

/// Keyboard layout configuration
class KeyboardLayout {
  KeyboardLayout._();

  /// Standard QWERTY rows
  static const List<List<String>> qwertyRows = [
    ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
    ['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
  ];

  /// Symbol row keys
  static const List<String> symbolRow = [
    '!', '@', '#', '\$', '%', '^', '&', '*', '(', ')',
  ];

  /// Special key identifiers
  static const String backspaceKey = 'BACKSPACE';
  static const String spaceKey = 'SPACE';
  static const String enterKey = 'ENTER';
  static const String shiftKey = 'SHIFT';
  static const String clearKey = 'CLEAR';
}
