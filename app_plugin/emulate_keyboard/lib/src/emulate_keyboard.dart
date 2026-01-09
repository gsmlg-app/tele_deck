import 'package:flutter/services.dart';
import 'models/keyboard_backend.dart';
import 'models/key_event.dart';
import 'models/backend_status.dart';

/// Physical keyboard emulation plugin.
///
/// Provides three backends for emulating a hardware keyboard:
/// - [KeyboardBackend.virtualDevice]: Android VirtualDeviceManager (API 34+)
/// - [KeyboardBackend.uinput]: Linux uinput kernel module (root required)
/// - [KeyboardBackend.bluetoothHid]: Bluetooth HID device emulation
///
/// Example usage:
/// ```dart
/// final keyboard = EmulateKeyboard();
///
/// // Check available backends
/// final status = await keyboard.getBackendStatus();
/// print('Available: ${status.availableBackends}');
///
/// // Initialize a backend
/// await keyboard.initialize(KeyboardBackend.virtualDevice);
///
/// // Send key events
/// await keyboard.sendKeyEvent(EmulatedKeyEvent.press(
///   keyCode: AndroidKeyCode.keyA,
///   shift: true,
/// ));
///
/// // Type text
/// await keyboard.typeText('Hello, World!');
///
/// // Cleanup
/// await keyboard.dispose();
/// ```
class EmulateKeyboard {
  static const MethodChannel _channel = MethodChannel('emulate_keyboard');

  /// The currently active backend, if any.
  KeyboardBackend? _activeBackend;

  /// Get the currently active backend.
  KeyboardBackend? get activeBackend => _activeBackend;

  /// Get status of all backends.
  Future<AllBackendsStatus> getBackendStatus() async {
    final result = await _channel.invokeMethod<Map<Object?, Object?>>('getBackendStatus');
    if (result == null) {
      throw PlatformException(
        code: 'NULL_RESULT',
        message: 'Failed to get backend status',
      );
    }
    return AllBackendsStatus.fromMap(result.cast<String, dynamic>());
  }

  /// Check if a specific backend is available.
  Future<bool> isBackendAvailable(KeyboardBackend backend) async {
    final result = await _channel.invokeMethod<bool>('isBackendAvailable', {
      'backend': backend.name,
    });
    return result ?? false;
  }

  /// Initialize a backend for keyboard emulation.
  ///
  /// Returns true if initialization succeeded.
  /// Throws [PlatformException] if initialization fails.
  Future<bool> initialize(KeyboardBackend backend) async {
    final result = await _channel.invokeMethod<bool>('initialize', {
      'backend': backend.name,
    });
    if (result == true) {
      _activeBackend = backend;
    }
    return result ?? false;
  }

  /// Dispose the current backend and release resources.
  Future<void> dispose() async {
    await _channel.invokeMethod<void>('dispose');
    _activeBackend = null;
  }

  /// Send a single key event.
  ///
  /// The [event] specifies the key code and modifiers.
  /// If [event.isDown] is null, both key down and key up events are sent.
  Future<bool> sendKeyEvent(EmulatedKeyEvent event) async {
    final result = await _channel.invokeMethod<bool>('sendKeyEvent', event.toMap());
    return result ?? false;
  }

  /// Send multiple key events in sequence.
  Future<bool> sendKeyEvents(List<EmulatedKeyEvent> events) async {
    final result = await _channel.invokeMethod<bool>('sendKeyEvents', {
      'events': events.map((e) => e.toMap()).toList(),
    });
    return result ?? false;
  }

  /// Type a string of text character by character.
  ///
  /// This converts each character to the appropriate key events
  /// including shift for uppercase letters and symbols.
  Future<bool> typeText(String text) async {
    final result = await _channel.invokeMethod<bool>('typeText', {
      'text': text,
    });
    return result ?? false;
  }

  /// Send a key combination (e.g., Ctrl+C, Alt+Tab).
  ///
  /// All modifier keys are pressed, then the main key is pressed and released,
  /// then all modifier keys are released.
  Future<bool> sendKeyCombination({
    required int keyCode,
    bool ctrl = false,
    bool alt = false,
    bool shift = false,
    bool meta = false,
  }) async {
    return sendKeyEvent(EmulatedKeyEvent.press(
      keyCode: keyCode,
      ctrl: ctrl,
      alt: alt,
      shift: shift,
      meta: meta,
    ));
  }

  // === Bluetooth HID specific methods ===

  /// Start Bluetooth HID advertising (for bluetoothHid backend).
  ///
  /// Makes the device discoverable as a Bluetooth keyboard.
  Future<bool> startBluetoothAdvertising() async {
    final result = await _channel.invokeMethod<bool>('startBluetoothAdvertising');
    return result ?? false;
  }

  /// Stop Bluetooth HID advertising.
  Future<bool> stopBluetoothAdvertising() async {
    final result = await _channel.invokeMethod<bool>('stopBluetoothAdvertising');
    return result ?? false;
  }

  /// Get paired Bluetooth devices.
  Future<List<Map<String, String>>> getBluetoothDevices() async {
    final result = await _channel.invokeMethod<List<Object?>>('getBluetoothDevices');
    if (result == null) return [];
    return result
        .whereType<Map<Object?, Object?>>()
        .map((m) => m.cast<String, String>())
        .toList();
  }

  /// Connect to a Bluetooth host device by MAC address.
  Future<bool> connectBluetoothDevice(String macAddress) async {
    final result = await _channel.invokeMethod<bool>('connectBluetoothDevice', {
      'macAddress': macAddress,
    });
    return result ?? false;
  }

  /// Disconnect from the current Bluetooth host.
  Future<bool> disconnectBluetooth() async {
    final result = await _channel.invokeMethod<bool>('disconnectBluetooth');
    return result ?? false;
  }

  // === uinput specific methods ===

  /// Check if root access is available (for uinput backend).
  Future<bool> checkRootAccess() async {
    final result = await _channel.invokeMethod<bool>('checkRootAccess');
    return result ?? false;
  }

  /// Request root access (shows su dialog if needed).
  Future<bool> requestRootAccess() async {
    final result = await _channel.invokeMethod<bool>('requestRootAccess');
    return result ?? false;
  }
}
