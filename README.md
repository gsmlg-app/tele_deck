# TeleDeck

A dual-screen custom keyboard application for Android handheld devices with secondary displays (Ayaneo Pocket DS, etc.).

## Overview

TeleDeck transforms your dual-screen device into a dedicated input system:
- **Primary Screen**: Read-only virtual input field with real-time text updates
- **Secondary Screen**: Cyberpunk-styled QWERTY keyboard with neon glow effects

Communication between screens uses low-latency IPC via Dart's `IsolateNameServer`.

## Features

- Custom QWERTY keyboard with cyberpunk aesthetic (dark theme, neon cyan/magenta accents)
- Real-time keystroke transmission via IPC
- Blinking cursor and character/word/line count display
- Shift key with auto-disable after character input
- Support for device folding/unfolding events
- **Physical button binding** for keyboard toggle via Android Intents
- **Configurable startup behavior** (hidden by default, show on startup, remember last state)
- **Settings UI** accessible from both main screen and keyboard

## Physical Button Binding

Ayaneo Pocket DS (or other devices) can bind physical buttons to these actions:

| Action | Intent |
|--------|--------|
| Toggle Keyboard | `app.gsmlg.tele_deck.TOGGLE_KEYBOARD` |
| Show Keyboard | `app.gsmlg.tele_deck.SHOW_KEYBOARD` |
| Hide Keyboard | `app.gsmlg.tele_deck.HIDE_KEYBOARD` |

Test via ADB:
```bash
adb shell am broadcast -a app.gsmlg.tele_deck.TOGGLE_KEYBOARD
```

## Requirements

- Android device with secondary display support
- Android SDK 26+ (Android 8.0 Oreo)
- Flutter SDK 3.10+

## Getting Started

```bash
# Install dependencies
flutter pub get

# Run on connected device
flutter run

# Build release APK
flutter build apk
```

## Architecture

```
lib/
├── main.dart                      # Main screen entry point
├── main_keyboard.dart             # Secondary screen entry point
├── shared/
│   ├── constants.dart             # Theme colors, keyboard layout
│   └── protocol.dart              # IPC event protocol (KeyboardEvent)
├── settings/
│   ├── settings_model.dart        # Settings data class
│   ├── settings_provider.dart     # Riverpod state management
│   ├── settings_service.dart      # Persistence layer
│   └── views/
│       └── settings_view.dart     # Settings UI
├── main_screen/
│   ├── display_controller.dart    # IPC listener, Riverpod state
│   └── views/
│       └── main_display_view.dart # Input display UI
└── keyboard_screen/
    ├── keyboard_service.dart      # IPC sender
    └── views/
        ├── keyboard_view.dart     # QWERTY layout
        └── keyboard_key.dart      # Key widget with glow effect
```

## Tech Stack

- **Framework**: Flutter / Dart 3.0+
- **State Management**: flutter_riverpod v2
- **Multi-Screen**: presentation_displays
- **IPC**: dart:ui IsolateNameServer + ReceivePort/SendPort
- **Persistence**: shared_preferences

## License

MIT
