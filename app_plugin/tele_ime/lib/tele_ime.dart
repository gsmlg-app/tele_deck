/// Android IME service with secondary display support
///
/// Provides:
/// - [TeleImeSettings]: IME status checks and settings management
/// - [TeleImeKeyboard]: Keyboard operations (commit text, backspace, etc.)
///
/// The actual IME service (InputMethodService) is implemented by extending
/// BaseImeService in native code. This Dart API provides:
/// - Status checks for setup flow (isImeEnabled, isImeActive)
/// - Settings management (openImeSettings, showImePicker)
/// - Keyboard operations for the keyboard UI
library tele_ime;

export 'src/tele_ime.dart';
export 'src/models/models.dart';
