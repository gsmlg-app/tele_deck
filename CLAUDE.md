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
├── third_party/                      # Third-party packages (forked/modified)
│   ├── form_bloc/                    # Form state management with BLoC
│   └── flutter_form_bloc/            # Flutter widgets for form_bloc
├── android/                          # Native Android code
│   └── app/src/main/kotlin/.../      # TeleDeckIMEService, crash handler
└── melos.yaml                        # Workspace configuration
```

## Package Dependencies

```
tele_deck (root)
├── tele_theme ────────────────────┐
├── tele_models ───────────────────┤
├── tele_services ─────────────────┤── app_lib (no internal deps)
├── tele_logging ──────────────────┤
└── tele_constants ────────────────┘
        │
        ▼
├── keyboard_bloc ─── depends on: tele_services, tele_models, tele_constants
├── settings_bloc ─── depends on: tele_services, tele_models
└── setup_bloc ────── depends on: tele_services, tele_models
        │
        ▼
├── keyboard_widgets ─ depends on: keyboard_bloc, tele_theme, tele_constants
├── settings_widgets ─ depends on: settings_bloc, setup_bloc, tele_theme
└── common_widgets ─── depends on: tele_logging, tele_theme
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

### Keyboard Layouts

The keyboard supports multiple layouts defined in `KeyboardMode`:

| Mode | Description | Rows |
|------|-------------|------|
| `standard` | Full QWERTY with function row | 6 rows (Fn, Numbers, QWERTY x3, Modifiers) |
| `numpad` | Numeric keypad | 4x4 grid with operators |
| `emoji` | Emoji picker | Category tabs + emoji grid |

### Keyboard State (KeyboardBloc)

```dart
// State fields
isConnected: bool           // IME connection status
mode: KeyboardMode          // Current layout mode
shiftEnabled: bool          // Shift key pressed
shiftLocked: bool           // Shift lock (double-tap)
capsLockEnabled: bool       // Caps lock on
ctrlEnabled: bool           // Ctrl modifier
altEnabled: bool            // Alt modifier
superEnabled: bool          // Super/Windows key
fnEnabled: bool             // Function key modifier
displayMode: String         // Display mode from native
showModeSelector: bool      // Mode selector overlay visible
```

### MethodChannel Communication

- `tele_deck/ime` - IME keyboard operations
  - `commitText(String)` - Insert text at cursor
  - `backspace()` - Delete character before cursor
  - `delete()` - Delete character after cursor
  - `enter()` - Insert newline / submit
  - `tab()` - Insert tab character
  - `sendKeyEvent(keyCode, metaState)` - Send raw key event
  - `moveCursor(offset)` - Move cursor position

- `app.gsmlg.tele_deck/settings` - Settings and IME status
  - `isImeEnabled()` - Check if TeleDeck IME is enabled
  - `isImeActive()` - Check if TeleDeck is the active IME
  - `openImeSettings()` - Open system IME settings

- `app.gsmlg.tele_deck/crash_logs` - Crash logging
  - `getCrashLogs()` - Retrieve stored crash logs
  - `clearCrashLogs()` - Delete all crash logs

### State Management (BLoC)

Uses `flutter_bloc` for state management:

**KeyboardBloc** (`app_bloc/keyboard_bloc`):
- Events: `KeyboardKeyPressed`, `KeyboardBackspacePressed`, `KeyboardEnterPressed`, `KeyboardShiftToggled`, `KeyboardShiftLocked`, `KeyboardCapsLockToggled`, `KeyboardCtrlToggled`, `KeyboardAltToggled`, `KeyboardFnToggled`, `KeyboardModeChanged`, `KeyboardConnectionChanged`
- Handles all keyboard input and modifier state

**SettingsBloc** (`app_bloc/settings_bloc`):
- Events: `SettingsLoaded`, `SettingsKeyboardRotationChanged`, `SettingsPreferredDisplayChanged`
- State: `SettingsState` with `status` enum (initial/loading/success/failure)

**SetupBloc** (`app_bloc/setup_bloc`):
- Events: `SetupCheckRequested`, `SetupOpenImeSettings`, `SetupImeStatusChanged`
- Manages the 3-step IME setup flow

### Key Services

**ImeChannelService** (`app_lib/tele_services`):
- Singleton service for IME MethodChannel communication
- Callbacks: `onConnectionStatusChanged`, `onDisplayModeChanged`
- Methods mirror native IME capabilities

**SettingsService** (`app_lib/tele_services`):
- Persists `AppSettings` via `shared_preferences`
- Settings: `keyboardRotation`, `showKeyboardOnStartup`, `preferredDisplayIndex`

**CrashLogService** (`app_lib/tele_logging`):
- File-based crash logs in app documents directory
- Automatic 7-day retention cleanup
- JSON format with timestamp, error type, message, stack trace

## Android Native Code

### TeleDeckIMEService.kt

The main IME service that:
- Extends `InputMethodService`
- Hosts Flutter via `FlutterEngine` with entry point `imeMain`
- Handles display detection for dual-screen devices
- Communicates with Flutter via MethodChannel

### VirtualKeyboardPresentation.kt

Renders the keyboard on secondary displays using Android's Presentation API:
- Creates a **local FlutterEngine** for the Presentation's display context (not shared)
- Uses `FLAG_NOT_FOCUSABLE | FLAG_NOT_TOUCH_MODAL` to prevent stealing focus from primary display
- Does NOT use `TYPE_INPUT_METHOD` (only valid for primary display)
- On Android 12+, uses `createWindowContext(TYPE_PRESENTATION)` for proper context

**Why local FlutterEngine**: FlutterEngine rendering is tied to its creation context. A shared engine created in IME service context cannot render properly on a different display's context.

### Dual-Display Architecture

The IME operates in two modes based on available displays:

| Mode | Trigger | Primary Screen | Secondary Screen |
|------|---------|----------------|------------------|
| `secondary` | Secondary display detected | 0-height empty view | Full keyboard via Presentation (local engine) |
| `primary_fallback` | No secondary display | 50% height keyboard | N/A |

**Key state flags** in `TeleDeckIMEService`:
- `isInPrimaryFallbackMode` - Currently rendering on primary screen
- `isPrimaryViewAttached` - FlutterView attached to engine (for view reuse)
- `isDartEntrypointExecuted` - Dart code started (deferred until view ready)
- `secondaryDisplay` - Reference to detected secondary display (null if none)

**FlutterEngine lifecycle**:
- Primary mode: Engine created in `initFlutterEngine()`, Dart entrypoint executed when FlutterView attaches
- Secondary mode: Local engine created in `VirtualKeyboardPresentation`, Dart entrypoint executed on view attach
- MethodChannel set up via `onEngineReady` callback after Presentation's engine is ready

**Display mode switching**:
- `handleDisplayAdded()` - Cleans up primary view, switches to Presentation
- `handleDisplayRemoved()` - Dismisses Presentation, switches to primary fallback
- Events are debounced (500ms) to handle rapid connect/disconnect

**Focus management** (critical for secondary display IME):
- `FLAG_NOT_FOCUSABLE` - Key events go to primary display app, not keyboard
- `FLAG_NOT_TOUCH_MODAL` - Touch events outside keyboard pass through
- Without these flags, touching keyboard steals focus → `onFinishInputView` → keyboard disappears

### CrashHandler.kt

- Catches uncaught exceptions in native code
- Logs crashes to file storage
- Shows notification to view crash logs

## Android Configuration

- `minSdk = 26` required for InputMethodService features
- `TeleDeckIMEService` registered in AndroidManifest as input method
- `CrashHandler` initialized on app start

## Development Workflow

1. Make changes to packages in `app_lib/`, `app_bloc/`, or `app_widget/`
2. Run `melos bootstrap` if dependencies changed
3. Run `melos run analyze` to check for issues
4. Test with `flutter run` or `flutter build apk`

## Debugging

```bash
# Watch IME and Presentation logs
adb logcat -s TeleDeckIME:D VirtualKeyboardPresentation:D

# Watch all TeleDeck logs
adb logcat | grep -E "(TeleDeck|tele_deck)"

# Check if secondary display is detected
adb shell dumpsys display | grep -A5 "Display Devices"
```

**Common issues**:
- "Black bar" on primary, no keyboard on secondary = Check Presentation logs, verify `FLAG_NOT_FOCUSABLE` set
- Keyboard disappears when touched = Missing focus flags, keyboard stealing focus from primary app
- No input from keyboard = MethodChannel not set up on local engine (check `onEngineReady` callback)
- Blank keyboard on secondary = Dart entrypoint not executed or lifecycle not resumed
- Keyboard not appearing after hide = FlutterView detached prematurely (check `isPrimaryViewAttached`)
- Crash on display disconnect = Race condition (debounce should handle this)

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

// Combined builder + listener
BlocConsumer<SetupBloc, SetupState>(
  listener: (context, state) {
    if (state.shouldNavigateToSettings) {
      // Navigate
    }
  },
  builder: (context, state) {
    return SetupGuideView(state: state.guideState);
  },
)
```

## Theme Constants

```dart
// Colors (from tele_theme/TeleDeckColors)
darkBackground     = 0xFF0D0D0D   // Main background
secondaryBackground = 0xFF1A1A2E  // Card/panel background
neonCyan           = 0xFF00F5FF   // Primary accent
neonMagenta        = 0xFFFF00FF   // Secondary accent
neonPurple         = 0xFF9D00FF   // Tertiary accent
textPrimary        = 0xFFE0E0E0   // Primary text
textSecondary      = 0xFFA0A0A0   // Secondary text
```

## Device-Specific Documentation

For detailed implementation notes on specific hardware devices, see:

- **Ayaneo Pocket DS**: [docs/devices/ayaneo-pocket-ds.md](docs/devices/ayaneo-pocket-ds.md)
  - Dual-display architecture (Display 0: 1920x1080, Display 2: 1024x768)
  - Bidirectional keyboard placement (keyboard on opposite display from input)
  - Gamewindow overlay blocking workarounds
  - Input display detection using IME window context
  - Debugging commands for dual-display issues

## Active Technologies

- Dart 3.8+ / Kotlin (Android) + Flutter 3.x
- flutter_bloc v9.x for state management
- form_bloc + flutter_form_bloc for form handling
- Melos for monorepo management
- shared_preferences for settings persistence
- File-based crash logs (7-day retention)
- google_fonts for typography (JetBrains Mono, Roboto Mono)
