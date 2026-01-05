# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TeleDeck is a System IME (Input Method Editor) for Android that supports dual-screen devices (Ayaneo Pocket DS). It provides a custom keyboard that renders on the secondary display while sending input to apps on the primary screen.

## Monorepo Structure

This project uses **Melos** for workspace management with a multi-package architecture:

```
tele_deck/
├── lib/                              # Main app entry points only
│   ├── main.dart                     # Launcher app (settings/setup)
│   └── main_ime.dart                 # IME keyboard entry point
├── app_lib/                          # Core library packages
│   ├── tele_theme/                   # Cyberpunk theme (TeleDeckColors, TeleDeckTheme)
│   ├── tele_models/                  # Data models (AppSettings, DisplayState, SetupGuideState)
│   ├── tele_services/                # Platform services (SettingsService, ImeChannelService)
│   ├── tele_logging/                 # Crash logging (CrashLogEntry, CrashLogService)
│   └── tele_constants/               # Constants (IPC, ImeMethod, DisplayMode, KeyboardLayout)
├── app_bloc/                         # BLoC state management
│   ├── keyboard_bloc/                # Keyboard state (modifiers, mode, connection)
│   ├── settings_bloc/                # Settings persistence
│   └── setup_bloc/                   # IME onboarding flow
├── app_widget/                       # UI components
│   ├── keyboard_widgets/             # Keyboard view with all layouts
│   ├── settings_widgets/             # Settings and setup guide UI
│   └── common_widgets/               # Shared widgets (crash log viewer)
├── android/                          # Native Android code
│   └── app/src/main/kotlin/.../      # TeleDeckIMEService, crash handler
└── melos.yaml                        # Workspace configuration
```

## Build Commands

```bash
# Melos workspace commands
melos bootstrap          # Install all dependencies and link packages
melos run analyze        # Run flutter analyze on all packages
melos run test           # Run tests for all packages
melos run format         # Format all packages

# Flutter commands
flutter run              # Run on connected device
flutter build apk        # Build release APK

# Individual package development
cd app_bloc/keyboard_bloc && flutter test
```

## Architecture

### System IME Architecture

TeleDeck runs as a System Input Method Editor (IME) service:

1. **TeleDeckIMEService** (`android/.../TeleDeckIMEService.kt`): Native InputMethodService that hosts Flutter
2. **IME Entry Point** (`lib/main_ime.dart`): Flutter keyboard UI, entry point `@pragma('vm:entry-point') void imeMain()`
3. **Launcher App** (`lib/main.dart`): Setup guide and settings, run as a normal activity

### MethodChannel Communication

- `tele_deck/ime` - IME keyboard operations (commitText, backspace, enter, tab, etc.)
- `app.gsmlg.tele_deck/settings` - Settings operations and IME status checks
- `app.gsmlg.tele_deck/crash_logs` - Crash log operations

### State Management (BLoC)

Uses `flutter_bloc` for state management:

**KeyboardBloc** (`app_bloc/keyboard_bloc`):
- Events: `KeyboardKeyPressed`, `KeyboardBackspacePressed`, `KeyboardEnterPressed`, `KeyboardShiftToggled`, `KeyboardCapsLockToggled`, `KeyboardModeChanged`, etc.
- State: `isConnected`, `mode`, `shiftEnabled`, `shiftLocked`, `capsLockEnabled`, `ctrlEnabled`, `altEnabled`, `fnEnabled`, `displayMode`

**SettingsBloc** (`app_bloc/settings_bloc`):
- Events: `SettingsLoaded`, `SettingsKeyboardRotationChanged`, `SettingsPreferredDisplayChanged`
- State: `SettingsState` with `status` (initial/loading/success/failure), `settings` (AppSettings)

**SetupBloc** (`app_bloc/setup_bloc`):
- Events: `SetupCheckRequested`, `SetupOpenImeSettings`, `SetupImeStatusChanged`
- State: `SetupState` with `guideState` (currentStep, imeEnabled, imeActive, isComplete)

### Key Services

**ImeChannelService** (`app_lib/tele_services`):
- Handles all MethodChannel communication with native IME
- Methods: `commitText()`, `backspace()`, `enter()`, `tab()`, `delete()`, `sendKeyEvent()`, `moveCursor()`
- IME status: `isImeEnabled()`, `isImeActive()`, `openImeSettings()`

**SettingsService** (`app_lib/tele_services`):
- Persists settings via `shared_preferences`
- Manages keyboard rotation, display preferences

**CrashLogService** (`app_lib/tele_logging`):
- File-based crash logs with 7-day retention
- Accessed via MethodChannel from native crash handler

## Android Configuration

- `minSdk = 26` required for InputMethodService
- `TeleDeckIMEService` registered in AndroidManifest as input method
- `CrashHandler` captures Flutter engine crashes and logs them

## Development Workflow

1. Make changes to packages in `app_lib/`, `app_bloc/`, or `app_widget/`
2. Run `melos bootstrap` if dependencies changed
3. Run `melos run analyze` to check for issues
4. Test with `flutter run` or `flutter build apk`

## BLoC Patterns

```dart
// Reading state in widgets
BlocBuilder<KeyboardBloc, KeyboardState>(
  builder: (context, state) {
    return KeyboardKey(
      shiftActive: state.isShiftActive,
    );
  },
)

// Dispatching events
context.read<KeyboardBloc>().add(KeyboardKeyPressed('a'));

// Listening for state changes
BlocListener<SettingsBloc, SettingsState>(
  listener: (context, state) {
    if (state.status == SettingsStatus.success) {
      // Handle success
    }
  },
)
```

## Active Technologies

- Dart 3.8+ / Kotlin (Android) + Flutter 3.x
- flutter_bloc v8.x for state management
- Melos for monorepo management
- shared_preferences for settings persistence
- File-based crash logs (7-day retention)
