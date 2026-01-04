import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';

/// Arrow key directions
enum ArrowDirection { up, down, left, right }

/// Modifier key types
enum ModifierType { ctrl, alt, super_ }

/// Service for sending keyboard events to the IME Service via MethodChannel
class KeyboardService {
  final MethodChannel _channel = imeChannel;
  bool _isConnected = false;

  KeyboardService();

  /// Check if connected to input field
  bool get isConnected => _isConnected;

  /// Update connection status (called from main.dart)
  void setConnected(bool connected) {
    _isConnected = connected;
  }

  /// Send text to the current input field
  Future<bool> sendKeyDown(String char) async {
    try {
      await _channel.invokeMethod('commitText', {'text': char});
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Send backspace event
  Future<bool> sendBackspace() async {
    try {
      await _channel.invokeMethod('backspace');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Send enter event
  Future<bool> sendEnter() async {
    try {
      await _channel.invokeMethod('enter');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Send space event
  Future<bool> sendSpace() async {
    return sendKeyDown(' ');
  }

  /// Send clear event (select all + delete)
  Future<bool> sendClear() async {
    // TODO: Implement select all + delete via key events
    return true;
  }

  /// Send tab event
  Future<bool> sendTab() async {
    try {
      await _channel.invokeMethod('tab');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Send escape event
  Future<bool> sendEscape() async {
    try {
      await _channel.invokeMethod('sendKeyEvent', {
        'keyCode': 111, // KEYCODE_ESCAPE
        'metaState': 0,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Send delete (forward) event
  Future<bool> sendDelete() async {
    try {
      await _channel.invokeMethod('delete');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Send function key event (F1-F12)
  Future<bool> sendFunctionKey(int number) async {
    try {
      // F1 = KEYCODE_F1 (131), F2 = 132, etc.
      final keyCode = 130 + number;
      await _channel.invokeMethod('sendKeyEvent', {
        'keyCode': keyCode,
        'metaState': 0,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Send arrow key event
  Future<bool> sendArrowKey(ArrowDirection direction) async {
    try {
      await _channel.invokeMethod('moveCursor', {
        'direction': direction.name,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Send modifier key event
  Future<bool> sendModifier(ModifierType modifier, {required bool pressed}) async {
    // Modifier state is tracked locally for now
    // The native side will need to handle modifier combinations
    return true;
  }

  /// Send caps lock event
  Future<bool> sendCapsLock(bool enabled) async {
    // Caps lock state is tracked locally
    return true;
  }
}

/// Provider for keyboard service
final keyboardServiceProvider = Provider<KeyboardService>((ref) {
  final service = KeyboardService();

  // Listen for connection status changes
  ref.listen(imeConnectionProvider, (previous, next) {
    service.setConnected(next);
  });

  return service;
});

/// Provider for shift state
final shiftEnabledProvider = StateProvider<bool>((ref) => false);

/// Provider for shift lock state (when long pressed)
final shiftLockedProvider = StateProvider<bool>((ref) => false);

/// Provider for caps lock state
final capsLockProvider = StateProvider<bool>((ref) => false);

/// Provider for ctrl key state
final ctrlEnabledProvider = StateProvider<bool>((ref) => false);

/// Provider for alt key state
final altEnabledProvider = StateProvider<bool>((ref) => false);

/// Provider for super key state
final superEnabledProvider = StateProvider<bool>((ref) => false);

/// Provider for fn key state
final fnEnabledProvider = StateProvider<bool>((ref) => false);

/// Keyboard layout mode
enum KeyboardMode { standard, numpad, emoji }

/// Provider for keyboard layout mode
final keyboardModeProvider = StateProvider<KeyboardMode>((ref) => KeyboardMode.standard);

/// Provider for showing mode selector overlay
final showModeSelectorProvider = StateProvider<bool>((ref) => false);
