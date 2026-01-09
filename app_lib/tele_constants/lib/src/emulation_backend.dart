/// Backend for physical keyboard emulation.
///
/// When [KeyboardType.physical] is selected, this determines
/// which underlying technology is used to emulate a hardware keyboard.
enum EmulationBackend {
  /// VirtualDeviceManager backend (Android 14+).
  /// Requires system privileges but is the official Android API.
  virtualDevice,

  /// uinput backend (Linux kernel).
  /// Requires root access but works on any Android version.
  uinput,

  /// Bluetooth HID backend.
  /// No root required but needs Bluetooth and complex pairing.
  bluetoothHid,
}

/// Extension methods for [EmulationBackend].
extension EmulationBackendExtension on EmulationBackend {
  /// Human-readable display name.
  String get displayName {
    switch (this) {
      case EmulationBackend.virtualDevice:
        return 'Virtual Device';
      case EmulationBackend.uinput:
        return 'uinput (Root)';
      case EmulationBackend.bluetoothHid:
        return 'Bluetooth HID';
    }
  }

  /// Short description of the backend.
  String get description {
    switch (this) {
      case EmulationBackend.virtualDevice:
        return 'Android 14+ API. Requires system app privileges.';
      case EmulationBackend.uinput:
        return 'Kernel-level input. Requires root access.';
      case EmulationBackend.bluetoothHid:
        return 'Bluetooth keyboard emulation. No root required.';
    }
  }

  /// Minimum Android API level required.
  int get minApiLevel {
    switch (this) {
      case EmulationBackend.virtualDevice:
        return 34; // Android 14
      case EmulationBackend.uinput:
        return 21; // Android 5+
      case EmulationBackend.bluetoothHid:
        return 28; // Android 9
    }
  }

  /// Convert to string for JSON serialization.
  String toJson() => name;

  /// Parse from JSON string.
  static EmulationBackend fromJson(String? value) {
    switch (value) {
      case 'virtualDevice':
        return EmulationBackend.virtualDevice;
      case 'uinput':
        return EmulationBackend.uinput;
      case 'bluetoothHid':
        return EmulationBackend.bluetoothHid;
      default:
        return EmulationBackend.virtualDevice;
    }
  }
}
