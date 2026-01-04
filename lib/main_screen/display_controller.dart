import 'dart:isolate';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/constants.dart';
import '../shared/protocol.dart';

/// State notifier for the input display text
class InputTextNotifier extends StateNotifier<String> {
  InputTextNotifier() : super('');

  /// Add a character to the input
  void addCharacter(String char) {
    state = '$state$char';
  }

  /// Remove last character (backspace)
  void removeLastCharacter() {
    if (state.isNotEmpty) {
      state = state.substring(0, state.length - 1);
    }
  }

  /// Add a space
  void addSpace() {
    state = '$state ';
  }

  /// Add newline (enter)
  void addNewline() {
    state = '$state\n';
  }

  /// Clear all text
  void clear() {
    state = '';
  }

  /// Handle incoming keyboard event
  void handleEvent(KeyboardEvent event) {
    switch (event) {
      case KeyDown(:final char):
        addCharacter(char);
      case KeyUp():
        // Optional: visual feedback
        break;
      case Backspace():
        removeLastCharacter();
      case Enter():
        addNewline();
      case Space():
        addSpace();
      case Clear():
        clear();
      case Shift():
        // Handled on keyboard side
        break;
    }
  }
}

/// Provider for the input text state
final inputTextProvider = StateNotifierProvider<InputTextNotifier, String>(
  (ref) => InputTextNotifier(),
);

/// Display controller that manages IPC listening
class DisplayController {
  final ReceivePort _receivePort;
  final InputTextNotifier _notifier;
  bool _isRegistered = false;

  DisplayController(this._notifier) : _receivePort = ReceivePort() {
    _initialize();
  }

  void _initialize() {
    // Register port with IsolateNameServer
    _isRegistered = IsolateNameServer.registerPortWithName(
      _receivePort.sendPort,
      kIpcPortName,
    );

    if (_isRegistered) {
      // Listen for incoming events
      _receivePort.listen(_handleMessage);
    }
  }

  void _handleMessage(dynamic message) {
    if (message is Map<String, dynamic>) {
      try {
        final event = KeyboardEvent.fromMap(message);
        _notifier.handleEvent(event);
      } catch (e) {
        // Silently ignore malformed messages
      }
    }
  }

  bool get isRegistered => _isRegistered;

  void dispose() {
    if (_isRegistered) {
      IsolateNameServer.removePortNameMapping(kIpcPortName);
    }
    _receivePort.close();
  }
}

/// Provider for display controller
final displayControllerProvider = Provider.autoDispose<DisplayController>((ref) {
  final notifier = ref.read(inputTextProvider.notifier);
  final controller = DisplayController(notifier);

  ref.onDispose(() {
    controller.dispose();
  });

  return controller;
});

/// Provider for cursor visibility (blinking)
final cursorVisibleProvider = StateProvider<bool>((ref) => true);
