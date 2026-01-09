# Ayaneo Pocket DS - TeleDeck Keyboard Implementation Notes

## Device Overview

The **Ayaneo Pocket DS** is a dual-screen Android handheld gaming device with:

- **Display 0 (Primary)**: 1920x1080 @ 120Hz - Main touchscreen
- **Display 2 (Secondary)**: 1024x768 @ 60Hz - Bottom touchscreen (like Nintendo DS)
- **Android Version**: 12+ (API 31+)
- **Display IDs**: Primary is `displayId=0`, Secondary is `displayId=2` (no display 1)

## Display Architecture

```
┌─────────────────────────┐
│     Display 0           │  1920x1080 (rotated to landscape)
│     Primary Screen      │  layerStack=0
│     (Apps run here)     │
└─────────────────────────┘
┌─────────────────────────┐
│     Display 2           │  1024x768 (rotated to landscape)
│     Secondary Screen    │  layerStack=2
│     (Keyboard here)     │
└─────────────────────────┘
```

### Display Detection

```kotlin
val displayManager = getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
val displays = displayManager.displays

// Find secondary display
for (display in displays) {
    if (display.displayId != Display.DEFAULT_DISPLAY) {
        // This is display 2 on Ayaneo Pocket DS
        secondaryDisplay = display
    }
}
```

## Ayaneo Gamewindow App

### What is Gamewindow?

`com.ayaneo.gamewindow` is Ayaneo's proprietary app that manages the secondary display. It provides:

1. **SecondaryLauncherActivity** - A launcher/home screen for display 2
2. **System Overlays** - Various overlay windows for quick access features
3. **Display Management** - Controls what shows on the secondary display

### Gamewindow Window Hierarchy

When gamewindow is running, it creates multiple windows on display 2:

```
Window #2  com.ayaneo.gamewindow              ty=DISPLAY_OVERLAY (privileged)
Window #21 com.ayaneo.gamewindow              ty=SYSTEM_ALERT_WINDOW
Window #22 com.ayaneo.gamewindow              (another overlay)
Window #23 com.ayaneo.gamewindow/SecondaryLauncherActivity  ty=BASE_APPLICATION
```

### The Blocking Problem

Gamewindow's `DISPLAY_OVERLAY` window has special properties:

```
ty=DISPLAY_OVERLAY
mBaseLayer=291000          # Very high z-order
pfl=TRUSTED_OVERLAY        # System privilege flag
alpha=1.0                  # Fully opaque
```

Our keyboard presentation has:
```
ty=PRESENTATION or TYPE_APPLICATION_OVERLAY
mBaseLayer=31000           # Much lower z-order
```

**Result**: Gamewindow's overlay completely covers our keyboard because:
1. `mBaseLayer=291000` >> `mBaseLayer=31000`
2. `TRUSTED_OVERLAY` is a system privilege we cannot obtain
3. `alpha=1.0` means it's fully opaque, blocking everything below

### Gamewindow Respawn Behavior

Even when force-stopped, gamewindow automatically respawns when:
- Any touch event occurs on display 2
- The system detects activity on the secondary display
- Certain system events trigger it

```bash
# Force stop (temporary)
adb shell am force-stop com.ayaneo.gamewindow
# Gamewindow will respawn on next touch to display 2
```

## Workarounds Attempted

### 1. Disable Gamewindow (NOT RECOMMENDED)

```bash
# Disable gamewindow package
adb shell pm disable-user --user 0 com.ayaneo.gamewindow

# Re-enable gamewindow
adb shell pm enable --user 0 com.ayaneo.gamewindow
```

**Effects of disabling gamewindow:**
- Secondary display loses its launcher/home screen
- Secondary display shows only wallpaper or black screen
- Quick access features on secondary display stop working
- Our keyboard becomes visible and functional

**Why this is bad:**
- Removes ALL secondary display functionality
- User loses the normal dual-screen experience
- Only the keyboard shows on display 2
- Not a viable solution for end users

### 2. Force Stop Gamewindow (Temporary)

```bash
adb shell am force-stop com.ayaneo.gamewindow
```

**Effects:**
- Temporarily removes gamewindow overlay
- Keyboard becomes visible
- Gamewindow respawns on next touch to display 2 or system event

### 3. Window Type Experiments

Tried various window types to appear above gamewindow:

| Window Type | Result |
|-------------|--------|
| `TYPE_PRESENTATION` (2037) | Blocked by gamewindow overlay |
| `TYPE_APPLICATION_OVERLAY` (2038) | Blocked by gamewindow overlay |
| `TYPE_SYSTEM_ALERT` | Requires system permission, still blocked |

**Conclusion**: No standard window type can appear above `DISPLAY_OVERLAY` with `TRUSTED_OVERLAY` flag.

## TeleDeck Keyboard Implementation

### Architecture

TeleDeck supports **bidirectional keyboard placement** - keyboard appears on the OPPOSITE display from where input is requested:

```
┌─────────────────────────────────────────────────────────────────┐
│                    TeleDeckIMEService                           │
│                   (InputMethodService)                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
              ┌───────────────────────────────┐
              │   detectInputDisplayId()      │
              │   Uses IME window context     │
              └───────────────────────────────┘
                              │
           ┌──────────────────┴──────────────────┐
           ▼                                     ▼
┌─────────────────────┐               ┌─────────────────────┐
│ Input on Primary    │               │ Input on Secondary  │
│ (Display 0)         │               │ (Display 2)         │
└─────────────────────┘               └─────────────────────┘
           │                                     │
           ▼                                     ▼
┌─────────────────────┐               ┌─────────────────────┐
│ Show Keyboard on    │               │ Show Keyboard on    │
│ SECONDARY (Display 2)│              │ PRIMARY (Display 0) │
│ via Presentation    │               │ via Presentation    │
└─────────────────────┘               └─────────────────────┘
```

### Input Display Detection

The IME detects which display the input is on using the IME window's display context:

```kotlin
private fun detectInputDisplayId(): Int {
    // Method 1: Use IME window's display context (most reliable)
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && secondaryDisplay != null) {
        window?.window?.let { imeWindow ->
            val windowDisplay = imeWindow.context.display
            val windowDisplayId = windowDisplay?.displayId ?: Display.DEFAULT_DISPLAY
            Log.d(TAG, "IME window display: $windowDisplayId")

            // If the IME window is on a non-default display, that's where the input is
            if (windowDisplayId != Display.DEFAULT_DISPLAY) {
                return windowDisplayId
            }
        }
    }

    // Method 2: Check known secondary display packages
    val editorPackage = currentInputEditorInfo?.packageName
    val secondaryDisplayPackages = setOf(
        "com.ayaneo.gamewindow",
        "com.ayaneo.secondlauncher",
        "com.ayaneo.home"
    )
    if (editorPackage in secondaryDisplayPackages) {
        return secondaryDisplay?.displayId ?: Display.DEFAULT_DISPLAY
    }

    return Display.DEFAULT_DISPLAY
}
```

### Key Components

#### TeleDeckIMEService.kt

```kotlin
class TeleDeckIMEService : InputMethodService() {
    private var presentation: VirtualKeyboardPresentation? = null
    private var secondaryDisplay: Display? = null

    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        if (secondaryDisplay == null) {
            // No secondary display - use primary fallback mode
            isInPrimaryFallbackMode = true
            ensurePrimaryViewAttached()
        } else {
            // Dual display mode - detect input display and show keyboard on opposite
            val inputOnSecondary = isInputOnSecondaryDisplay()

            if (inputOnSecondary) {
                // Input on secondary → keyboard on PRIMARY
                val primaryDisplay = displayManager?.getDisplay(Display.DEFAULT_DISPLAY)
                hideKeyboardPresentation()
                showKeyboardPresentation(primaryDisplay)
            } else {
                // Input on primary → keyboard on SECONDARY
                cleanupPrimaryFlutterView()
                showKeyboardPresentation(secondaryDisplay)
            }
        }
    }

    private fun showKeyboardPresentation(targetDisplay: Display? = null) {
        val display = targetDisplay ?: secondaryDisplay ?: return

        // Check if presentation is on correct display
        presentation?.let { p ->
            if (p.isShowing && p.display?.displayId == display.displayId) {
                return // Already showing on correct display
            }
            p.dismiss()
            presentation = null
        }

        // Create WindowContext for TYPE_APPLICATION_OVERLAY
        val presentationContext = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            applicationContext.createDisplayContext(display)
                .createWindowContext(TYPE_APPLICATION_OVERLAY, null)
        } else {
            this
        }

        presentation = VirtualKeyboardPresentation(
            presentationContext,
            display,
            flutterEngine,
            onEngineReady = { engine -> setupMethodChannelOnEngine(engine) }
        )
        presentation?.show()
    }
}
```

#### VirtualKeyboardPresentation.kt

```kotlin
class VirtualKeyboardPresentation(
    context: Context,
    display: Display,
    private val sharedFlutterEngine: FlutterEngine,
    private val onEngineReady: ((FlutterEngine) -> Unit)? = null
) : Presentation(context, display) {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        window?.let { window ->
            // CRITICAL: Prevent focus stealing from the other display
            window.addFlags(
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
            )

            // Visual configuration
            window.addFlags(WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED)
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            window.setFormat(PixelFormat.OPAQUE)
            window.setBackgroundDrawableResource(android.R.color.black)
        }

        createFlutterView()
    }
}
```

### Critical Window Flags

```kotlin
// MUST have these flags to prevent focus issues:
FLAG_NOT_FOCUSABLE      // Key events go to the app's display, not keyboard
FLAG_NOT_TOUCH_MODAL    // Touch events outside keyboard pass through

// Without these flags:
// - Touching keyboard steals focus from primary app
// - onFinishInputView gets called
// - IME service gets destroyed and recreated
// - Keyboard disappears
```

### Flutter Entry Point

The keyboard UI runs from a separate Dart entry point:

```dart
// lib/main_ime.dart
@pragma('vm:entry-point')
void imeMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TeleDeckKeyboardApp());
}
```

**Important**: The `@pragma('vm:entry-point')` annotation is required for AOT compilation to include the entry point.

## MethodChannel Communication

```
Flutter (Keyboard UI) <──────────> Native (TeleDeckIMEService)
         │                                    │
    commitText('a')      ───────────>  currentInputConnection.commitText()
    backspace()          ───────────>  deleteSurroundingText()
    delete()             ───────────>  deleteSurroundingText(0, 1)
    enter()              ───────────>  sendKeyEvent(KEYCODE_ENTER)
    tab()                ───────────>  sendKeyEvent(KEYCODE_TAB)
    sendKeyEvent(...)    ───────────>  KeyEvent with modifiers (Ctrl, Alt, etc.)
    hideKeyboard()       ───────────>  hideKeyboardPresentation() + requestHideSelf()
    openImePicker()      ───────────>  InputMethodManager.showInputMethodPicker()
    getConnectionStatus  <───────────  currentInputConnection != null
```

### Keyboard UI Features

The keyboard header includes:

| Button | Icon | Action |
|--------|------|--------|
| IME Picker | `keyboard_alt_outlined` | Opens system IME picker to switch keyboards |
| Settings | `settings` | Shows keyboard settings info |
| Hide Keyboard | `keyboard_hide` | Hides keyboard and dismisses presentation |

### Key Input Features

| Feature | Description |
|---------|-------------|
| Long press repeat | Hold character keys to repeat input |
| Haptic feedback | Vibration on key press (configurable) |
| Shift lock | Double-tap Shift to lock uppercase |
| Modifier keys | Ctrl, Alt, Super (Windows) key support |
| Arrow keys | DPAD keycodes sent via sendKeyEvent |
| Function keys | F1-F12 with media function icons when Fn pressed |

## Debugging Commands

```bash
# Check display status
adb shell dumpsys display | grep -E "Display Id|state"

# Check window hierarchy on display 2
adb shell dumpsys window windows | grep -B2 "mDisplayId=2"

# Check if gamewindow is blocking
adb shell dumpsys window windows | grep -i gamewindow

# Check TeleDeck keyboard logs
adb logcat -s TeleDeckIME:D VirtualKeyboardPresentation:D

# Check input display detection logs
adb logcat -s TeleDeckIME:D | grep -E "(IME window display|inputOnSecondary|showKeyboardPresentation)"

# Check active IME
adb shell settings get secure default_input_method

# Set TeleDeck as active IME
adb shell ime set app.gsmlg.tele_deck/.TeleDeckIMEService

# Check IME state
adb shell dumpsys input_method | grep -E "mShowRequested|mInputShown"
```

## Known Issues

### 1. Gamewindow Overlay Blocking

**Status**: Unresolved

The gamewindow overlay blocks our keyboard. Current workarounds:
- Disable gamewindow (removes secondary display functionality)
- Force-stop gamewindow (temporary, respawns on touch)

**Potential solutions to investigate:**
- Contact Ayaneo for API to allow third-party apps above overlay
- Check if AYASetting app has configuration for gamewindow
- Investigate if gamewindow has intent filters to disable overlay mode
- System app installation with higher privileges

### 2. Flutter Entry Point Not Found

**Status**: Resolved

**Error**: `Could not resolve main entrypoint function`

**Cause**: The local FlutterEngine in Presentation couldn't find `imeMain` entry point.

**Solution**:
- Ensure `@pragma('vm:entry-point')` annotation on `imeMain()`
- Export from main.dart: `export 'main_ime.dart' show imeMain;`
- Clean rebuild: `flutter clean && flutter build apk --debug`

### 3. Focus Stealing

**Status**: Resolved

**Problem**: Touching keyboard caused IME to lose focus and restart.

**Solution**: Add `FLAG_NOT_FOCUSABLE | FLAG_NOT_TOUCH_MODAL` to presentation window.

### 4. Input Display Detection

**Status**: Resolved

**Problem**: Could not reliably detect which display the input was coming from.

**Solution**: Use the IME window's display context (`window?.window?.context.display`) which correctly reflects the display where input is requested.

## Testing Checklist

- [ ] TeleDeck IME is enabled in system settings
- [ ] TeleDeck is set as active/default IME
- [ ] Gamewindow status (enabled/disabled) is known
- [ ] Secondary display is detected (check logs for "Found secondary display: 2")
- [ ] Presentation is created (check for "Presentation shown successfully")
- [ ] Flutter engine starts (check for "imeMain: Starting IME entry point")
- [ ] Touch events received (check for "dispatchTouchEvent")
- [ ] Text input works (check for "commitText")
- [ ] Input on primary → keyboard on secondary
- [ ] Input on secondary → keyboard on primary
- [ ] Hide keyboard button works
- [ ] IME picker button works

## File Locations

```
android/app/src/main/kotlin/app/gsmlg/tele_deck/
├── TeleDeckIMEService.kt      # Main IME service with dual-display logic
├── VirtualKeyboardPresentation.kt  # Presentation for any display
├── MainActivity.kt            # Launcher app activity
└── ToggleKeyboardReceiver.kt  # Broadcast receiver for keyboard toggle

lib/
├── main.dart                  # Launcher app entry point
└── main_ime.dart              # Keyboard UI entry point (imeMain)

app_widget/keyboard_widgets/lib/src/
├── keyboard_view.dart         # Main keyboard layout with header
├── keyboard_key.dart          # Individual key widget with haptic/repeat
└── mode_selector_overlay.dart # Keyboard mode selector

app_bloc/keyboard_bloc/lib/src/
├── keyboard_bloc.dart         # Keyboard state management
├── keyboard_event.dart        # Keyboard events (key press, modifiers)
└── keyboard_state.dart        # Keyboard state (shift, ctrl, mode, etc.)

android/app/src/main/
├── AndroidManifest.xml        # IME service declaration
└── res/xml/method.xml         # IME configuration
```

## References

- [Android Presentation API](https://developer.android.com/reference/android/app/Presentation)
- [InputMethodService](https://developer.android.com/reference/android/inputmethodservice/InputMethodService)
- [WindowManager.LayoutParams](https://developer.android.com/reference/android/view/WindowManager.LayoutParams)
- [Flutter Multiple Entry Points](https://docs.flutter.dev/add-to-app/android/add-flutter-fragment#multiple-flutter-engines)
- [Android Multi-Display](https://developer.android.com/guide/topics/large-screens/multi-window-support)
