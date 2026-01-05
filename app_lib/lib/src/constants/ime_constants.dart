/// IPC port name for communication between screens
const String kIpcPortName = 'teledeck_ipc_port';

/// MethodChannel name for IME communication
const String kImeChannelName = 'tele_deck/ime';

/// Display rendering modes
class DisplayMode {
  DisplayMode._();

  /// Keyboard rendering on secondary display
  static const String secondary = 'secondary';

  /// Keyboard rendering on primary display (fallback)
  static const String primaryFallback = 'primary_fallback';
}

/// MethodChannel method names for IME communication
class ImeMethod {
  ImeMethod._();

  // Flutter -> Native (keyboard actions)
  static const String commitText = 'commitText';
  static const String backspace = 'backspace';
  static const String delete = 'delete';
  static const String enter = 'enter';
  static const String tab = 'tab';
  static const String moveCursor = 'moveCursor';
  static const String sendKeyEvent = 'sendKeyEvent';
  static const String getConnectionStatus = 'getConnectionStatus';

  // Native -> Flutter (status updates)
  static const String connectionStatus = 'connectionStatus';
  static const String displayModeChanged = 'displayModeChanged';

  // Flutter (Launcher) -> Native
  static const String isImeEnabled = 'isImeEnabled';
  static const String isImeActive = 'isImeActive';
  static const String openImeSettings = 'openImeSettings';
  static const String getCrashLogs = 'getCrashLogs';
  static const String getCrashLogDetail = 'getCrashLogDetail';
  static const String clearCrashLogs = 'clearCrashLogs';
}
