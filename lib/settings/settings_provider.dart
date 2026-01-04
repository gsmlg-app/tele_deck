import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_model.dart';
import 'settings_service.dart';

/// Provider for the settings service singleton
final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

/// State notifier for app settings
class SettingsNotifier extends StateNotifier<AppSettings> {
  final SettingsService _service;

  SettingsNotifier(this._service) : super(const AppSettings());

  /// Initialize settings from persistent storage
  Future<void> loadSettings() async {
    state = await _service.loadSettings();
  }

  /// Update show keyboard on startup setting
  Future<void> setShowKeyboardOnStartup(bool value) async {
    state = await _service.updateSetting(
      current: state,
      showKeyboardOnStartup: value,
    );
  }

  /// Update preferred display index
  Future<void> setPreferredDisplayIndex(int value) async {
    state = await _service.updateSetting(
      current: state,
      preferredDisplayIndex: value,
    );
  }

  /// Update remember last state setting
  Future<void> setRememberLastState(bool value) async {
    state = await _service.updateSetting(
      current: state,
      rememberLastState: value,
    );
  }

  /// Save the current visibility state (for remember feature)
  Future<void> saveVisibilityState(bool isVisible) async {
    await _service.saveLastVisibilityState(state, isVisible);
    if (state.rememberLastState) {
      state = state.copyWith(lastVisibilityState: isVisible);
    }
  }
}

/// Provider for app settings state
final appSettingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return SettingsNotifier(service);
});

/// Provider for keyboard visibility state
/// This is the main toggle state that controls whether keyboard is shown
final keyboardVisibleProvider = StateProvider<bool>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return settings.initialKeyboardVisible;
});

/// Provider to check if settings have been initialized
final settingsInitializedProvider = StateProvider<bool>((ref) => false);
