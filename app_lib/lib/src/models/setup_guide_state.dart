import 'package:equatable/equatable.dart';

/// Represents the onboarding/setup guide state in the launcher.
///
/// Steps:
/// 1. Enable TeleDeck in keyboard settings
/// 2. Switch to TeleDeck as active keyboard
/// 3. Setup complete - show settings
class SetupGuideState extends Equatable {
  final int currentStep;
  final bool imeEnabled;
  final bool imeActive;

  const SetupGuideState({
    this.currentStep = 1,
    this.imeEnabled = false,
    this.imeActive = false,
  });

  /// Minimum step number
  static const int minStep = 1;

  /// Maximum step number
  static const int maxStep = 3;

  /// Check if setup is complete (both enabled and active)
  bool get isComplete => imeEnabled && imeActive;

  /// Calculate the current step based on IME status
  int get calculatedStep {
    if (!imeEnabled) return 1;
    if (!imeActive) return 2;
    return 3;
  }

  /// Check if we're on the final step
  bool get isOnFinalStep => currentStep == maxStep;

  /// Get step title
  String get stepTitle {
    switch (currentStep) {
      case 1:
        return 'Enable TeleDeck Keyboard';
      case 2:
        return 'Switch to TeleDeck';
      case 3:
        return 'Setup Complete';
      default:
        return 'Unknown Step';
    }
  }

  /// Get step description
  String get stepDescription {
    switch (currentStep) {
      case 1:
        return "Enable TeleDeck in your device's keyboard settings to use it as an input method.";
      case 2:
        return 'Switch to TeleDeck as your active keyboard to start using it.';
      case 3:
        return 'TeleDeck is now your active keyboard. Configure your preferences below.';
      default:
        return '';
    }
  }

  /// Get action button text
  String get actionButtonText {
    switch (currentStep) {
      case 1:
        return 'Open Keyboard Settings';
      case 2:
        return 'Switch Keyboard';
      case 3:
        return 'Go to Settings';
      default:
        return 'Continue';
    }
  }

  SetupGuideState copyWith({
    int? currentStep,
    bool? imeEnabled,
    bool? imeActive,
  }) {
    return SetupGuideState(
      currentStep: currentStep ?? this.currentStep,
      imeEnabled: imeEnabled ?? this.imeEnabled,
      imeActive: imeActive ?? this.imeActive,
    );
  }

  /// Update state based on current IME status and return new state
  SetupGuideState updateFromImeStatus({
    required bool imeEnabled,
    required bool imeActive,
  }) {
    return SetupGuideState(
      currentStep: _calculateStep(imeEnabled, imeActive),
      imeEnabled: imeEnabled,
      imeActive: imeActive,
    );
  }

  static int _calculateStep(bool imeEnabled, bool imeActive) {
    if (!imeEnabled) return 1;
    if (!imeActive) return 2;
    return 3;
  }

  @override
  List<Object?> get props => [currentStep, imeEnabled, imeActive];

  @override
  String toString() =>
      'SetupGuideState(step: $currentStep, enabled: $imeEnabled, active: $imeActive)';
}
