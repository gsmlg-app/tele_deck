import 'package:equatable/equatable.dart';

/// Base class for keyboard events
sealed class KeyboardEvent extends Equatable {
  const KeyboardEvent();

  @override
  List<Object?> get props => [];
}

/// Key pressed event
final class KeyboardKeyPressed extends KeyboardEvent {
  final String key;

  const KeyboardKeyPressed(this.key);

  @override
  List<Object?> get props => [key];
}

/// Backspace pressed
final class KeyboardBackspacePressed extends KeyboardEvent {
  const KeyboardBackspacePressed();
}

/// Enter pressed
final class KeyboardEnterPressed extends KeyboardEvent {
  const KeyboardEnterPressed();
}

/// Tab pressed
final class KeyboardTabPressed extends KeyboardEvent {
  const KeyboardTabPressed();
}

/// Escape pressed
final class KeyboardEscapePressed extends KeyboardEvent {
  const KeyboardEscapePressed();
}

/// Delete pressed
final class KeyboardDeletePressed extends KeyboardEvent {
  const KeyboardDeletePressed();
}

/// Function key pressed (F1-F12)
final class KeyboardFunctionKeyPressed extends KeyboardEvent {
  final int number;

  const KeyboardFunctionKeyPressed(this.number);

  @override
  List<Object?> get props => [number];
}

/// Arrow direction
enum ArrowDirection { up, down, left, right }

/// Arrow key pressed
final class KeyboardArrowKeyPressed extends KeyboardEvent {
  final ArrowDirection direction;

  const KeyboardArrowKeyPressed(this.direction);

  @override
  List<Object?> get props => [direction];
}

/// Shift toggled
final class KeyboardShiftToggled extends KeyboardEvent {
  final bool enabled;

  const KeyboardShiftToggled(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// Shift locked (long press)
final class KeyboardShiftLocked extends KeyboardEvent {
  final bool locked;

  const KeyboardShiftLocked(this.locked);

  @override
  List<Object?> get props => [locked];
}

/// Caps lock toggled
final class KeyboardCapsLockToggled extends KeyboardEvent {
  final bool enabled;

  const KeyboardCapsLockToggled(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// Ctrl toggled
final class KeyboardCtrlToggled extends KeyboardEvent {
  final bool enabled;

  const KeyboardCtrlToggled(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// Alt toggled
final class KeyboardAltToggled extends KeyboardEvent {
  final bool enabled;

  const KeyboardAltToggled(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// Super toggled
final class KeyboardSuperToggled extends KeyboardEvent {
  final bool enabled;

  const KeyboardSuperToggled(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// Fn toggled
final class KeyboardFnToggled extends KeyboardEvent {
  final bool enabled;

  const KeyboardFnToggled(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// Keyboard mode
enum KeyboardMode { standard, numpad, emoji }

/// Mode changed
final class KeyboardModeChanged extends KeyboardEvent {
  final KeyboardMode mode;

  const KeyboardModeChanged(this.mode);

  @override
  List<Object?> get props => [mode];
}

/// Mode selector visibility changed
final class KeyboardModeSelectorChanged extends KeyboardEvent {
  final bool visible;

  const KeyboardModeSelectorChanged(this.visible);

  @override
  List<Object?> get props => [visible];
}

/// Connection status changed
final class KeyboardConnectionChanged extends KeyboardEvent {
  final bool isConnected;

  const KeyboardConnectionChanged(this.isConnected);

  @override
  List<Object?> get props => [isConnected];
}

/// Display mode changed
final class KeyboardDisplayModeChanged extends KeyboardEvent {
  final String displayMode;

  const KeyboardDisplayModeChanged(this.displayMode);

  @override
  List<Object?> get props => [displayMode];
}
