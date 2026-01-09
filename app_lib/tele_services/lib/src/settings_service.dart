import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:tele_constants/tele_constants.dart';
import 'package:tele_models/tele_models.dart';

/// Service for persisting and loading app settings
class SettingsService {
  static const String _settingsKey = 'teledeck_settings';

  SharedPreferences? _prefs;

  /// Initialize the service (must be called before using)
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Load settings from persistent storage
  Future<AppSettings> loadSettings() async {
    if (_prefs == null) {
      await init();
    }

    final jsonString = _prefs?.getString(_settingsKey);
    if (jsonString == null) {
      return const AppSettings();
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return AppSettings.fromJson(json);
    } catch (e) {
      // Return default settings if parsing fails
      return const AppSettings();
    }
  }

  /// Save settings to persistent storage
  Future<bool> saveSettings(AppSettings settings) async {
    if (_prefs == null) {
      await init();
    }

    final jsonString = jsonEncode(settings.toJson());
    return await _prefs?.setString(_settingsKey, jsonString) ?? false;
  }

  /// Update a single setting value
  Future<AppSettings> updateSetting({
    required AppSettings current,
    bool? showKeyboardOnStartup,
    int? preferredDisplayIndex,
    bool? rememberLastState,
    bool? lastVisibilityState,
    int? keyboardRotation,
    KeyboardType? keyboardType,
    EmulationBackend? emulationBackend,
  }) async {
    final updated = current.copyWith(
      showKeyboardOnStartup: showKeyboardOnStartup,
      preferredDisplayIndex: preferredDisplayIndex,
      rememberLastState: rememberLastState,
      lastVisibilityState: lastVisibilityState,
      keyboardRotation: keyboardRotation,
      keyboardType: keyboardType,
      emulationBackend: emulationBackend,
    );

    await saveSettings(updated);
    return updated;
  }

  /// Save the last visibility state (for remember last state feature)
  Future<void> saveLastVisibilityState(
    AppSettings current,
    bool isVisible,
  ) async {
    if (current.rememberLastState) {
      await saveSettings(current.copyWith(lastVisibilityState: isVisible));
    }
  }
}
