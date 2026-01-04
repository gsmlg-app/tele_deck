# Research: Dual-Screen IME Entry Point Separation

**Feature**: 001-dual-screen-ime-entry
**Date**: 2025-01-05

## Research Topics

### 1. Custom Dart Entry Point for IME Service

**Question**: How to define and invoke a custom Dart entry point from Android IME Service?

**Decision**: Use `@pragma('vm:entry-point')` annotation with `DartExecutor.DartEntrypoint`

**Rationale**:
- Flutter supports multiple entry points via the `@pragma('vm:entry-point')` annotation
- The IME service can load a specific Dart entrypoint using `DartExecutor.DartEntrypoint("lib/main_ime.dart", "imeMain")`
- This keeps the keyboard UI code (`main_ime.dart`) separate from the launcher UI (`main.dart`)

**Implementation Pattern**:
```dart
// lib/main_ime.dart
@pragma('vm:entry-point')
void imeMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: TeleDeckKeyboardApp()));
}
```

```kotlin
// TeleDeckIMEService.kt
dartExecutor.executeDartEntrypoint(
    DartExecutor.DartEntrypoint(
        FlutterInjector.instance().flutterLoader().findAppBundlePath(),
        "imeMain"
    )
)
```

**Alternatives Considered**:
- **Single entry point with route-based switching**: Rejected - both UI contexts would be loaded, wasting memory
- **Separate Flutter modules**: Rejected - overcomplicated for this use case, harder to share code

---

### 2. Single-Screen Fallback Rendering

**Question**: How to render keyboard on primary display when no secondary is available?

**Decision**: Use `FlutterView` embedded in standard `onCreateInputView()` return value

**Rationale**:
- When no secondary display exists, the IME must provide a visible input view on primary
- Android's `onCreateInputView()` expects a `View` to display
- A `FlutterView` can be embedded in the returned `FrameLayout`
- Max height constraint (50% screen) enforced via `LayoutParams`

**Implementation Pattern**:
```kotlin
override fun onCreateInputView(): View {
    if (secondaryDisplay != null) {
        // Dual-screen mode: 0-height on primary
        return FrameLayout(this).apply {
            layoutParams = ViewGroup.LayoutParams(MATCH_PARENT, 0)
        }
    } else {
        // Single-screen fallback: embed FlutterView
        return createPrimaryFlutterView()
    }
}

private fun createPrimaryFlutterView(): View {
    val maxHeight = (resources.displayMetrics.heightPixels * 0.5).toInt()
    return flutterView.apply {
        layoutParams = ViewGroup.LayoutParams(MATCH_PARENT, maxHeight)
    }
}
```

**Alternatives Considered**:
- **Always use Presentation API (even on primary)**: Rejected - Presentation API requires a separate display
- **WebView-based fallback**: Rejected - unnecessary complexity, Flutter already runs on primary

---

### 3. Display Connect/Disconnect Debouncing

**Question**: How to handle rapid display events without crashing?

**Decision**: Implement 500ms debounce using `Handler.postDelayed()`

**Rationale**:
- USB-C display connections may trigger multiple add/remove events rapidly
- Debouncing prevents race conditions during Flutter engine state changes
- 500ms is long enough to prevent thrashing, short enough to feel responsive

**Implementation Pattern**:
```kotlin
private val displayHandler = Handler(Looper.getMainLooper())
private var pendingDisplayAction: Runnable? = null

private fun debounceDisplayChange(action: () -> Unit) {
    pendingDisplayAction?.let { displayHandler.removeCallbacks(it) }
    pendingDisplayAction = Runnable { action() }
    displayHandler.postDelayed(pendingDisplayAction!!, 500)
}

override fun onDisplayAdded(displayId: Int) {
    debounceDisplayChange { handleDisplayAdded(displayId) }
}
```

**Alternatives Considered**:
- **No debouncing**: Rejected - could cause ANR or crash during rapid events
- **Coroutine delay**: Rejected - adds Kotlin coroutines dependency, Handler is simpler

---

### 4. Crash Logging with System Notifications

**Question**: How to persist crash logs and show notifications with deep links?

**Decision**: Use file-based logging with `NotificationCompat` and `PendingIntent`

**Rationale**:
- File storage allows offline access and 7-day retention via timestamp-based cleanup
- Android notifications can include deep links via `PendingIntent`
- Deep link opens launcher activity which routes to crash log viewer

**Implementation Pattern**:
```kotlin
// Write crash log
private fun logCrash(error: Throwable) {
    val logFile = File(context.filesDir, "crash_logs/${System.currentTimeMillis()}.log")
    logFile.writeText("${Date()}\n${error.stackTraceToString()}")
    showCrashNotification()
}

// Show notification with deep link
private fun showCrashNotification() {
    val intent = Intent(context, MainActivity::class.java).apply {
        action = "VIEW_CRASH_LOGS"
        flags = Intent.FLAG_ACTIVITY_NEW_TASK
    }
    val pendingIntent = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_IMMUTABLE)
    // Build and show notification with pendingIntent
}
```

**Alternatives Considered**:
- **SQLite database**: Rejected - overkill for simple text logs
- **Remote crash reporting (Firebase)**: Rejected - spec requires offline viewing, privacy concerns

---

### 5. IME Enable Status Detection

**Question**: How can the launcher detect if TeleDeck IME is enabled?

**Decision**: Use `InputMethodManager.getEnabledInputMethodList()`

**Rationale**:
- Standard Android API for querying enabled IMEs
- Works without special permissions
- Returns list that can be checked for TeleDeck's package name

**Implementation Pattern**:
```kotlin
fun isImeEnabled(context: Context): Boolean {
    val imm = context.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
    return imm.enabledInputMethodList.any {
        it.packageName == context.packageName
    }
}
```

```dart
// In Flutter via MethodChannel
Future<bool> isImeEnabled() async {
    return await imeChannel.invokeMethod('isImeEnabled') as bool;
}
```

**Alternatives Considered**:
- **Check SharedPreferences flag**: Rejected - user could enable/disable in system settings, flag would be stale
- **Always show setup guide**: Rejected - poor UX for users who already enabled the IME

---

## Summary

All research questions resolved. No NEEDS CLARIFICATION items remain.

| Topic | Decision | Risk Level |
|-------|----------|------------|
| Custom entry point | `@pragma('vm:entry-point')` + `DartEntrypoint` | Low |
| Single-screen fallback | FlutterView in `onCreateInputView()` | Medium |
| Display debouncing | 500ms Handler delay | Low |
| Crash logging | File-based + NotificationCompat | Low |
| IME status detection | `InputMethodManager.getEnabledInputMethodList()` | Low |

Proceed to Phase 1: Design & Contracts.
