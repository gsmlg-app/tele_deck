# Quickstart: Dual-Screen IME Entry Point Separation

**Feature**: 001-dual-screen-ime-entry
**Date**: 2025-01-05

## Prerequisites

- Android Studio or VS Code with Flutter extension
- Flutter SDK 3.10+
- Android device with secondary display OR Android emulator with secondary display enabled
- ADB for command-line testing

## Build & Install

```bash
# Clone and navigate to project
cd tele_deck

# Install dependencies
flutter pub get

# Run static analysis
flutter analyze

# Build debug APK
flutter build apk --debug

# Install on device
adb install build/app/outputs/flutter-apk/app-debug.apk
```

## Enable TeleDeck IME

1. Open Android **Settings** > **System** > **Languages & input** > **On-screen keyboard**
2. Enable **TeleDeck**
3. Return to previous screen
4. Tap **Default keyboard** and select **TeleDeck**

Or via ADB:
```bash
# Enable the IME
adb shell ime enable app.gsmlg.tele_deck/.TeleDeckIMEService

# Set as default
adb shell ime set app.gsmlg.tele_deck/.TeleDeckIMEService
```

## Test Scenarios

### Scenario 1: Dual-Screen Mode (Primary Use Case)

**Setup**: Device with secondary display connected (Ayaneo Pocket DS, USB-C monitor, etc.)

1. Open any app with a text field (e.g., Notes, Messages)
2. Tap the text field to focus
3. **Expected**: Keyboard appears on secondary display only
4. **Expected**: Primary display shows 0-height input view (no visual obstruction)
5. Type on the virtual keyboard
6. **Expected**: Text appears in the focused field

### Scenario 2: Single-Screen Fallback

**Setup**: Device with no secondary display OR secondary disconnected

1. Open any app with a text field
2. Tap the text field to focus
3. **Expected**: Keyboard appears on primary display
4. **Expected**: Keyboard height ≤ 50% of screen height
5. Type on the virtual keyboard
6. **Expected**: Text appears in the focused field

### Scenario 3: Dynamic Display Switching

**Setup**: Device with detachable secondary display

1. Start with secondary connected, focus a text field
2. **Expected**: Keyboard on secondary display
3. Disconnect secondary display (unplug USB-C)
4. **Expected**: Keyboard transitions to primary display without crash
5. Reconnect secondary display
6. Tap another text field (or refocus)
7. **Expected**: Keyboard appears on secondary display again

### Scenario 4: Launcher Setup Guide

1. Launch TeleDeck app from app drawer
2. **If IME not enabled**: See setup guide with instructions
3. Tap "Open Keyboard Settings"
4. **Expected**: Android keyboard settings opens
5. Enable and select TeleDeck
6. Return to TeleDeck app
7. **Expected**: Shows settings/status view, not setup guide

### Scenario 5: Physical Button Toggle

```bash
# Toggle keyboard visibility
adb shell am broadcast -a app.gsmlg.tele_deck.TOGGLE_KEYBOARD

# Force show
adb shell am broadcast -a app.gsmlg.tele_deck.SHOW_KEYBOARD

# Force hide
adb shell am broadcast -a app.gsmlg.tele_deck.HIDE_KEYBOARD
```

### Scenario 6: Crash Log Viewer

1. (Simulate crash by disconnecting display rapidly during input)
2. If crash occurs, system notification appears
3. Tap notification OR open TeleDeck app > Settings > View Crash Logs
4. **Expected**: List of crash logs with timestamps
5. Tap a log entry
6. **Expected**: Full stack trace and display state at crash time

## Verification Commands

```bash
# Check if IME is enabled
adb shell ime list -s | grep tele_deck

# Check current IME
adb shell settings get secure default_input_method

# View IME service logs
adb logcat -s TeleDeckIME

# Simulate secondary display (emulator only)
adb emu screenrecord start secondary

# List connected displays
adb shell dumpsys display | grep "Display\|mDisplayId"
```

## Success Criteria Checklist

- [ ] SC-001: IME activates without crash (100% success rate)
- [ ] SC-002: Keyboard renders on secondary within 500ms
- [ ] SC-003: Primary shows 0-height input view in dual-screen mode
- [ ] SC-004: Display disconnect causes 0 crashes
- [ ] SC-005: `flutter analyze` passes with no errors
- [ ] SC-006: `flutter build apk --debug` succeeds

## Troubleshooting

### Keyboard doesn't appear

1. Verify TeleDeck is enabled: `adb shell ime list -s`
2. Verify TeleDeck is active: `adb shell settings get secure default_input_method`
3. Check logs: `adb logcat -s TeleDeckIME`

### Keyboard appears on wrong display

1. Check display detection: `adb logcat -s TeleDeckIME | grep "display"`
2. Verify secondary display is recognized: `adb shell dumpsys display`

### App crashes on display disconnect

1. Check crash logs in app
2. Verify debounce logic is working: `adb logcat -s TeleDeckIME | grep "debounce"`
3. Report issue with crash log content
