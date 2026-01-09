import 'package:equatable/equatable.dart';
import 'package:tele_constants/tele_constants.dart';

import 'keyboard_event.dart';

/// Backend availability status
enum BackendAvailability {
  /// Not yet checked
  unknown,
  /// Currently checking availability
  checking,
  /// Available and can be used
  available,
  /// Not available on this device
  unavailable,
  /// Disabled (not implemented yet)
  disabled,
}

/// Keyboard state
class KeyboardState extends Equatable {
  /// Connection status
  final bool isConnected;

  /// Current keyboard mode
  final KeyboardMode mode;

  /// Show mode selector overlay
  final bool showModeSelector;

  /// Shift enabled (single press)
  final bool shiftEnabled;

  /// Shift locked (long press)
  final bool shiftLocked;

  /// Caps lock enabled
  final bool capsLockEnabled;

  /// Ctrl enabled
  final bool ctrlEnabled;

  /// Alt enabled
  final bool altEnabled;

  /// Super (Win/Cmd) enabled
  final bool superEnabled;

  /// Fn enabled
  final bool fnEnabled;

  /// Display mode (secondary/primary_fallback)
  final String displayMode;

  /// Keyboard input type (ime or physical)
  final KeyboardType keyboardType;

  /// Emulation backend for physical keyboard mode
  final EmulationBackend emulationBackend;

  /// Whether the emulation backend is initialized
  final bool isEmulationInitialized;

  /// Emulation backend status message
  final String emulationStatus;

  /// Whether to show backend selection screen
  final bool showBackendSelection;

  /// VirtualDeviceManager availability status
  final BackendAvailability virtualDeviceAvailability;

  /// uinput availability status (root check)
  final BackendAvailability uinputAvailability;

  /// Bluetooth HID availability status
  final BackendAvailability bluetoothHidAvailability;

  /// Status message for each backend
  final String virtualDeviceStatus;
  final String uinputStatus;
  final String bluetoothHidStatus;

  const KeyboardState({
    this.isConnected = false,
    this.mode = KeyboardMode.standard,
    this.showModeSelector = false,
    this.shiftEnabled = false,
    this.shiftLocked = false,
    this.capsLockEnabled = false,
    this.ctrlEnabled = false,
    this.altEnabled = false,
    this.superEnabled = false,
    this.fnEnabled = false,
    this.displayMode = 'primary_fallback',
    this.keyboardType = KeyboardType.ime,
    this.emulationBackend = EmulationBackend.virtualDevice,
    this.isEmulationInitialized = false,
    this.emulationStatus = '',
    this.showBackendSelection = true,
    this.virtualDeviceAvailability = BackendAvailability.unknown,
    this.uinputAvailability = BackendAvailability.unknown,
    this.bluetoothHidAvailability = BackendAvailability.unknown,
    this.virtualDeviceStatus = '',
    this.uinputStatus = '',
    this.bluetoothHidStatus = '',
  });

  /// Initial state
  factory KeyboardState.initial() => const KeyboardState();

  /// Whether any shift modifier is active
  bool get isShiftActive => shiftEnabled || shiftLocked || capsLockEnabled;

  /// Whether any modifier is active
  bool get hasActiveModifier =>
      ctrlEnabled || altEnabled || superEnabled || fnEnabled;

  KeyboardState copyWith({
    bool? isConnected,
    KeyboardMode? mode,
    bool? showModeSelector,
    bool? shiftEnabled,
    bool? shiftLocked,
    bool? capsLockEnabled,
    bool? ctrlEnabled,
    bool? altEnabled,
    bool? superEnabled,
    bool? fnEnabled,
    String? displayMode,
    KeyboardType? keyboardType,
    EmulationBackend? emulationBackend,
    bool? isEmulationInitialized,
    String? emulationStatus,
    bool? showBackendSelection,
    BackendAvailability? virtualDeviceAvailability,
    BackendAvailability? uinputAvailability,
    BackendAvailability? bluetoothHidAvailability,
    String? virtualDeviceStatus,
    String? uinputStatus,
    String? bluetoothHidStatus,
  }) {
    return KeyboardState(
      isConnected: isConnected ?? this.isConnected,
      mode: mode ?? this.mode,
      showModeSelector: showModeSelector ?? this.showModeSelector,
      shiftEnabled: shiftEnabled ?? this.shiftEnabled,
      shiftLocked: shiftLocked ?? this.shiftLocked,
      capsLockEnabled: capsLockEnabled ?? this.capsLockEnabled,
      ctrlEnabled: ctrlEnabled ?? this.ctrlEnabled,
      altEnabled: altEnabled ?? this.altEnabled,
      superEnabled: superEnabled ?? this.superEnabled,
      fnEnabled: fnEnabled ?? this.fnEnabled,
      displayMode: displayMode ?? this.displayMode,
      keyboardType: keyboardType ?? this.keyboardType,
      emulationBackend: emulationBackend ?? this.emulationBackend,
      isEmulationInitialized: isEmulationInitialized ?? this.isEmulationInitialized,
      emulationStatus: emulationStatus ?? this.emulationStatus,
      showBackendSelection: showBackendSelection ?? this.showBackendSelection,
      virtualDeviceAvailability: virtualDeviceAvailability ?? this.virtualDeviceAvailability,
      uinputAvailability: uinputAvailability ?? this.uinputAvailability,
      bluetoothHidAvailability: bluetoothHidAvailability ?? this.bluetoothHidAvailability,
      virtualDeviceStatus: virtualDeviceStatus ?? this.virtualDeviceStatus,
      uinputStatus: uinputStatus ?? this.uinputStatus,
      bluetoothHidStatus: bluetoothHidStatus ?? this.bluetoothHidStatus,
    );
  }

  @override
  List<Object?> get props => [
    isConnected,
    mode,
    showModeSelector,
    shiftEnabled,
    shiftLocked,
    capsLockEnabled,
    ctrlEnabled,
    altEnabled,
    superEnabled,
    fnEnabled,
    displayMode,
    keyboardType,
    emulationBackend,
    isEmulationInitialized,
    emulationStatus,
    showBackendSelection,
    virtualDeviceAvailability,
    uinputAvailability,
    bluetoothHidAvailability,
    virtualDeviceStatus,
    uinputStatus,
    bluetoothHidStatus,
  ];
}
