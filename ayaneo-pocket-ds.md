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

```
TeleDeckIMEService (InputMethodService)
    │
    ├── Primary Display (Display 0)
    │   └── Returns 0-height view (empty placeholder)
    │
    └── Secondary Display (Display 2)
        └── VirtualKeyboardPresentation
            └── Local FlutterEngine
                └── Flutter Keyboard UI (imeMain entry point)
```

### Key Components

#### TeleDeckIMEService.kt

```kotlin
class TeleDeckIMEService : InputMethodService() {
    private var presentation: VirtualKeyboardPresentation? = null
    private var secondaryDisplay: Display? = null

    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        if (secondaryDisplay != null) {
            showKeyboardPresentation()  // Show on display 2
        } else {
            // Fallback to primary display
        }
    }

    private fun showKeyboardPresentation() {
        // Create WindowContext for TYPE_APPLICATION_OVERLAY
        val presentationContext = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            applicationContext.createDisplayContext(secondaryDisplay)
                .createWindowContext(TYPE_APPLICATION_OVERLAY, null)
        } else {
            this
        }

        presentation = VirtualKeyboardPresentation(
            presentationContext,
            secondaryDisplay,
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
            // CRITICAL: Prevent focus stealing from primary display
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
FLAG_NOT_FOCUSABLE      // Key events go to primary display app
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
Flutter (Keyboard UI) <---> Native (TeleDeckIMEService)
         │                           │
    commitText('a')  ───────>  currentInputConnection.commitText()
    backspace()      ───────>  deleteSurroundingText()
    enter()          ───────>  sendKeyEvent(KEYCODE_ENTER)
    moveCursor(n)    ───────>  setSelection()
```

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

## Testing Checklist

- [ ] TeleDeck IME is enabled in system settings
- [ ] TeleDeck is set as active/default IME
- [ ] Gamewindow status (enabled/disabled) is known
- [ ] Secondary display is detected (check logs for "Found secondary display: 2")
- [ ] Presentation is created (check for "Presentation shown successfully")
- [ ] Flutter engine starts (check for "imeMain: Starting IME entry point")
- [ ] Touch events received (check for "dispatchTouchEvent")
- [ ] Text input works (check for "commitText")

## File Locations

```
android/app/src/main/kotlin/app/gsmlg/tele_deck/
├── TeleDeckIMEService.kt      # Main IME service
├── VirtualKeyboardPresentation.kt  # Secondary display presentation
├── MainActivity.kt            # Launcher app activity
└── ToggleKeyboardReceiver.kt  # Broadcast receiver for keyboard toggle

lib/
├── main.dart                  # Launcher app entry point
└── main_ime.dart              # Keyboard UI entry point (imeMain)

android/app/src/main/
├── AndroidManifest.xml        # IME service declaration
└── res/xml/method.xml         # IME configuration
```

## References

- [Android Presentation API](https://developer.android.com/reference/android/app/Presentation)
- [InputMethodService](https://developer.android.com/reference/android/inputmethodservice/InputMethodService)
- [WindowManager.LayoutParams](https://developer.android.com/reference/android/view/WindowManager.LayoutParams)
- [Flutter Multiple Entry Points](https://docs.flutter.dev/add-to-app/android/add-flutter-fragment#multiple-flutter-engines)
