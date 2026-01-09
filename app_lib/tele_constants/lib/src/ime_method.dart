/// MethodChannel method names for IME communication
class ImeMethod {
  ImeMethod._();

  // Flutter → Native (keyboard actions)
  static const String commitText = 'commitText';
  static const String backspace = 'backspace';
  static const String delete = 'delete';
  static const String enter = 'enter';
  static const String tab = 'tab';
  static const String moveCursor = 'moveCursor';
  static const String sendKeyEvent = 'sendKeyEvent';
  static const String sendMediaKey = 'sendMediaKey';
  static const String getConnectionStatus = 'getConnectionStatus';

  // Native → Flutter (status updates)
  static const String connectionStatus = 'connectionStatus';
  static const String displayModeChanged = 'displayModeChanged';

  // Flutter (Launcher) → Native
  static const String isImeEnabled = 'isImeEnabled';
  static const String isImeActive = 'isImeActive';
  static const String openImeSettings = 'openImeSettings';
  static const String openImePicker = 'openImePicker';
  static const String getCrashLogs = 'getCrashLogs';
  static const String getCrashLogDetail = 'getCrashLogDetail';
  static const String clearCrashLogs = 'clearCrashLogs';
}
