import 'package:equatable/equatable.dart';

/// Base class for setup events
sealed class SetupEvent extends Equatable {
  const SetupEvent();

  @override
  List<Object?> get props => [];
}

/// Check IME status
final class SetupCheckRequested extends SetupEvent {
  const SetupCheckRequested();
}

/// Open IME settings
final class SetupOpenImeSettings extends SetupEvent {
  const SetupOpenImeSettings();
}

/// Open IME picker
final class SetupOpenImePicker extends SetupEvent {
  const SetupOpenImePicker();
}

/// IME status changed (from native callback)
final class SetupImeStatusChanged extends SetupEvent {
  final bool imeEnabled;
  final bool imeActive;

  const SetupImeStatusChanged({
    required this.imeEnabled,
    required this.imeActive,
  });

  @override
  List<Object?> get props => [imeEnabled, imeActive];
}

/// Navigate to settings (after setup complete)
final class SetupNavigateToSettings extends SetupEvent {
  const SetupNavigateToSettings();
}
