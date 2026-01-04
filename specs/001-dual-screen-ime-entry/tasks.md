# Tasks: Dual-Screen IME Entry Point Separation

**Input**: Design documents from `/specs/001-dual-screen-ime-entry/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Tests are NOT explicitly requested. Manual testing via quickstart.md is the primary validation method.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Dart code**: `lib/`
- **Kotlin code**: `android/app/src/main/kotlin/app/gsmlg/tele_deck/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and verification

- [x] T001 Verify current project compiles with `flutter build apk --debug`
- [x] T002 [P] Run `flutter analyze` to establish baseline (fix any blocking errors)
- [x] T003 [P] Create directory structure for new files: `lib/logging/`, `lib/logging/views/`, `lib/settings/views/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Create `lib/main_ime.dart` with `@pragma('vm:entry-point') void imeMain()` entry point (copy keyboard UI from current main.dart)
- [x] T005 Add MethodChannel constants and providers in `lib/shared/constants.dart` for IME communication
- [x] T006 Create DisplayState model in `lib/shared/display_state.dart` per data-model.md
- [x] T007 Create CrashLogEntry model in `lib/logging/crash_log_entry.dart` per data-model.md
- [x] T008 Create CrashLogService in `lib/logging/crash_log_service.dart` with file-based persistence and 7-day cleanup

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - IME Service Activation (Priority: P1) 🎯 MVP

**Goal**: Enable TeleDeck as system keyboard through Android Settings

**Independent Test**: Navigate to Android Settings > Language & Input > On-screen keyboard, enable TeleDeck, switch to it. IME service starts without crash.

### Implementation for User Story 1

- [x] T009 [US1] Update `TeleDeckIMEService.kt` to use custom Dart entrypoint `imeMain` in `android/app/src/main/kotlin/app/gsmlg/tele_deck/TeleDeckIMEService.kt`
- [x] T010 [US1] Add `isImeEnabled` and `isImeActive` MethodChannel handlers in `TeleDeckIMEService.kt` per contracts/method-channel.md
- [x] T011 [US1] Add `openImeSettings` MethodChannel handler in `MainActivity.kt` in `android/app/src/main/kotlin/app/gsmlg/tele_deck/MainActivity.kt`
- [x] T012 [US1] Update `lib/main_ime.dart` to handle `connectionStatus` and `displayModeChanged` callbacks from native
- [ ] T013 [US1] Verify IME appears in Android keyboard list and can be enabled (manual test)

**Checkpoint**: User Story 1 complete - IME can be enabled and activated

---

## Phase 4: User Story 2 - Dual-Screen Keyboard Display (Priority: P1) 🎯 MVP

**Goal**: Render keyboard on secondary display while primary shows 0-height view

**Independent Test**: On dual-screen device, focus text field. Keyboard appears on secondary display only, primary unobstructed.

### Implementation for User Story 2

- [x] T014 [US2] Update `TeleDeckIMEService.kt` to detect secondary display in `onCreate()` via `DisplayManager.getDisplays()` in `android/app/src/main/kotlin/app/gsmlg/tele_deck/TeleDeckIMEService.kt`
- [x] T015 [US2] Update `onCreateInputView()` in `TeleDeckIMEService.kt` to return 0-height FrameLayout when secondary display exists
- [x] T016 [US2] Add `displayModeChanged` MethodChannel invocation when switching to secondary display in `TeleDeckIMEService.kt`
- [x] T017 [US2] Update `VirtualKeyboardPresentation.kt` to use `imeMain` entrypoint in `android/app/src/main/kotlin/app/gsmlg/tele_deck/VirtualKeyboardPresentation.kt`
- [ ] T018 [US2] Verify keyboard renders on secondary display with 0-height on primary (manual test on Ayaneo Pocket DS or emulator)

**Checkpoint**: User Story 2 complete - Dual-screen mode fully functional

---

## Phase 5: User Story 3 - Single-Screen Fallback (Priority: P2)

**Goal**: Render keyboard on primary display when no secondary exists (max 50% height)

**Independent Test**: On single-screen device, focus text field. Keyboard appears on primary display at max 50% screen height.

### Implementation for User Story 3

- [x] T019 [US3] Create `createPrimaryFlutterView()` method in `TeleDeckIMEService.kt` that embeds FlutterView with 50% max height in `android/app/src/main/kotlin/app/gsmlg/tele_deck/TeleDeckIMEService.kt`
- [x] T020 [US3] Update `onCreateInputView()` to call `createPrimaryFlutterView()` when no secondary display in `TeleDeckIMEService.kt`
- [x] T021 [US3] Add `displayModeChanged` MethodChannel invocation with `primary_fallback` mode in `TeleDeckIMEService.kt`
- [ ] T022 [US3] Verify keyboard renders on primary with correct height constraint (manual test)

**Checkpoint**: User Story 3 complete - Single-screen fallback works

---

## Phase 6: User Story 4 - Dynamic Display Switching (Priority: P2)

**Goal**: Gracefully handle display connect/disconnect mid-session

**Independent Test**: With keyboard active, connect/disconnect secondary display. Keyboard transitions smoothly without crash.

### Implementation for User Story 4

- [x] T023 [US4] Add 500ms debounce logic using `Handler.postDelayed()` for display events in `TeleDeckIMEService.kt` in `android/app/src/main/kotlin/app/gsmlg/tele_deck/TeleDeckIMEService.kt`
- [x] T024 [US4] Update `onDisplayAdded` to debounce and trigger keyboard relocation to secondary in `TeleDeckIMEService.kt`
- [x] T025 [US4] Update `onDisplayRemoved` to debounce and gracefully fall back to primary in `TeleDeckIMEService.kt`
- [x] T026 [US4] Add null-safety checks in `hideKeyboardPresentation()` to prevent crash on rapid disconnect in `TeleDeckIMEService.kt`
- [ ] T027 [US4] Verify no crash on rapid display connect/disconnect (manual stress test)

**Checkpoint**: User Story 4 complete - Dynamic switching works safely

---

## Phase 7: User Story 5 - Launcher Setup Guide (Priority: P3)

**Goal**: Show setup guide when app launches, not keyboard UI

**Independent Test**: Launch TeleDeck app. See setup instructions if IME not enabled, settings view if already enabled.

### Implementation for User Story 5

- [x] T028 [P] [US5] Create SetupGuideState model in `lib/settings/setup_guide_state.dart` per data-model.md
- [x] T029 [P] [US5] Create SetupGuideView widget in `lib/settings/views/setup_guide_view.dart` with 3-step flow
- [x] T030 [US5] Add `isImeEnabled` and `openImeSettings` MethodChannel calls in `lib/settings/settings_provider.dart`
- [x] T031 [US5] Refactor `lib/main.dart` to show SetupGuideView or SettingsView based on IME status (remove keyboard UI)
- [x] T032 [US5] Add navigation from setup guide to settings when IME is enabled in `lib/main.dart`
- [ ] T033 [US5] Verify launcher shows correct view based on IME status (manual test)

**Checkpoint**: User Story 5 complete - Launcher shows appropriate content

---

## Phase 8: Crash Logging (Cross-Cutting - FR-012, FR-013, FR-014)

**Purpose**: Crash notification and log viewer functionality

- [x] T034 [P] Add crash logging calls in `TeleDeckIMEService.kt` try-catch blocks in `android/app/src/main/kotlin/app/gsmlg/tele_deck/TeleDeckIMEService.kt`
- [x] T035 [P] Add crash notification with deep link in `TeleDeckIMEService.kt` using `NotificationCompat` in `android/app/src/main/kotlin/app/gsmlg/tele_deck/TeleDeckIMEService.kt`
- [x] T036 Add `getCrashLogs`, `getCrashLogDetail`, `clearCrashLogs` MethodChannel handlers in `MainActivity.kt` in `android/app/src/main/kotlin/app/gsmlg/tele_deck/MainActivity.kt`
- [x] T037 Create CrashLogViewer widget in `lib/logging/views/crash_log_viewer.dart` with list and detail views
- [x] T038 Add crash log viewer navigation from settings in `lib/settings/views/settings_view.dart`
- [x] T039 Handle `VIEW_CRASH_LOGS` intent deep link in `lib/main.dart` to open crash log viewer

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Final validation and cleanup

- [x] T040 Run `flutter analyze` and fix any new errors in all Dart files
- [x] T041 Run `flutter build apk --debug` to verify complete build in project root
- [ ] T042 Execute all quickstart.md test scenarios (manual validation)
- [ ] T043 Update checklists/requirements.md with completed items in `specs/001-dual-screen-ime-entry/checklists/requirements.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-7)**: All depend on Foundational phase completion
  - US1 and US2 are both P1 and can run in parallel after Phase 2
  - US3 depends on US2 (uses same display detection logic)
  - US4 depends on US2 (extends display handling)
  - US5 is independent after Phase 2
- **Crash Logging (Phase 8)**: Can run after US1 is complete (needs IME service)
- **Polish (Phase 9)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 3 (P2)**: Depends on US2 completion (uses same `TeleDeckIMEService.kt` methods)
- **User Story 4 (P2)**: Depends on US2 completion (extends `DisplayManager.DisplayListener`)
- **User Story 5 (P3)**: Can start after Foundational (Phase 2) - No dependencies on other stories

### Within Each User Story

- Models/entities before services
- Services before UI components
- Native code before Flutter code (when dependent)
- Core implementation before manual verification

### Parallel Opportunities

- T002, T003 can run in parallel (Setup phase)
- T028, T029 can run in parallel (US5 models and views)
- T034, T035 can run in parallel (crash logging native code)
- US1 and US2 can be worked on in parallel after Phase 2
- US5 can be worked on in parallel with US1/US2 after Phase 2

---

## Parallel Example: Phase 2 Foundation

```bash
# After T004 completes, these can run in parallel:
Task: "Add MethodChannel constants in lib/shared/constants.dart"
Task: "Create DisplayState model in lib/shared/display_state.dart"
Task: "Create CrashLogEntry model in lib/logging/crash_log_entry.dart"
```

## Parallel Example: User Story 5

```bash
# These can run in parallel:
Task: "Create SetupGuideState model in lib/settings/setup_guide_state.dart"
Task: "Create SetupGuideView widget in lib/settings/views/setup_guide_view.dart"
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (IME Activation)
4. Complete Phase 4: User Story 2 (Dual-Screen Display)
5. **STOP and VALIDATE**: Test dual-screen keyboard on Ayaneo Pocket DS
6. Deploy/demo if ready - this is the core product value

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add US1 + US2 → Test dual-screen mode → Deploy/Demo (MVP!)
3. Add US3 → Test single-screen fallback → Deploy/Demo
4. Add US4 → Test dynamic switching → Deploy/Demo
5. Add US5 → Test launcher UI → Deploy/Demo
6. Add Crash Logging → Full feature complete

### Solo Developer Strategy

1. Complete Setup and Foundational sequentially
2. Complete US1 → US2 → Test dual-screen (MVP checkpoint)
3. Complete US3 → US4 → Test display transitions
4. Complete US5 → Test launcher flow
5. Complete crash logging → Polish → Final validation

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Manual testing required after each story phase completion
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Primary focus: US1 + US2 form the MVP for dual-screen keyboard functionality
