# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TeleDeck is a dual-screen Android application for handheld devices (Ayaneo Pocket DS). The secondary screen acts as a custom keyboard that sends keystrokes to the main screen via IPC.

## Build Commands

```bash
flutter pub get          # Install dependencies
flutter analyze          # Run static analysis
flutter test             # Run all tests
flutter test test/widget_test.dart  # Run single test
flutter run              # Run on connected device
flutter build apk        # Build release APK
```

## Architecture

### Dual-Screen Communication

The app runs two separate Flutter engines (isolates) - one per screen. They communicate via `dart:ui` `IsolateNameServer` with `ReceivePort`/`SendPort` for low-latency IPC.

- **Main Screen** (`lib/main.dart`): Registers a `ReceivePort` with `IsolateNameServer` using port name `teledeck_ipc_port`
- **Keyboard Screen** (`lib/main_keyboard.dart`): Looks up the port via `IsolateNameServer.lookupPortByName()` and sends events

### Key Components

- `lib/shared/protocol.dart`: Sealed class `KeyboardEvent` with subtypes (`KeyDown`, `Backspace`, `Enter`, `Space`, `Clear`, `Shift`) - serialized as Maps for IPC
- `lib/shared/constants.dart`: IPC port name, theme colors (`TeleDeckColors`), QWERTY layout config
- `lib/main_screen/display_controller.dart`: Riverpod providers for input state, IPC listening
- `lib/keyboard_screen/keyboard_service.dart`: IPC sender service

### Settings System

- `lib/settings/settings_model.dart`: `AppSettings` data class with serialization
- `lib/settings/settings_service.dart`: Persistence via `shared_preferences`
- `lib/settings/settings_provider.dart`: Riverpod providers (`appSettingsProvider`, `keyboardVisibleProvider`)
- `lib/settings/views/settings_view.dart`: Settings UI screen

### Physical Button Integration

Android BroadcastReceiver (`ToggleKeyboardReceiver.kt`) handles external intents:
- `app.gsmlg.tele_deck.TOGGLE_KEYBOARD` - Toggle visibility
- `app.gsmlg.tele_deck.SHOW_KEYBOARD` - Show keyboard
- `app.gsmlg.tele_deck.HIDE_KEYBOARD` - Hide keyboard

Communication flow: BroadcastReceiver → MethodChannel → Flutter provider state

### Multi-Display Management

Uses `presentation_displays` package:
- `DisplayManager.getDisplays()` to detect secondary displays
- `showSecondaryDisplay(displayId, routerName)` to launch keyboard on secondary screen
- `hideSecondaryDisplay(displayId)` to hide keyboard
- `SecondaryDisplay` widget wraps keyboard UI to receive data from main screen

### State Management

Uses `flutter_riverpod` v2:
- `inputTextProvider`: StateNotifier for the text buffer on main screen
- `displayControllerProvider`: Manages IPC receive port lifecycle
- `keyboardServiceProvider`: Keyboard IPC sender
- `appSettingsProvider`: App settings with persistence
- `keyboardVisibleProvider`: Current keyboard visibility state
- `shiftEnabledProvider`, `capsLockProvider`: Keyboard modifier state

## Android Configuration

- `minSdk = 26` required for multi-display support
- `resizeableActivity="true"` in AndroidManifest for foldable devices
- `windowSoftInputMode="adjustNothing"` to prevent system keyboard
- `ToggleKeyboardReceiver` registered for external intent handling
