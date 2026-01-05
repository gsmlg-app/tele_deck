/// TeleDeck Core Library
///
/// This library provides shared models, services, theme, and utilities
/// for the TeleDeck IME application.
library tele_lib;

// Theme
export 'src/theme/tele_deck_colors.dart';
export 'src/theme/tele_deck_theme.dart';

// Models
export 'src/models/display_state.dart';
export 'src/models/app_settings.dart';
export 'src/models/setup_guide_state.dart';

// Services
export 'src/services/settings_service.dart';
export 'src/services/ime_channel_service.dart';

// Logging
export 'src/logging/crash_log_entry.dart';
export 'src/logging/crash_log_service.dart';

// Constants
export 'src/constants/keyboard_layout.dart';
export 'src/constants/ime_constants.dart';
