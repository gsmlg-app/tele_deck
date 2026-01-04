# Data Model: Dual-Screen IME Entry Point Separation

**Feature**: 001-dual-screen-ime-entry
**Date**: 2025-01-05

## Entities

### 1. DisplayState

Represents the current display configuration detected by the IME service.

| Field | Type | Description |
|-------|------|-------------|
| hasSecondaryDisplay | Boolean | True if a secondary display is connected |
| secondaryDisplayId | Int? | Display ID of secondary (null if none) |
| primaryWidth | Int | Primary display width in pixels |
| primaryHeight | Int | Primary display height in pixels |
| secondaryWidth | Int? | Secondary display width (null if none) |
| secondaryHeight | Int? | Secondary display height (null if none) |

**State Transitions**:
- `NO_DISPLAY` → `SECONDARY_CONNECTED`: On `onDisplayAdded` event
- `SECONDARY_CONNECTED` → `NO_DISPLAY`: On `onDisplayRemoved` event

**Validation Rules**:
- `secondaryDisplayId` must be > 0 when `hasSecondaryDisplay` is true
- `secondaryWidth`/`secondaryHeight` must be non-null when `hasSecondaryDisplay` is true

---

### 2. CrashLogEntry

Represents a single crash log entry persisted to local storage.

| Field | Type | Description |
|-------|------|-------------|
| id | String | Unique identifier (timestamp-based) |
| timestamp | DateTime | When the crash occurred |
| errorType | String | Exception class name |
| message | String | Error message |
| stackTrace | String | Full stack trace |
| displayState | DisplayState | Display config at crash time |
| engineState | String | Flutter engine state (running/stopped) |

**Validation Rules**:
- `timestamp` must not be in the future
- `id` format: `crash_<timestamp_millis>.log`
- Auto-delete entries older than 7 days

**Storage Format**: JSON file per entry in `app_data/crash_logs/`

---

### 3. ImeStatus

Represents the current IME service state communicated to Flutter.

| Field | Type | Description |
|-------|------|-------------|
| isEnabled | Boolean | IME enabled in system settings |
| isActive | Boolean | Currently the active keyboard |
| hasInputConnection | Boolean | Currently focused on a text field |
| renderingMode | Enum | `SECONDARY_DISPLAY` or `PRIMARY_FALLBACK` |

**State Transitions**:
- `DISABLED` → `ENABLED`: User enables in Android Settings
- `ENABLED` → `ACTIVE`: User switches to TeleDeck as active IME
- `ACTIVE` + `hasInputConnection=true`: Text field focused
- `ACTIVE` + render mode changes: Display connected/disconnected

---

### 4. SetupGuideState

Represents the onboarding/setup guide state in the launcher.

| Field | Type | Description |
|-------|------|-------------|
| currentStep | Int | Current step in setup flow (1-3) |
| imeEnabled | Boolean | Cached IME enabled status |
| imeActive | Boolean | Cached IME active status |

**Steps**:
1. Enable TeleDeck in keyboard settings
2. Switch to TeleDeck as active keyboard
3. Setup complete - show settings

---

## Relationships

```text
┌─────────────────────┐
│  TeleDeckIMEService │
│  (Kotlin)           │
├─────────────────────┤
│ - displayState      │──────┐
│ - imeStatus         │      │
│ - crashLogs[]       │      │
└─────────────────────┘      │
         │                   │
         │ MethodChannel     │
         ▼                   │
┌─────────────────────┐      │
│  Flutter UI         │      │
│  (main_ime.dart)    │      │
├─────────────────────┤      │
│ - receives          │◄─────┘
│   displayState      │
│ - receives          │
│   imeStatus         │
└─────────────────────┘

┌─────────────────────┐
│  Launcher App       │
│  (main.dart)        │
├─────────────────────┤
│ - setupGuideState   │
│ - queries imeStatus │
│ - views crashLogs[] │
└─────────────────────┘
```

## Data Flow

1. **IME Service → Flutter (Keyboard)**
   - `connectionStatus`: Sent when text field focus changes
   - `displayMode`: Sent when rendering mode changes

2. **Flutter (Keyboard) → IME Service**
   - `commitText`: Send typed character
   - `backspace`, `delete`, `enter`, `tab`: Special keys
   - `moveCursor`: Arrow key navigation
   - `sendKeyEvent`: Raw key event with modifiers

3. **Launcher ↔ Native**
   - `isImeEnabled`: Query if IME is enabled in settings
   - `openImeSettings`: Launch Android keyboard settings
   - `getCrashLogs`: Retrieve crash log list
   - `clearCrashLogs`: Delete all crash logs

## File Storage Schema

```text
/data/data/app.gsmlg.tele_deck/
├── files/
│   └── crash_logs/
│       ├── crash_1704499200000.log   # JSON format
│       ├── crash_1704585600000.log
│       └── ...
└── shared_prefs/
    └── FlutterSharedPreferences.xml  # Existing settings
```

### Crash Log File Format

```json
{
  "id": "crash_1704499200000",
  "timestamp": "2025-01-05T12:00:00Z",
  "errorType": "FlutterError",
  "message": "Failed to initialize FlutterEngine",
  "stackTrace": "...",
  "displayState": {
    "hasSecondaryDisplay": true,
    "secondaryDisplayId": 2,
    "primaryWidth": 1080,
    "primaryHeight": 2400,
    "secondaryWidth": 800,
    "secondaryHeight": 480
  },
  "engineState": "stopped"
}
```
