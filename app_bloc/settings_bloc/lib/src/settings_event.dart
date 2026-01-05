import 'package:equatable/equatable.dart';

/// Base class for settings events
sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Load settings from storage
final class SettingsLoaded extends SettingsEvent {
  const SettingsLoaded();
}

/// Keyboard rotation changed
final class SettingsKeyboardRotationChanged extends SettingsEvent {
  final int rotation;

  const SettingsKeyboardRotationChanged(this.rotation);

  @override
  List<Object?> get props => [rotation];
}

/// Show keyboard on startup changed
final class SettingsShowKeyboardOnStartupChanged extends SettingsEvent {
  final bool value;

  const SettingsShowKeyboardOnStartupChanged(this.value);

  @override
  List<Object?> get props => [value];
}

/// Remember last state changed
final class SettingsRememberLastStateChanged extends SettingsEvent {
  final bool value;

  const SettingsRememberLastStateChanged(this.value);

  @override
  List<Object?> get props => [value];
}

/// Preferred display changed
final class SettingsPreferredDisplayChanged extends SettingsEvent {
  final int displayIndex;

  const SettingsPreferredDisplayChanged(this.displayIndex);

  @override
  List<Object?> get props => [displayIndex];
}

/// Save last visibility state
final class SettingsLastVisibilityChanged extends SettingsEvent {
  final bool isVisible;

  const SettingsLastVisibilityChanged(this.isVisible);

  @override
  List<Object?> get props => [isVisible];
}
