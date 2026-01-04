import 'dart:isolate';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/constants.dart';
import '../shared/protocol.dart';

/// Service for sending keyboard events via IPC
class KeyboardService {
  SendPort? _sendPort;
  bool _isConnected = false;

  KeyboardService() {
    _connect();
  }

  /// Attempt to connect to the main screen's receive port
  void _connect() {
    _sendPort = IsolateNameServer.lookupPortByName(kIpcPortName);
    _isConnected = _sendPort != null;
  }

  /// Check if connected, attempt reconnect if not
  bool get isConnected {
    if (!_isConnected) {
      _connect();
    }
    return _isConnected;
  }

  /// Send a keyboard event to the main screen
  bool sendEvent(KeyboardEvent event) {
    if (!isConnected) {
      return false;
    }

    try {
      _sendPort!.send(event.toMap());
      return true;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  /// Send a character key down event
  bool sendKeyDown(String char) {
    return sendEvent(KeyDown(char));
  }

  /// Send backspace event
  bool sendBackspace() {
    return sendEvent(const Backspace());
  }

  /// Send enter event
  bool sendEnter() {
    return sendEvent(const Enter());
  }

  /// Send space event
  bool sendSpace() {
    return sendEvent(const Space());
  }

  /// Send clear event
  bool sendClear() {
    return sendEvent(const Clear());
  }
}

/// Provider for keyboard service
final keyboardServiceProvider = Provider<KeyboardService>((ref) {
  return KeyboardService();
});

/// Provider for shift state
final shiftEnabledProvider = StateProvider<bool>((ref) => false);

/// Provider for caps lock state
final capsLockProvider = StateProvider<bool>((ref) => false);
