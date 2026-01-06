import 'package:equatable/equatable.dart';

/// Application settings configuration
class AppSettings extends Equatable {
  /// Whether to show keyboard on app startup
  final bool showKeyboardOnStartup;

  /// Preferred display index for keyboard (0 = primary, 1 = secondary)
  final int preferredDisplayIndex;

  /// Remember last visibility state between app launches
  final bool rememberLastState;

  /// Last known visibility state (used when rememberLastState is true)
  final bool lastVisibilityState;

  /// Keyboard rotation in quarter turns (0=0deg, 1=90deg, 2=180deg, 3=270deg)
  final int keyboardRotation;

  const AppSettings({
    this.showKeyboardOnStartup = false,
    this.preferredDisplayIndex = 1,
    this.rememberLastState = false,
    this.lastVisibilityState = false,
    this.keyboardRotation = 0,
  });

  /// Create settings from JSON map
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      showKeyboardOnStartup: json['showKeyboardOnStartup'] as bool? ?? false,
      preferredDisplayIndex: json['preferredDisplayIndex'] as int? ?? 1,
      rememberLastState: json['rememberLastState'] as bool? ?? false,
      lastVisibilityState: json['lastVisibilityState'] as bool? ?? false,
      keyboardRotation: json['keyboardRotation'] as int? ?? 0,
    );
  }

  /// Convert settings to JSON map
  Map<String, dynamic> toJson() {
    return {
      'showKeyboardOnStartup': showKeyboardOnStartup,
      'preferredDisplayIndex': preferredDisplayIndex,
      'rememberLastState': rememberLastState,
      'lastVisibilityState': lastVisibilityState,
      'keyboardRotation': keyboardRotation,
    };
  }

  /// Create a copy with updated values
  AppSettings copyWith({
    bool? showKeyboardOnStartup,
    int? preferredDisplayIndex,
    bool? rememberLastState,
    bool? lastVisibilityState,
    int? keyboardRotation,
  }) {
    return AppSettings(
      showKeyboardOnStartup:
          showKeyboardOnStartup ?? this.showKeyboardOnStartup,
      preferredDisplayIndex:
          preferredDisplayIndex ?? this.preferredDisplayIndex,
      rememberLastState: rememberLastState ?? this.rememberLastState,
      lastVisibilityState: lastVisibilityState ?? this.lastVisibilityState,
      keyboardRotation: keyboardRotation ?? this.keyboardRotation,
    );
  }

  /// Get initial keyboard visibility based on settings
  bool get initialKeyboardVisible {
    if (rememberLastState) {
      return lastVisibilityState;
    }
    return showKeyboardOnStartup;
  }

  @override
  List<Object?> get props => [
    showKeyboardOnStartup,
    preferredDisplayIndex,
    rememberLastState,
    lastVisibilityState,
    keyboardRotation,
  ];
}
