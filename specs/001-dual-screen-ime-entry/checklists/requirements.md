# Requirements Checklist: Dual-Screen IME Entry Point Separation

**Feature Branch**: `001-dual-screen-ime-entry`
**Generated**: 2025-01-05

## Functional Requirements

- [ ] **FR-001**: IME service initializes via `@pragma('vm:entry-point') void imeMain()` entry point
- [ ] **FR-002**: IME service detects secondary displays via `DisplayManager.getDisplays()` during `onCreate()`
- [ ] **FR-003**: IME service renders keyboard on secondary display using Presentation API
- [ ] **FR-004**: IME service returns 0-height input view to primary display when rendering on secondary
- [ ] **FR-005**: IME service falls back to standard input view rendering when no secondary display exists
- [ ] **FR-006**: IME service registers `DisplayManager.DisplayListener` for dynamic display changes
- [ ] **FR-007**: IME service handles `onDisplayAdded`/`onDisplayRemoved` events without crashing
- [ ] **FR-008**: App launcher displays setup guide when IME is not enabled
- [ ] **FR-009**: App launcher does NOT display keyboard UI - only configuration and status
- [ ] **FR-010**: MethodChannel `tele_deck/ime` is used for Flutter-to-native communication
- [ ] **FR-011**: All text input flows through standard Android `InputConnection` API

## User Stories Acceptance

### US1 - IME Service Activation (P1)

- [ ] TeleDeck appears in Android keyboard settings without errors
- [ ] IME service starts and responds to input focus events
- [ ] Keyboard UI renders on text field focus

### US2 - Dual-Screen Keyboard Display (P1)

- [ ] Keyboard renders on secondary display via Presentation API
- [ ] Text appears in focused field when typing on secondary keyboard
- [ ] Primary display has no visual obstruction (0-height input view)

### US3 - Single-Screen Fallback (P2)

- [ ] Keyboard renders in standard input view when no secondary display
- [ ] Text input functions correctly in fallback mode

### US4 - Dynamic Display Switching (P2)

- [ ] Keyboard relocates to secondary on display connect
- [ ] Keyboard relocates to primary on display disconnect without crash
- [ ] No ANR or crash during display transition

### US5 - Launcher Setup Guide (P3)

- [ ] Setup guide displayed when IME not enabled
- [ ] "Open Keyboard Settings" opens Android settings
- [ ] Settings/status view shown when IME already enabled

## Success Criteria

- [ ] **SC-001**: IME activates without crash 100% of attempts
- [ ] **SC-002**: Keyboard renders on secondary within 500ms
- [ ] **SC-003**: Primary shows 0-height input view
- [ ] **SC-004**: Display disconnect causes 0 crashes
- [ ] **SC-005**: `flutter analyze` passes with no errors
- [ ] **SC-006**: `flutter build apk --debug` succeeds

## Constitution Compliance

- [ ] Principle I (System IME Architecture): Keyboard renders via Presentation API, 0-height on primary
- [ ] Principle II (Cyberpunk Aesthetic): UI maintains neon cyan/magenta color scheme
- [ ] Principle III (Multi-Display Awareness): Dynamic display detection and graceful disconnect handling
- [ ] Principle IV (Physical Button Integration): Intent receivers remain functional
- [ ] Principle V (Keyboard Feature Completeness): 6-row Magic Keyboard layout preserved
