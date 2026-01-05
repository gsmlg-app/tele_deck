# Feature Specification: Dual-Screen IME Entry Point Separation

**Feature Branch**: `001-dual-screen-ime-entry`
**Created**: 2025-01-05
**Status**: Draft
**Input**: Refactoring to separate Config UI (Launcher) from Keyboard UI (IME Service)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - IME Service Activation (Priority: P1)

As a user, I want to enable TeleDeck as my system keyboard through Android Settings so that I can use it as my input method in any application.

**Why this priority**: This is the foundational capability - without IME activation, no other features work. The system must be recognized as a valid input method.

**Independent Test**: Can be fully tested by navigating to Android Settings > Language & Input > On-screen keyboard, enabling TeleDeck, and switching to it as the active keyboard. Success means the IME service starts without crash.

**Acceptance Scenarios**:

1. **Given** TeleDeck is installed but not enabled, **When** user navigates to Android keyboard settings and enables TeleDeck, **Then** TeleDeck appears in the list of available keyboards without errors.
2. **Given** TeleDeck is enabled, **When** user switches to TeleDeck as active keyboard, **Then** the IME service starts and responds to input focus events.
3. **Given** TeleDeck IME is active, **When** user taps any text field in any app, **Then** the keyboard UI renders (location depends on display availability).

---

### User Story 2 - Dual-Screen Keyboard Display (Priority: P1)

As a user with a dual-screen device (Ayaneo Pocket DS), I want the keyboard to render on my secondary display while the primary display remains unobstructed, so I can see the full app while typing.

**Why this priority**: This is the core differentiating feature of TeleDeck - rendering on secondary display. Equal priority to US1 as it's the primary use case.

**Independent Test**: On a dual-screen device, focus on a text field. Keyboard should appear on secondary display only. Primary display should have 0-height input view.

**Acceptance Scenarios**:

1. **Given** a secondary display is connected and TeleDeck is the active IME, **When** user focuses on a text input field, **Then** keyboard renders via Presentation API on the secondary display.
2. **Given** keyboard is showing on secondary display, **When** user types on the virtual keyboard, **Then** text appears in the focused text field on primary display.
3. **Given** keyboard is showing on secondary display, **When** user observes primary display, **Then** no keyboard overlay or system input view blocks the app content (0-height input view).

---

### User Story 3 - Single-Screen Fallback (Priority: P2)

As a user without a secondary display, I want the keyboard to render on the primary screen so I can still use TeleDeck as a functional keyboard.

**Why this priority**: Important for broader device compatibility, but secondary to the dual-screen experience which is the product's core value.

**Independent Test**: On a single-screen device (or with secondary disconnected), focus on a text field. Keyboard should render as standard bottom-sheet on primary display.

**Acceptance Scenarios**:

1. **Given** no secondary display is detected and TeleDeck is active, **When** user focuses on text input, **Then** keyboard renders in the standard input view area on primary display.
2. **Given** keyboard is showing on primary display in fallback mode, **When** user types, **Then** text input functions correctly.

---

### User Story 4 - Dynamic Display Switching (Priority: P2)

As a user, I want the keyboard to gracefully handle when my secondary display connects or disconnects mid-session, switching between dual-screen and single-screen modes without crashing.

**Why this priority**: Important for real-world usage where display connections may change, but not blocking for MVP.

**Independent Test**: With keyboard active, connect/disconnect secondary display. Keyboard should transition smoothly without crashes.

**Acceptance Scenarios**:

1. **Given** keyboard is showing on primary display (no secondary), **When** secondary display is connected, **Then** keyboard relocates to secondary display on next input focus.
2. **Given** keyboard is showing on secondary display, **When** secondary display is disconnected, **Then** keyboard relocates to primary display without crashing.
3. **Given** display transition occurs, **When** IME service detects change via DisplayManager callback, **Then** no ANR or crash occurs during transition.

---

### User Story 5 - Launcher Setup Guide (Priority: P3)

As a new user, I want to launch the TeleDeck app and see a clear setup guide explaining how to enable it as my keyboard, so I can complete initial configuration.

**Why this priority**: Quality-of-life feature for onboarding. The core keyboard works without this - users can navigate to system settings manually.

**Independent Test**: Launch TeleDeck app icon. Should show setup instructions with steps to enable IME, not a keyboard UI.

**Acceptance Scenarios**:

1. **Given** TeleDeck is not enabled as an IME, **When** user launches the app, **Then** a setup guide is displayed with clear instructions to enable TeleDeck in system settings.
2. **Given** user is viewing setup guide, **When** user taps "Open Keyboard Settings", **Then** Android's keyboard settings screen opens.
3. **Given** TeleDeck is already enabled, **When** user launches app, **Then** app shows settings/status view (not keyboard UI).

---

### Edge Cases

- What happens when user has multiple secondary displays? → Use first detected display (Display ID priority)
- How does system handle Flutter engine initialization failure on secondary display? → Fall back to primary display, show system notification with link to logs, log error to persistent crash log
- What happens if `onCreateInputView` is called before display detection completes? → Return 0-height view, re-evaluate on first `showInputView` call
- How does system handle rapid connect/disconnect of secondary display? → Debounce display events, minimum 500ms between transitions

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: IME service MUST initialize via `@pragma('vm:entry-point') void imeMain()` entry point in `lib/main_ime.dart`
- **FR-002**: IME service MUST detect secondary displays via `DisplayManager.getDisplays()` during `onCreate()`
- **FR-003**: IME service MUST render keyboard on secondary display using Android Presentation API when secondary display is available
- **FR-004**: IME service MUST return 0-height input view to primary display when rendering on secondary
- **FR-005**: IME service MUST fall back to standard input view rendering when no secondary display exists (max 50% screen height)
- **FR-006**: IME service MUST register `DisplayManager.DisplayListener` for dynamic display changes
- **FR-007**: IME service MUST handle `onDisplayAdded`/`onDisplayRemoved` events without crashing
- **FR-008**: App launcher (`lib/main.dart`) MUST display setup guide when IME is not enabled
- **FR-009**: App launcher MUST NOT display keyboard UI - only configuration and status
- **FR-010**: MethodChannel `tele_deck/ime` MUST be used for Flutter-to-native communication
- **FR-011**: All text input MUST flow through standard Android `InputConnection` API
- **FR-012**: IME service MUST show Android system notification on crash/error with deep link to log viewer
- **FR-013**: App launcher MUST include a crash/error log viewer module accessible from settings menu
- **FR-014**: Crash logs MUST be persisted locally (7-day retention, auto-cleanup) and viewable without internet connection

### Key Entities

- **TeleDeckIMEService**: Kotlin InputMethodService handling IME lifecycle, display detection, and Flutter engine management
- **VirtualKeyboardPresentation**: Kotlin Presentation subclass for rendering Flutter keyboard on secondary display
- **ImeMain**: Dart entry point (`lib/main_ime.dart`) containing keyboard UI and state management
- **AppMain**: Dart entry point (`lib/main.dart`) containing setup guide and settings UI
- **DisplayState**: Represents current display configuration (hasSecondary, activeDisplayId, displayMetrics)

## Clarifications

### Session 2025-01-05

- Q: When keyboard crashes on secondary display, what should user see? → A: System notification with link to logs; app includes crash log viewer module.
- Q: Single-screen fallback keyboard height constraint? → A: Maximum 50% of screen height.
- Q: Crash log retention period? → A: 7 days with automatic cleanup.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: IME service activates without crash in Android Settings on 100% of attempts
- **SC-002**: Keyboard renders on secondary display within 500ms of text field focus when secondary is connected
- **SC-003**: Primary display shows 0-height input view (no visual obstruction) when keyboard is on secondary
- **SC-004**: Display disconnect during active keyboard session causes 0 crashes (graceful fallback)
- **SC-005**: `flutter analyze` passes with no errors for all Dart code changes
- **SC-006**: `flutter build apk --debug` succeeds without Kotlin compilation errors
