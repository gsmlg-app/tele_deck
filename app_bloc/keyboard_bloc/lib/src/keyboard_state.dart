import 'package:equatable/equatable.dart';

import 'keyboard_event.dart';

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
      ];
}
