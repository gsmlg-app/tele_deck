import 'package:bloc/bloc.dart';
import 'package:tele_services/tele_services.dart';

import 'setup_event.dart';
import 'setup_state.dart';

/// BLoC for IME setup/onboarding flow
class SetupBloc extends Bloc<SetupEvent, SetupState> {
  final ImeChannelService _imeService;

  SetupBloc({required ImeChannelService imeService})
    : _imeService = imeService,
      super(SetupState.initial()) {
    on<SetupCheckRequested>(_onCheckRequested);
    on<SetupOpenImeSettings>(_onOpenImeSettings);
    on<SetupOpenImePicker>(_onOpenImePicker);
    on<SetupImeStatusChanged>(_onImeStatusChanged);
    on<SetupNavigateToSettings>(_onNavigateToSettings);
  }

  Future<void> _onCheckRequested(
    SetupCheckRequested event,
    Emitter<SetupState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      final imeEnabled = await _imeService.isImeEnabled();
      final imeActive = await _imeService.isImeActive();

      final newGuideState = state.guideState.updateFromImeStatus(
        imeEnabled: imeEnabled,
        imeActive: imeActive,
      );

      emit(state.copyWith(guideState: newGuideState, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _onOpenImeSettings(
    SetupOpenImeSettings event,
    Emitter<SetupState> emit,
  ) async {
    await _imeService.openImeSettings();
  }

  Future<void> _onOpenImePicker(
    SetupOpenImePicker event,
    Emitter<SetupState> emit,
  ) async {
    await _imeService.openImePicker();
  }

  void _onImeStatusChanged(
    SetupImeStatusChanged event,
    Emitter<SetupState> emit,
  ) {
    final newGuideState = state.guideState.updateFromImeStatus(
      imeEnabled: event.imeEnabled,
      imeActive: event.imeActive,
    );

    emit(state.copyWith(guideState: newGuideState));
  }

  void _onNavigateToSettings(
    SetupNavigateToSettings event,
    Emitter<SetupState> emit,
  ) {
    emit(state.copyWith(shouldNavigateToSettings: true));
  }
}
