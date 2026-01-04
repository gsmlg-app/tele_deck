# MethodChannel Contract: tele_deck/ime

**Feature**: 001-dual-screen-ime-entry
**Date**: 2025-01-05
**Channel Name**: `tele_deck/ime`

## Overview

This document defines the MethodChannel API contract between Flutter (Dart) and native Android (Kotlin) for the TeleDeck IME service.

## Direction: Flutter → Native (Keyboard Actions)

### commitText

Commit typed text to the focused input field.

**Method**: `commitText`

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| text | String | Yes | Character(s) to insert |

**Returns**: `bool` - true if successful

**Example**:
```dart
await imeChannel.invokeMethod('commitText', {'text': 'a'});
```

---

### backspace

Delete character before cursor.

**Method**: `backspace`

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| (none) | - | - | - |

**Returns**: `bool` - true if successful

---

### delete

Delete character after cursor.

**Method**: `delete`

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| (none) | - | - | - |

**Returns**: `bool` - true if successful

---

### enter

Send enter/action key to input field.

**Method**: `enter`

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| (none) | - | - | - |

**Returns**: `bool` - true if successful

**Behavior**: Performs editor action if defined (search, go, send), otherwise inserts newline.

---

### tab

Insert tab character.

**Method**: `tab`

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| (none) | - | - | - |

**Returns**: `bool` - true if successful

---

### moveCursor

Move cursor in specified direction.

**Method**: `moveCursor`

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| direction | String | Yes | One of: `left`, `right`, `up`, `down` |

**Returns**: `bool` - true if successful

---

### sendKeyEvent

Send raw key event with modifier state.

**Method**: `sendKeyEvent`

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| keyCode | int | Yes | Android KeyEvent keycode |
| metaState | int | No | Modifier flags (Ctrl, Alt, Shift, Meta) |

**Returns**: `bool` - true if successful

**Meta State Flags**:
- `META_CTRL_ON`: 0x1000
- `META_ALT_ON`: 0x2
- `META_SHIFT_ON`: 0x1
- `META_META_ON`: 0x10000

---

### getConnectionStatus

Query if an input connection is currently active.

**Method**: `getConnectionStatus`

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| (none) | - | - | - |

**Returns**: `bool` - true if text field is focused

---

## Direction: Native → Flutter (Status Updates)

### connectionStatus

Notify Flutter when input connection state changes.

**Method**: `connectionStatus`

| Parameter | Type | Description |
|-----------|------|-------------|
| connected | bool | True when text field gains focus, false when loses focus |

**Example**:
```kotlin
methodChannel.invokeMethod("connectionStatus", mapOf("connected" to true))
```

---

### displayModeChanged

Notify Flutter when rendering mode changes (new method).

**Method**: `displayModeChanged`

| Parameter | Type | Description |
|-----------|------|-------------|
| mode | String | One of: `secondary`, `primary_fallback` |
| displayWidth | int | Current display width |
| displayHeight | int | Current display height |

**Example**:
```kotlin
methodChannel.invokeMethod("displayModeChanged", mapOf(
    "mode" to "secondary",
    "displayWidth" to 800,
    "displayHeight" to 480
))
```

---

## Direction: Flutter (Launcher) → Native

These methods are used by the launcher app, not the keyboard.

### isImeEnabled

Check if TeleDeck is enabled in system keyboard settings.

**Method**: `isImeEnabled`

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| (none) | - | - | - |

**Returns**: `bool` - true if enabled in settings

---

### isImeActive

Check if TeleDeck is the currently active keyboard.

**Method**: `isImeActive`

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| (none) | - | - | - |

**Returns**: `bool` - true if currently selected as active IME

---

### openImeSettings

Open Android keyboard settings screen.

**Method**: `openImeSettings`

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| (none) | - | - | - |

**Returns**: `void`

---

### getCrashLogs

Retrieve list of crash log entries.

**Method**: `getCrashLogs`

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| (none) | - | - | - |

**Returns**: `List<Map<String, dynamic>>` - List of crash log entries

**Return Format**:
```dart
[
  {
    "id": "crash_1704499200000",
    "timestamp": "2025-01-05T12:00:00Z",
    "errorType": "FlutterError",
    "message": "Failed to initialize FlutterEngine"
  },
  // ...
]
```

---

### getCrashLogDetail

Get full details of a specific crash log.

**Method**: `getCrashLogDetail`

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | String | Yes | Crash log ID |

**Returns**: `Map<String, dynamic>` - Full crash log entry including stack trace

---

### clearCrashLogs

Delete all crash logs.

**Method**: `clearCrashLogs`

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| (none) | - | - | - |

**Returns**: `bool` - true if successful

---

## Error Handling

All methods may throw `PlatformException` with these codes:

| Code | Description |
|------|-------------|
| `NO_CONNECTION` | No active input connection |
| `ENGINE_NOT_READY` | Flutter engine not initialized |
| `INVALID_ARGUMENT` | Missing or invalid parameter |
| `INTERNAL_ERROR` | Unexpected native error |

**Example**:
```dart
try {
  await imeChannel.invokeMethod('commitText', {'text': 'a'});
} on PlatformException catch (e) {
  if (e.code == 'NO_CONNECTION') {
    // Handle no text field focused
  }
}
```
