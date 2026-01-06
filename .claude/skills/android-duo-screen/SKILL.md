---
name: android-duo-screen
description: Guide for building dual-screen Android apps using Presentation API for secondary displays
---

# Android Dual-Screen Development Skill

This skill guides development of Android apps that render content on secondary displays (external monitors, dual-screen devices like Ayaneo Pocket DS).

## When to Use

Trigger this skill when:
- Building apps for dual-screen or foldable devices
- Rendering UI on secondary/external displays
- Using Android's Presentation API
- User asks about "dual display", "secondary screen", "Presentation class", or "multi-display"

## Core Architecture

### Display Detection

Use `DisplayManager` to detect and monitor displays:

```kotlin
class DualScreenService : Service() {
    private var displayManager: DisplayManager? = null
    private var secondaryDisplay: Display? = null

    override fun onCreate() {
        displayManager = getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
        displayManager?.registerDisplayListener(displayListener, null)
        findSecondaryDisplay()
    }

    private fun findSecondaryDisplay() {
        displayManager?.displays?.forEach { display ->
            if (display.displayId != Display.DEFAULT_DISPLAY) {
                secondaryDisplay = display
                return
            }
        }
    }

    private val displayListener = object : DisplayManager.DisplayListener {
        override fun onDisplayAdded(displayId: Int) {
            // Handle with debouncing to prevent race conditions
            handleDisplayAddedDebounced(displayId)
        }
        override fun onDisplayRemoved(displayId: Int) {
            handleDisplayRemovedDebounced(displayId)
        }
        override fun onDisplayChanged(displayId: Int) { }
    }
}
```

### Presentation Class

Android's `Presentation` class renders content on secondary displays:

```kotlin
class SecondaryPresentation(
    context: Context,
    display: Display,
    private val onReady: (() -> Unit)? = null
) : Presentation(context, display) {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        window?.let { window ->
            // CRITICAL: Focus management flags
            window.addFlags(
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
            )

            // Fullscreen on secondary display
            window.setFlags(
                WindowManager.LayoutParams.FLAG_FULLSCREEN or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                WindowManager.LayoutParams.FLAG_FULLSCREEN or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN
            )

            window.addFlags(WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED)
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }

        setContentView(R.layout.secondary_display_layout)
        onReady?.invoke()
    }
}
```

## Critical Patterns

### 1. Focus Management (Essential)

Without proper focus flags, touching the secondary display steals focus from the primary:

```kotlin
// MUST set these flags to prevent focus stealing
window.addFlags(
    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
)
```

| Flag | Purpose |
|------|---------|
| `FLAG_NOT_FOCUSABLE` | Window won't get key input focus; key events go to primary |
| `FLAG_NOT_TOUCH_MODAL` | Touch events outside window pass through to primary apps |

### 2. Android 12+ Context Creation

On Android 12+, use `createWindowContext` for proper display context:

```kotlin
val presentationContext: Context = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
    // TYPE_PRESENTATION = 2011
    createDisplayContext(display).createWindowContext(2011, null)
} else {
    this
}

presentation = SecondaryPresentation(presentationContext, display)
```

### 3. Display Event Debouncing

Rapid connect/disconnect can cause race conditions:

```kotlin
companion object {
    private const val DISPLAY_DEBOUNCE_MS = 500L
}

private val mainHandler = Handler(Looper.getMainLooper())
private var pendingDisplayAddedRunnable: Runnable? = null

private fun handleDisplayAddedDebounced(displayId: Int) {
    // Cancel pending remove (prevents race condition)
    pendingDisplayRemovedRunnable?.let { mainHandler.removeCallbacks(it) }

    // Cancel previous pending add
    pendingDisplayAddedRunnable?.let { mainHandler.removeCallbacks(it) }

    pendingDisplayAddedRunnable = Runnable {
        handleDisplayAdded(displayId)
    }
    mainHandler.postDelayed(pendingDisplayAddedRunnable!!, DISPLAY_DEBOUNCE_MS)
}
```

### 4. Flutter on Secondary Display

**IMPORTANT**: Create a LOCAL FlutterEngine for Presentation - shared engines don't render properly:

```kotlin
class FlutterPresentation(
    context: Context,
    display: Display,
    private val onEngineReady: ((FlutterEngine) -> Unit)? = null
) : Presentation(context, display) {

    companion object {
        // Local engine for this display context
        private var localFlutterEngine: FlutterEngine? = null
        private var isDartEntrypointExecuted: Boolean = false
    }

    private var flutterView: FlutterView? = null

    private fun createFlutterView() {
        // Create LOCAL engine for this Presentation's display context
        if (localFlutterEngine == null) {
            localFlutterEngine = FlutterEngine(context)
        }

        flutterView = FlutterView(context)
        setContentView(flutterView)

        flutterView?.addOnAttachStateChangeListener(object : View.OnAttachStateChangeListener {
            override fun onViewAttachedToWindow(v: View) {
                if (!isDartEntrypointExecuted) {
                    val appBundlePath = FlutterInjector.instance().flutterLoader().findAppBundlePath()
                    localFlutterEngine!!.dartExecutor.executeDartEntrypoint(
                        DartExecutor.DartEntrypoint(appBundlePath, "secondaryMain")
                    )
                    isDartEntrypointExecuted = true
                }

                flutterView?.attachToFlutterEngine(localFlutterEngine!!)
                onEngineReady?.invoke(localFlutterEngine!!)
                localFlutterEngine!!.lifecycleChannel.appIsResumed()
            }

            override fun onViewDetachedFromWindow(v: View) {
                flutterView?.detachFromFlutterEngine()
            }
        })
    }
}
```

## Available Plugin: `tele_presentation`

The `tele_presentation` plugin provides reusable components for secondary display support:

### Native Components (Kotlin)

**FlutterPresentation** - Base class for Flutter on secondary displays:
```kotlin
import com.tele.tele_presentation.FlutterPresentation

class MyPresentation(
    context: Context,
    display: Display,
    dartEntrypoint: String = "secondaryMain"
) : FlutterPresentation(context, display, dartEntrypoint) {

    override fun onEngineReady(engine: FlutterEngine) {
        // Set up MethodChannel communication
        MethodChannel(engine.dartExecutor.binaryMessenger, "my_channel")
            .setMethodCallHandler { call, result -> /* ... */ }
    }
}
```

**DisplayHelper** - Display detection with debounced events:
```kotlin
import com.tele.tele_presentation.DisplayHelper

val displayHelper = DisplayHelper(context)

// Check for secondary display
val secondaryDisplay = displayHelper.getSecondaryDisplay()

// Listen for display changes (debounced)
displayHelper.registerDisplayListener(object : DisplayHelper.DisplayListener {
    override fun onDisplayAdded(display: Display) {
        // Show presentation
    }
    override fun onDisplayRemoved(displayId: Int) {
        // Dismiss presentation
    }
})
```

### Dart API

```dart
import 'package:tele_presentation/tele_presentation.dart';

// Check for secondary display
final hasSecondary = await TelePresentation.instance.hasSecondaryDisplay();
final display = await TelePresentation.instance.getSecondaryDisplay();

// Listen for display events
TelePresentation.instance.startListening();
TelePresentation.instance.displayEvents.listen((event) {
  switch (event.type) {
    case DisplayEventType.added:
      print('Display added: ${event.display}');
    case DisplayEventType.removed:
      print('Display removed: ${event.displayId}');
    case DisplayEventType.changed:
      print('Display changed');
  }
});
```

## Reference Implementation

See the TeleDeck codebase:
- `android/.../VirtualKeyboardPresentation.kt` - Flutter Presentation with local engine
- `android/.../TeleDeckIMEService.kt` - Display management and mode switching
- `app_plugin/tele_presentation/` - Plugin source code

## Debugging

```bash
# Watch Presentation logs
adb logcat -s VirtualKeyboardPresentation:D

# Check detected displays
adb shell dumpsys display | grep -A5 "Display Devices"
```

## Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Content on secondary steals focus | Missing focus flags | Add `FLAG_NOT_FOCUSABLE \| FLAG_NOT_TOUCH_MODAL` |
| Flutter blank on secondary | Shared engine | Create LOCAL FlutterEngine in Presentation context |
| Crash on Android 12+ | Wrong window context | Use `createWindowContext(TYPE_PRESENTATION)` |
| Race condition on disconnect | No debouncing | Debounce display events (500ms) |
| Presentation won't show | Display invalid/removed | Check `display.isValid` before show() |
