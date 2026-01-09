import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tele_constants/tele_constants.dart';

/// Centralized service for IME MethodChannel communication.
///
/// This service handles all communication between the Flutter app
/// and the native Android IME service.
class ImeChannelService {
  static const MethodChannel _channel = MethodChannel(kImeChannelName);

  /// Callback for connection status changes
  ValueChanged<bool>? onConnectionStatusChanged;

  /// Callback for display mode changes
  ValueChanged<String>? onDisplayModeChanged;

  /// Initialize the service and set up method call handler
  void init() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  /// Dispose the service
  void dispose() {
    _channel.setMethodCallHandler(null);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case ImeMethod.connectionStatus:
        final isConnected = call.arguments as bool? ?? false;
        onConnectionStatusChanged?.call(isConnected);
        break;
      case ImeMethod.displayModeChanged:
        final mode = call.arguments as String? ?? DisplayMode.primaryFallback;
        onDisplayModeChanged?.call(mode);
        break;
    }
  }

  // === Keyboard Actions (Flutter -> Native) ===

  /// Send text to the input field
  Future<void> commitText(String text) async {
    try {
      await _channel.invokeMethod(ImeMethod.commitText, text);
    } catch (e) {
      debugPrint('Failed to commit text: $e');
    }
  }

  /// Send backspace key
  Future<void> backspace() async {
    try {
      await _channel.invokeMethod(ImeMethod.backspace);
    } catch (e) {
      debugPrint('Failed to send backspace: $e');
    }
  }

  /// Send delete key
  Future<void> delete() async {
    try {
      await _channel.invokeMethod(ImeMethod.delete);
    } catch (e) {
      debugPrint('Failed to send delete: $e');
    }
  }

  /// Send enter key
  Future<void> enter() async {
    try {
      await _channel.invokeMethod(ImeMethod.enter);
    } catch (e) {
      debugPrint('Failed to send enter: $e');
    }
  }

  /// Send tab key
  Future<void> tab() async {
    try {
      await _channel.invokeMethod(ImeMethod.tab);
    } catch (e) {
      debugPrint('Failed to send tab: $e');
    }
  }

  /// Move cursor by offset
  Future<void> moveCursor(int offset) async {
    try {
      await _channel.invokeMethod(ImeMethod.moveCursor, offset);
    } catch (e) {
      debugPrint('Failed to move cursor: $e');
    }
  }

  /// Send a key event with modifiers
  Future<void> sendKeyEvent({
    required int keyCode,
    bool shift = false,
    bool ctrl = false,
    bool alt = false,
    bool meta = false,
  }) async {
    try {
      await _channel.invokeMethod(ImeMethod.sendKeyEvent, {
        'keyCode': keyCode,
        'shift': shift,
        'ctrl': ctrl,
        'alt': alt,
        'meta': meta,
      });
    } catch (e) {
      debugPrint('Failed to send key event: $e');
    }
  }

  /// Send a media key action (brightness, volume, media controls)
  Future<void> sendMediaKey(String action) async {
    try {
      await _channel.invokeMethod(ImeMethod.sendMediaKey, action);
    } catch (e) {
      debugPrint('Failed to send media key: $e');
    }
  }

  /// Get current connection status
  Future<bool> getConnectionStatus() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        ImeMethod.getConnectionStatus,
      );
      return result ?? false;
    } catch (e) {
      debugPrint('Failed to get connection status: $e');
      return false;
    }
  }

  // === Launcher Actions (Flutter -> Native) ===

  /// Check if TeleDeck IME is enabled in system settings
  Future<bool> isImeEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>(ImeMethod.isImeEnabled);
      return result ?? false;
    } catch (e) {
      debugPrint('Failed to check IME enabled: $e');
      return false;
    }
  }

  /// Check if TeleDeck IME is the active input method
  Future<bool> isImeActive() async {
    try {
      final result = await _channel.invokeMethod<bool>(ImeMethod.isImeActive);
      return result ?? false;
    } catch (e) {
      debugPrint('Failed to check IME active: $e');
      return false;
    }
  }

  /// Open system IME settings
  Future<void> openImeSettings() async {
    try {
      await _channel.invokeMethod(ImeMethod.openImeSettings);
    } catch (e) {
      debugPrint('Failed to open IME settings: $e');
    }
  }

  /// Open IME picker dialog to switch keyboards
  Future<void> openImePicker() async {
    try {
      await _channel.invokeMethod(ImeMethod.openImePicker);
    } catch (e) {
      debugPrint('Failed to open IME picker: $e');
    }
  }

  // === Crash Log Actions ===

  /// Get all crash logs
  Future<List<Map<String, dynamic>>> getCrashLogs() async {
    try {
      final result = await _channel.invokeMethod<List>(ImeMethod.getCrashLogs);
      return result?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      debugPrint('Failed to get crash logs: $e');
      return [];
    }
  }

  /// Get crash log detail by ID
  Future<Map<String, dynamic>?> getCrashLogDetail(String id) async {
    try {
      final result = await _channel.invokeMethod<Map>(
        ImeMethod.getCrashLogDetail,
        id,
      );
      return result?.cast<String, dynamic>();
    } catch (e) {
      debugPrint('Failed to get crash log detail: $e');
      return null;
    }
  }

  /// Clear all crash logs
  Future<bool> clearCrashLogs() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        ImeMethod.clearCrashLogs,
      );
      return result ?? false;
    } catch (e) {
      debugPrint('Failed to clear crash logs: $e');
      return false;
    }
  }
}
