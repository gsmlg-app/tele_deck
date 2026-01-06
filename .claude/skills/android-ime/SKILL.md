---
name: android-ime
description: Guide for building Android Input Method Engines (IME) with InputMethodService
---

# Android IME Development Skill

This skill guides development of custom Input Method Editors (keyboards) for Android using `InputMethodService`.

## When to Use

Trigger this skill when:
- Building a custom keyboard/IME for Android
- Implementing `InputMethodService`
- Working with `InputConnection` for text input
- User asks about "IME", "keyboard service", "input method", or "custom keyboard"

## Core Architecture

### InputMethodService Basics

```kotlin
class CustomIMEService : InputMethodService() {

    override fun onCreate() {
        super.onCreate()
        // Initialize resources, engines, etc.
    }

    override fun onCreateInputView(): View {
        // Return your keyboard layout
        return layoutInflater.inflate(R.layout.keyboard_view, null)
    }

    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        // Keyboard becoming visible - setup for current editor
    }

    override fun onFinishInputView(finishingInput: Boolean) {
        super.onFinishInputView(finishingInput)
        // Keyboard being hidden
    }

    override fun onDestroy() {
        // Cleanup resources
        super.onDestroy()
    }
}
```

### AndroidManifest Configuration

```xml
<service
    android:name=".CustomIMEService"
    android:permission="android.permission.BIND_INPUT_METHOD"
    android:exported="true">
    <intent-filter>
        <action android:name="android.view.InputMethod" />
    </intent-filter>
    <meta-data
        android:name="android.view.im"
        android:resource="@xml/method" />
</service>
```

Create `res/xml/method.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<input-method xmlns:android="http://schemas.android.com/apk/res/android"
    android:settingsActivity="com.example.ime.SettingsActivity"
    android:isDefault="false">
    <subtype
        android:label="@string/subtype_en_US"
        android:imeSubtypeLocale="en_US"
        android:imeSubtypeMode="keyboard" />
</input-method>
```

## InputConnection API

The `InputConnection` is how you send text to the focused app:

```kotlin
// Commit text at cursor
currentInputConnection?.commitText("Hello", 1)

// Delete backward (backspace)
currentInputConnection?.deleteSurroundingText(1, 0)

// Delete forward (delete key)
currentInputConnection?.deleteSurroundingText(0, 1)

// Move cursor
currentInputConnection?.let { ic ->
    val extracted = ic.getExtractedText(ExtractedTextRequest(), 0)
    if (extracted != null) {
        val newPos = (extracted.selectionStart + offset).coerceIn(0, extracted.text?.length ?: 0)
        ic.setSelection(newPos, newPos)
    }
}

// Send key event (for special keys)
currentInputConnection?.let { ic ->
    val downEvent = KeyEvent(
        System.currentTimeMillis(),
        System.currentTimeMillis(),
        KeyEvent.ACTION_DOWN,
        keyCode,
        0,
        metaState
    )
    val upEvent = KeyEvent(
        System.currentTimeMillis(),
        System.currentTimeMillis(),
        KeyEvent.ACTION_UP,
        keyCode,
        0,
        metaState
    )
    ic.sendKeyEvent(downEvent)
    ic.sendKeyEvent(upEvent)
}
```

### Handling Enter Key

Enter behavior depends on the editor's `imeOptions`:

```kotlin
private fun sendEnter() {
    currentInputConnection?.let { ic ->
        val editorInfo = currentInputEditorInfo
        if (editorInfo != null &&
            (editorInfo.imeOptions and EditorInfo.IME_FLAG_NO_ENTER_ACTION) == 0) {
            val action = editorInfo.imeOptions and EditorInfo.IME_MASK_ACTION
            if (action != EditorInfo.IME_ACTION_NONE &&
                action != EditorInfo.IME_ACTION_UNSPECIFIED) {
                // Perform the action (Search, Send, Done, etc.)
                ic.performEditorAction(action)
                return
            }
        }
        // Default to newline
        ic.commitText("\n", 1)
    }
}
```

## IME Lifecycle

```
onCreate()
    ↓
onCreateInputView() → Returns keyboard layout (cached by system)
    ↓
onStartInput() → Input field focused (no view yet)
    ↓
onStartInputView() → Keyboard visible, ready for input
    ↓
[User types, switches apps, etc.]
    ↓
onFinishInputView() → Keyboard being hidden
    ↓
onFinishInput() → Input field unfocused
    ↓
onDestroy() → Service terminating
```

### Key State Flags

```kotlin
private var isInPrimaryFallbackMode: Boolean = false
private var isPrimaryViewAttached: Boolean = false
private var isDartEntrypointExecuted: Boolean = false
```

## MethodChannel Integration (Flutter IME)

Set up bidirectional communication with Flutter:

```kotlin
private fun setupMethodChannel(engine: FlutterEngine) {
    val channel = MethodChannel(engine.dartExecutor.binaryMessenger, "my_ime/channel")
    channel.setMethodCallHandler { call, result ->
        when (call.method) {
            "commitText" -> {
                val text = call.arguments as? String ?: ""
                currentInputConnection?.commitText(text, 1)
                result.success(true)
            }
            "backspace" -> {
                currentInputConnection?.deleteSurroundingText(1, 0)
                result.success(true)
            }
            "sendKeyEvent" -> {
                val args = call.arguments as? Map<String, Any?> ?: emptyMap()
                val keyCode = (args["keyCode"] as? Int) ?: 0
                val shift = (args["shift"] as? Boolean) ?: false
                // Build metaState and send key event
                sendKeyEventToApp(keyCode, buildMetaState(shift, ...))
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    // Store reference for sending notifications to Flutter
    methodChannel = channel
}

// Notify Flutter about connection status
private fun notifyFlutterConnectionStatus(connected: Boolean) {
    methodChannel?.invokeMethod("connectionStatus", mapOf("connected" to connected))
}
```

## IME Status Checks

```kotlin
// Check if IME is enabled in system settings
private fun isImeEnabled(): Boolean {
    val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
    return imm.enabledInputMethodList.any { it.packageName == packageName }
}

// Check if IME is currently active
private fun isImeActive(): Boolean {
    val currentIme = Settings.Secure.getString(
        contentResolver,
        Settings.Secure.DEFAULT_INPUT_METHOD
    )
    return currentIme?.contains(packageName) == true
}
```

## Visibility Control

```kotlin
// Request to show keyboard
requestShowSelf(0)

// Request to hide keyboard
requestHideSelf(0)

// Check if keyboard is currently shown
val isShown = isInputViewShown

// Override to always allow showing
override fun onShowInputRequested(flags: Int, configChange: Boolean): Boolean {
    return true // Always allow keyboard to show
}
```

## Available Plugin: `tele_ime`

The `tele_ime` plugin provides reusable components for building IMEs:

### Native Components (Kotlin)

**BaseImeService** - Base class for Flutter-based IMEs:
```kotlin
import com.tele.tele_ime.BaseImeService

class MyIMEService : BaseImeService() {

    override fun getDartEntrypoint(): String = "imeMain"

    override fun getKeyboardHeight(): Int? {
        // Return null for default, 0 to hide (secondary display mode)
        return (resources.displayMetrics.heightPixels * 0.5).toInt()
    }

    override fun onSetupMethodChannel(channel: MethodChannel) {
        // Add custom handlers (base handles commitText, backspace, etc.)
    }
}
```

**ImeHelper** - IME status and settings utilities:
```kotlin
import com.tele.tele_ime.ImeHelper

val imeHelper = ImeHelper(context)

// Check IME status
val isEnabled = imeHelper.isImeEnabled(MyIMEService::class.java)
val isActive = imeHelper.isImeActive(MyIMEService::class.java)

// Open settings
imeHelper.openImeSettings()
imeHelper.showImePicker()

// Get all IMEs
val installedImes = imeHelper.getInstalledImes()
```

### Dart API

**TeleImeSettings** - For launcher/setup app:
```dart
import 'package:tele_ime/tele_ime.dart';

// Check IME status
final isEnabled = await TeleImeSettings.instance.isImeEnabled();
final isActive = await TeleImeSettings.instance.isImeActive();

// Open settings
await TeleImeSettings.instance.openImeSettings();
await TeleImeSettings.instance.showImePicker();

// List IMEs
final imes = await TeleImeSettings.instance.getInstalledImes();
```

**TeleImeKeyboard** - For keyboard UI:
```dart
import 'package:tele_ime/tele_ime.dart';

// Initialize keyboard service
TeleImeKeyboard.instance.initialize();
TeleImeKeyboard.instance.onInputStarted = (editorInfo) {
  print('Input started: ${editorInfo.packageName}');
};

// Send text operations
await TeleImeKeyboard.instance.commitText('Hello');
await TeleImeKeyboard.instance.backspace();
await TeleImeKeyboard.instance.enter();
await TeleImeKeyboard.instance.sendKeyEvent(KeyEvent.KEYCODE_TAB);
```

## Available Plugin: `tele_crash_logger`

The `tele_crash_logger` plugin provides crash logging with notifications:

### Native (Kotlin)
```kotlin
import com.tele.tele_crash_logger.CrashLogger

// Log a crash
CrashLogger.logCrash(
    context = this,
    errorType = "FlutterError",
    message = "Widget build failed",
    stackTrace = exception.stackTraceToString(),
    engineState = "running",
    showNotification = true
)

// Log an exception
CrashLogger.logException(context, exception, showNotification = true)
```

### Dart API
```dart
import 'package:tele_crash_logger/tele_crash_logger.dart';

// Log crash
await TeleCrashLogger.instance.logCrash(
  errorType: 'FlutterError',
  message: 'Something went wrong',
  stackTrace: stackTrace.toString(),
);

// Get crash logs
final logs = await TeleCrashLogger.instance.getCrashLogs();

// Clear logs
await TeleCrashLogger.instance.clearCrashLogs();
```

## Reference Implementation

See the TeleDeck codebase:
- `android/.../TeleDeckIMEService.kt` - Full IME implementation with dual-screen support
- `lib/main_ime.dart` - Flutter keyboard entry point (`@pragma('vm:entry-point')`)
- `app_lib/tele_services/` - `ImeChannelService` for Flutter-side MethodChannel
- `app_plugin/tele_ime/` - IME plugin source code
- `app_plugin/tele_crash_logger/` - Crash logger plugin source code

## Debugging

```bash
# Watch IME logs
adb logcat -s TeleDeckIME:D

# Check IME status
adb shell ime list -a
adb shell ime set <your.ime.package/.ServiceName>

# Enable IME via settings
adb shell settings put secure enabled_input_methods <ime_id>
```

## Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Keyboard not showing | IME not enabled | Guide user to enable in system settings |
| Text not committing | No InputConnection | Check `currentInputConnection != null` |
| Wrong editor action | Not checking `imeOptions` | Check `EditorInfo.imeOptions` for action |
| View not cached | Recreating view each time | Let Android cache `onCreateInputView()` result |
| Keyboard disappears | Focus stolen | Check focus flags (see android-duo-screen skill) |

## Minimum SDK

```kotlin
// build.gradle
android {
    defaultConfig {
        minSdk = 26  // Required for InputMethodService features
    }
}
```
