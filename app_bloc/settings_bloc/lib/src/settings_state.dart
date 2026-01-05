import 'package:equatable/equatable.dart';
import 'package:tele_models/tele_models.dart';

/// Settings load status
enum SettingsStatus { initial, loading, success, failure }

/// Settings state
class SettingsState extends Equatable {
  final SettingsStatus status;
  final AppSettings settings;
  final String? errorMessage;

  const SettingsState({
    this.status = SettingsStatus.initial,
    this.settings = const AppSettings(),
    this.errorMessage,
  });

  /// Initial state
  factory SettingsState.initial() => const SettingsState();

  /// Convenience getters
  int get keyboardRotation => settings.keyboardRotation;
  bool get showKeyboardOnStartup => settings.showKeyboardOnStartup;
  bool get rememberLastState => settings.rememberLastState;
  int get preferredDisplayIndex => settings.preferredDisplayIndex;
  bool get initialKeyboardVisible => settings.initialKeyboardVisible;

  SettingsState copyWith({
    SettingsStatus? status,
    AppSettings? settings,
    String? errorMessage,
  }) {
    return SettingsState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, settings, errorMessage];
}
