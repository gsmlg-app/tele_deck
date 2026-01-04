import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_model.dart';
import 'settings_service.dart';
import 'setup_guide_state.dart';

/// MethodChannel for settings-related operations
const _settingsChannel = MethodChannel('app.gsmlg.tele_deck/settings');

/// MethodChannel for IME operations
const _imeChannel = MethodChannel('tele_deck/ime');

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

  /// Update keyboard rotation (0-3 for 0°, 90°, 180°, 270°)
  Future<void> setKeyboardRotation(int value) async {
    state = await _service.updateSetting(
      current: state,
      keyboardRotation: value % 4,
    );
  }
}

/// Provider for app settings state
final appSettingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return SettingsNotifier(service);
});

/// Provider to check if settings have been initialized
final settingsInitializedProvider = StateProvider<bool>((ref) => false);

/// Notifier for settings-related native operations
class SettingsNativeNotifier extends StateNotifier<void> {
  SettingsNativeNotifier() : super(null);

  /// Check if IME is enabled in system settings
  Future<bool> isImeEnabled() async {
    try {
      final result = await _imeChannel.invokeMethod<bool>('isImeEnabled');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Check if IME is currently active
  Future<bool> isImeActive() async {
    try {
      final result = await _imeChannel.invokeMethod<bool>('isImeActive');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Open system IME settings
  Future<void> openImeSettings() async {
    try {
      await _settingsChannel.invokeMethod('openIMESettings');
    } catch (e) {
      // Ignore errors
    }
  }

  /// Open IME picker
  Future<void> openImePicker() async {
    try {
      await _settingsChannel.invokeMethod('openIMEPicker');
    } catch (e) {
      // Ignore errors
    }
  }

  /// Get combined IME status
  Future<({bool enabled, bool active})> getImeStatus() async {
    try {
      final result = await _settingsChannel.invokeMethod<Map>('getIMEStatus');
      if (result != null) {
        return (
          enabled: result['enabled'] as bool? ?? false,
          active: result['selected'] as bool? ?? false,
        );
      }
    } catch (e) {
      // Ignore errors
    }
    return (enabled: false, active: false);
  }
}

/// Provider for settings native operations
final settingsProvider =
    StateNotifierProvider<SettingsNativeNotifier, void>((ref) {
  return SettingsNativeNotifier();
});

/// Provider for setup guide state
final setupGuideProvider = FutureProvider<SetupGuideState>((ref) async {
  final notifier = ref.read(settingsProvider.notifier);
  final status = await notifier.getImeStatus();

  return SetupGuideState(
    currentStep: _calculateStep(status.enabled, status.active),
    imeEnabled: status.enabled,
    imeActive: status.active,
  );
});

int _calculateStep(bool imeEnabled, bool imeActive) {
  if (!imeEnabled) return 1;
  if (!imeActive) return 2;
  return 3;
}
