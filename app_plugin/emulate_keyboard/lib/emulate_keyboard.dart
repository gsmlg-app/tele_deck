/// Emulate Keyboard Plugin
///
/// A Flutter plugin for physical keyboard emulation with multiple backends:
/// - VirtualDeviceManager (Android 14+, requires system privileges)
/// - uinput (requires root access)
/// - Bluetooth HID (no root, but complex setup)

export 'src/emulate_keyboard.dart';
export 'src/models/keyboard_backend.dart';
export 'src/models/key_event.dart';
export 'src/models/backend_status.dart';
