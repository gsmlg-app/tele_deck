import 'package:bloc/bloc.dart';
import 'package:tele_lib/tele_lib.dart';

import 'settings_event.dart';
import 'settings_state.dart';

/// BLoC for settings state management
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsService _settingsService;

  SettingsBloc({
    required SettingsService settingsService,
  })  : _settingsService = settingsService,
        super(SettingsState.initial()) {
    on<SettingsLoaded>(_onLoaded);
    on<SettingsKeyboardRotationChanged>(_onKeyboardRotationChanged);
    on<SettingsShowKeyboardOnStartupChanged>(_onShowKeyboardOnStartupChanged);
    on<SettingsRememberLastStateChanged>(_onRememberLastStateChanged);
    on<SettingsPreferredDisplayChanged>(_onPreferredDisplayChanged);
    on<SettingsLastVisibilityChanged>(_onLastVisibilityChanged);
  }

  Future<void> _onLoaded(
    SettingsLoaded event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(status: SettingsStatus.loading));

    try {
      final settings = await _settingsService.loadSettings();
      emit(state.copyWith(
        status: SettingsStatus.success,
        settings: settings,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SettingsStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onKeyboardRotationChanged(
    SettingsKeyboardRotationChanged event,
    Emitter<SettingsState> emit,
  ) async {
    final updated = await _settingsService.updateSetting(
      current: state.settings,
      keyboardRotation: event.rotation,
    );
    emit(state.copyWith(settings: updated));
  }

  Future<void> _onShowKeyboardOnStartupChanged(
    SettingsShowKeyboardOnStartupChanged event,
    Emitter<SettingsState> emit,
  ) async {
    final updated = await _settingsService.updateSetting(
      current: state.settings,
      showKeyboardOnStartup: event.value,
    );
    emit(state.copyWith(settings: updated));
  }

  Future<void> _onRememberLastStateChanged(
    SettingsRememberLastStateChanged event,
    Emitter<SettingsState> emit,
  ) async {
    final updated = await _settingsService.updateSetting(
      current: state.settings,
      rememberLastState: event.value,
    );
    emit(state.copyWith(settings: updated));
  }

  Future<void> _onPreferredDisplayChanged(
    SettingsPreferredDisplayChanged event,
    Emitter<SettingsState> emit,
  ) async {
    final updated = await _settingsService.updateSetting(
      current: state.settings,
      preferredDisplayIndex: event.displayIndex,
    );
    emit(state.copyWith(settings: updated));
  }

  Future<void> _onLastVisibilityChanged(
    SettingsLastVisibilityChanged event,
    Emitter<SettingsState> emit,
  ) async {
    await _settingsService.saveLastVisibilityState(
      state.settings,
      event.isVisible,
    );
  }
}
