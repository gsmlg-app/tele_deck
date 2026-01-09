# TeleDeck

A System IME (Input Method Editor) for Android with dual-screen support, designed for handheld devices like Ayaneo Pocket DS.

## Overview

TeleDeck is a custom keyboard that runs as a system input method, allowing it to work with any app on your device. On dual-screen devices, the keyboard renders on the secondary display while you type into apps on the primary screen.

**Key Features:**
- System-wide input method (works with any app)
- Dual-screen support (keyboard on secondary display)
- Multiple keyboard layouts (Standard, Numpad, Emoji, Function row)
- Cyberpunk aesthetic with neon glow effects
- Modifier key support (Shift, Ctrl, Alt, Super, Fn)
- Configurable keyboard rotation (0°, 90°, 180°, 270°)
- Crash logging with 7-day retention

## Screenshots

The keyboard features a dark cyberpunk theme with neon cyan and magenta accents.

## Installation

### From APK

1. Download the latest APK from [Releases](https://github.com/gsmlg-app/tele_deck/releases)
2. Install the APK on your device
3. Open the TeleDeck app
4. Follow the setup guide to enable and activate the IME

### From Source

```bash
# Clone the repository
git clone https://github.com/gsmlg-app/tele_deck.git
cd tele_deck

# Install dependencies (uses Melos for monorepo management)
melos bootstrap

# Build release APK
flutter build apk --release

# Or run in debug mode
flutter run
```

## Setup Guide

After installing TeleDeck, you need to enable it as an input method:

1. **Enable IME**: Go to Settings > System > Languages & Input > On-screen keyboard > Manage on-screen keyboards > Enable "TeleDeck"
2. **Select IME**: Tap "Select TeleDeck as active keyboard" or use the keyboard switcher when typing
3. **Done**: The keyboard will now appear when you tap any text field

The TeleDeck app includes a setup guide that walks you through these steps.

## Keyboard Layouts

| Layout | Description |
|--------|-------------|
| Standard | Full QWERTY with 6 rows (function keys, numbers, letters) |
| Numpad | Numeric keypad for number entry |
| Emoji | Emoji picker (coming soon) |

### Modifier Keys

- **Shift**: Capitalize letters (tap once) or lock (double-tap)
- **Caps Lock**: Toggle caps lock mode
- **Ctrl/Alt/Super**: Modifier keys for shortcuts
- **Fn**: Access function keys and special characters

## Architecture

TeleDeck uses a Melos monorepo with BLoC state management:

```
tele_deck/
├── lib/                    # App entry points
│   ├── main.dart           # Launcher (settings/setup)
│   └── main_ime.dart       # IME keyboard
├── app_lib/                # Core libraries
│   ├── tele_theme/         # Cyberpunk theme
│   ├── tele_models/        # Data models
│   ├── tele_services/      # Platform services
│   ├── tele_logging/       # Crash logging
│   └── tele_constants/     # Constants
├── app_bloc/               # State management
│   ├── keyboard_bloc/      # Keyboard state
│   ├── settings_bloc/      # Settings
│   └── setup_bloc/         # Setup flow
├── app_widget/             # UI components
│   ├── keyboard_widgets/   # Keyboard UI
│   ├── settings_widgets/   # Settings UI
│   └── common_widgets/     # Shared widgets
├── third_party/            # Third-party packages
│   ├── form_bloc/          # Form state management
│   └── flutter_form_bloc/  # Flutter form widgets
└── android/                # Native code
```

## Supported Devices

TeleDeck is designed for dual-screen Android handhelds. Device-specific implementation notes:

| Device | Documentation |
|--------|---------------|
| **Ayaneo Pocket DS** | [docs/devices/ayaneo-pocket-ds.md](docs/devices/ayaneo-pocket-ds.md) |

The Ayaneo Pocket DS documentation includes:
- Display architecture (Primary 1920x1080, Secondary 1024x768)
- Bidirectional keyboard placement
- Gamewindow overlay workarounds
- Debugging commands

## Requirements

- Android 8.0+ (API 26+)
- Flutter 3.x
- For dual-screen: Device with secondary display support

## Tech Stack

- **Framework**: Flutter / Dart 3.8+
- **State Management**: flutter_bloc v9.x
- **Forms**: form_bloc + flutter_form_bloc
- **Workspace**: Melos monorepo
- **Native**: Kotlin (Android InputMethodService)
- **Persistence**: shared_preferences

## Development

```bash
# Bootstrap workspace
melos bootstrap

# Run analysis
melos run analyze

# Run tests
melos run test

# Format code
melos run format
```

## License

MIT
