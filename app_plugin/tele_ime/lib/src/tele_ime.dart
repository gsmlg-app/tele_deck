import 'package:flutter/services.dart';

import 'models/models.dart';

export 'models/models.dart';

/// IME settings and status service
///
/// Provides functionality to:
/// - Check if IME is enabled/active
/// - Open IME settings
/// - List installed/enabled IMEs
///
/// Note: The actual IME service (keyboard rendering, text input) is
/// implemented by extending BaseImeService in native code. This Dart API
/// provides status checks and settings management.
class TeleImeSettings {
  TeleImeSettings._();

  static final TeleImeSettings _instance = TeleImeSettings._();

  /// Returns the singleton instance of [TeleImeSettings]
  static TeleImeSettings get instance => _instance;

  /// Method channel for settings communication
  static const MethodChannel _channel = MethodChannel('tele_ime/settings');

  /// Set the IME service class name for status checks
  Future<void> setImeServiceClass(String className) async {
    await _channel.invokeMethod('setImeServiceClass', {'className': className});
  }

  /// Check if the IME is enabled in system settings
  Future<bool> isImeEnabled({String? imeId}) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'isImeEnabled',
        imeId != null ? {'imeId': imeId} : null,
      );
      return result ?? false;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Failed to check IME enabled: ${e.message}');
      return false;
    }
  }

  /// Check if the IME is the current active IME
  Future<bool> isImeActive({String? imeId}) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'isImeActive',
        imeId != null ? {'imeId': imeId} : null,
      );
      return result ?? false;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Failed to check IME active: ${e.message}');
      return false;
    }
  }

  /// Open the system IME settings screen
  Future<void> openImeSettings() async {
    try {
      await _channel.invokeMethod('openImeSettings');
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Failed to open IME settings: ${e.message}');
    }
  }

  /// Show the IME picker dialog
  Future<void> showImePicker() async {
    try {
      await _channel.invokeMethod('showImePicker');
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Failed to show IME picker: ${e.message}');
    }
  }

  /// Get list of all enabled input method IDs
  Future<List<String>> getEnabledImes() async {
    try {
      final result =
          await _channel.invokeMethod<List<dynamic>>('getEnabledImes');
      if (result == null) return [];
      return result.cast<String>();
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Failed to get enabled IMEs: ${e.message}');
      return [];
    }
  }

  /// Get the current default input method ID
  Future<String?> getCurrentIme() async {
    try {
      return await _channel.invokeMethod<String>('getCurrentIme');
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Failed to get current IME: ${e.message}');
      return null;
    }
  }

  /// Get list of all installed input methods
  Future<List<ImeInfo>> getInstalledImes() async {
    try {
      final result =
          await _channel.invokeMethod<List<dynamic>>('getInstalledImes');
      if (result == null) return [];
      return result
          .map((e) => ImeInfo.fromMap(e as Map<dynamic, dynamic>))
          .toList();
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Failed to get installed IMEs: ${e.message}');
      return [];
    }
  }
}

/// IME keyboard operations service
///
/// This service is used within the keyboard UI to send text input operations
/// to the connected input field. It communicates with the native BaseImeService.
class TeleImeKeyboard {
  TeleImeKeyboard._();

  static final TeleImeKeyboard _instance = TeleImeKeyboard._();

  /// Returns the singleton instance of [TeleImeKeyboard]
  static TeleImeKeyboard get instance => _instance;

  /// Method channel for keyboard operations
  static const MethodChannel _channel = MethodChannel('tele_ime');

  /// Callback for when input starts
  void Function(EditorInfo editorInfo)? onInputStarted;

  /// Callback for when input finishes
  void Function()? onInputFinished;

  /// Initialize the keyboard service and set up callbacks
  void initialize() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onInputStarted':
          final args = call.arguments as Map<dynamic, dynamic>?;
          if (args != null) {
            onInputStarted?.call(EditorInfo.fromMap(args));
          }
        case 'onInputFinished':
          onInputFinished?.call();
      }
    });
  }

  /// Commit text to the current input field
  Future<void> commitText(String text) async {
    try {
      await _channel.invokeMethod('commitText', {'text': text});
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Failed to commit text: ${e.message}');
    }
  }

  /// Delete character before cursor (backspace)
  Future<void> backspace() async {
    try {
      await _channel.invokeMethod('backspace');
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Failed to backspace: ${e.message}');
    }
  }

  /// Delete character after cursor
  Future<void> delete() async {
    try {
      await _channel.invokeMethod('delete');
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Failed to delete: ${e.message}');
    }
  }

  /// Send enter/newline
  Future<void> enter() async {
    try {
      await _channel.invokeMethod('enter');
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Failed to enter: ${e.message}');
    }
  }

  /// Send tab character
  Future<void> tab() async {
    try {
      await _channel.invokeMethod('tab');
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Failed to tab: ${e.message}');
    }
  }

  /// Move cursor by offset
  Future<void> moveCursor(int offset) async {
    try {
      await _channel.invokeMethod('moveCursor', {'offset': offset});
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Failed to move cursor: ${e.message}');
    }
  }

  /// Send a key event with meta state
  Future<void> sendKeyEvent(int keyCode, {int metaState = 0}) async {
    try {
      await _channel.invokeMethod('sendKeyEvent', {
        'keyCode': keyCode,
        'metaState': metaState,
      });
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Failed to send key event: ${e.message}');
    }
  }

  /// Hide the keyboard
  Future<void> hideKeyboard() async {
    try {
      await _channel.invokeMethod('hideKeyboard');
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Failed to hide keyboard: ${e.message}');
    }
  }

  /// Get the current editor info
  Future<EditorInfo?> getEditorInfo() async {
    try {
      final result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('getEditorInfo');
      if (result == null) return null;
      return EditorInfo.fromMap(result);
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Failed to get editor info: ${e.message}');
      return null;
    }
  }
}
