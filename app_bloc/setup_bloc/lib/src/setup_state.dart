import 'package:equatable/equatable.dart';
import 'package:tele_models/tele_models.dart';

/// Setup state
class SetupState extends Equatable {
  final SetupGuideState guideState;
  final bool isLoading;
  final bool shouldNavigateToSettings;

  const SetupState({
    this.guideState = const SetupGuideState(),
    this.isLoading = false,
    this.shouldNavigateToSettings = false,
  });

  /// Initial state
  factory SetupState.initial() => const SetupState();

  /// Convenience getters
  int get currentStep => guideState.currentStep;
  bool get imeEnabled => guideState.imeEnabled;
  bool get imeActive => guideState.imeActive;
  bool get isComplete => guideState.isComplete;
  String get stepTitle => guideState.stepTitle;
  String get stepDescription => guideState.stepDescription;
  String get actionButtonText => guideState.actionButtonText;

  SetupState copyWith({
    SetupGuideState? guideState,
    bool? isLoading,
    bool? shouldNavigateToSettings,
  }) {
    return SetupState(
      guideState: guideState ?? this.guideState,
      isLoading: isLoading ?? this.isLoading,
      shouldNavigateToSettings:
          shouldNavigateToSettings ?? this.shouldNavigateToSettings,
    );
  }

  @override
  List<Object?> get props => [guideState, isLoading, shouldNavigateToSettings];
}
