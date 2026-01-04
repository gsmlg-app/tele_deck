# Implementation Plan: Dual-Screen IME Entry Point Separation

**Branch**: `001-dual-screen-ime-entry` | **Date**: 2025-01-05 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-dual-screen-ime-entry/spec.md`

## Summary

Refactor TeleDeck to separate the Config UI (Launcher Activity) from the Keyboard UI (IME Service) by:
1. Creating a dedicated IME entry point (`lib/main_ime.dart`) with custom Dart entrypoint
2. Refactoring the launcher (`lib/main.dart`) to show setup guide instead of keyboard
3. Updating `TeleDeckIMEService.kt` to conditionally render on secondary display (dual-screen mode) or primary display (single-screen fallback)

## Technical Context

**Language/Version**: Dart 3.10+ / Kotlin (Android)
**Primary Dependencies**: Flutter 3.10+, flutter_riverpod v2, shared_preferences
**Storage**: shared_preferences for settings, file-based crash logs (7-day retention)
**Testing**: flutter test, manual IME testing on device
**Target Platform**: Android 8.0+ (API 26+)
**Project Type**: Mobile (Flutter + Android Native)
**Performance Goals**: Keyboard render within 500ms of text field focus
**Constraints**: Max 50% screen height for single-screen fallback mode
**Scale/Scope**: Single-user local app, 1 primary + 1 secondary display

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. System IME Architecture | ✅ PASS | Keyboard via Presentation API, 0-height on primary, InputConnection for text |
| II. Preserve Cyberpunk Aesthetic | ✅ PASS | Existing keyboard UI preserved, no visual changes in scope |
| III. Multi-Display Awareness | ✅ PASS | DisplayManager detection, dynamic add/remove handling, debounce |
| IV. Physical Button Integration | ✅ PASS | BroadcastReceiver pattern preserved |
| V. Keyboard Feature Completeness | ✅ PASS | Keyboard features unchanged, only entry point refactoring |

**Gate Result**: PASS - All principles satisfied.

## Project Structure

### Documentation (this feature)

```text
specs/001-dual-screen-ime-entry/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── method-channel.md
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
lib/
├── main.dart                      # MODIFY: Launcher with setup guide
├── main_ime.dart                  # NEW: IME entry point
├── keyboard_screen/
│   ├── keyboard_service.dart      # MODIFY: Use MethodChannel for IME
│   └── views/
│       ├── keyboard_view.dart     # EXISTING: Keyboard UI
│       └── keyboard_key.dart      # EXISTING: Key widget
├── settings/
│   ├── settings_model.dart        # EXISTING
│   ├── settings_service.dart      # EXISTING
│   ├── settings_provider.dart     # EXISTING
│   └── views/
│       ├── settings_view.dart     # EXISTING
│       └── setup_guide_view.dart  # NEW: IME setup instructions
├── logging/
│   ├── crash_log_service.dart     # NEW: Crash log persistence
│   └── views/
│       └── crash_log_viewer.dart  # NEW: Log viewer UI
└── shared/
    └── constants.dart             # EXISTING

android/app/src/main/kotlin/app/gsmlg/tele_deck/
├── TeleDeckIMEService.kt          # MODIFY: Dual-screen/single-screen logic
├── VirtualKeyboardPresentation.kt # EXISTING: Secondary display rendering
├── ToggleKeyboardReceiver.kt      # EXISTING: Physical button receiver
└── MainActivity.kt                # EXISTING: Launcher activity

test/
├── unit/
│   └── crash_log_service_test.dart
└── widget/
    └── setup_guide_test.dart
```

**Structure Decision**: Mobile + Native hybrid. Flutter handles UI (keyboard and launcher), Kotlin handles IME service lifecycle and display management.

## Complexity Tracking

> No constitution violations - section intentionally empty.
