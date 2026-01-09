/// Available keyboard emulation backends.
///
/// Each backend has different requirements and capabilities:
/// - [virtualDevice]: Uses Android VirtualDeviceManager API (Android 14+)
/// - [uinput]: Uses Linux uinput kernel module (requires root)
/// - [bluetoothHid]: Emulates a Bluetooth HID keyboard (no root needed)
enum KeyboardBackend {
  /// VirtualDeviceManager backend (Android 14+).
  ///
  /// Requirements:
  /// - Android 14 (API 34) or higher
  /// - CREATE_VIRTUAL_DEVICE permission (system/privileged app)
  ///
  /// Pros:
  /// - Official Android API
  /// - No root required (but needs system privileges)
  /// - Full keyboard emulation
  ///
  /// Cons:
  /// - Only works on Android 14+
  /// - Requires system app signing or privileged install
  virtualDevice,

  /// uinput backend (Linux kernel).
  ///
  /// Requirements:
  /// - Root access (su or similar)
  /// - /dev/uinput accessible
  ///
  /// Pros:
  /// - Works on any Android version
  /// - True kernel-level input injection
  /// - Most compatible with games
  ///
  /// Cons:
  /// - Requires root access
  /// - Needs native JNI code
  uinput,

  /// Bluetooth HID backend.
  ///
  /// Requirements:
  /// - Bluetooth enabled
  /// - BLUETOOTH permissions
  ///
  /// Pros:
  /// - No root required
  /// - Works on most Android versions (API 28+)
  /// - True Bluetooth keyboard emulation
  ///
  /// Cons:
  /// - Complex pairing setup
  /// - May have latency
  /// - Device must support BT HID device role
  bluetoothHid,
}

/// Extension methods for [KeyboardBackend].
extension KeyboardBackendExtension on KeyboardBackend {
  /// Human-readable name for the backend.
  String get displayName {
    switch (this) {
      case KeyboardBackend.virtualDevice:
        return 'Virtual Device (Android 14+)';
      case KeyboardBackend.uinput:
        return 'uinput (Root)';
      case KeyboardBackend.bluetoothHid:
        return 'Bluetooth HID';
    }
  }

  /// Short description of the backend.
  String get description {
    switch (this) {
      case KeyboardBackend.virtualDevice:
        return 'Uses Android VirtualDeviceManager API. Requires system privileges.';
      case KeyboardBackend.uinput:
        return 'Kernel-level input injection. Requires root access.';
      case KeyboardBackend.bluetoothHid:
        return 'Emulates a Bluetooth keyboard. No root required.';
    }
  }

  /// Minimum Android API level required.
  int get minApiLevel {
    switch (this) {
      case KeyboardBackend.virtualDevice:
        return 34; // Android 14
      case KeyboardBackend.uinput:
        return 21; // Any Android 5+
      case KeyboardBackend.bluetoothHid:
        return 28; // Android 9 (BluetoothHidDevice API)
    }
  }
}
