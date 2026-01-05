<!--
  Sync Impact Report
  ==================
  Version change: 1.1.0 → 1.2.0

  Modified principles:
  - Platform Requirements: Upgraded flutter_bloc from v8.x to v9.x
  - Platform Requirements: Added form_bloc + flutter_form_bloc for forms
  - Package Structure: Added third_party/ directory

  Added sections:
  - third_party packages (form_bloc, flutter_form_bloc)

  Removed sections: None

  Templates requiring updates:
  - .specify/templates/plan-template.md - ✅ No changes needed (generic template)
  - .specify/templates/spec-template.md - ✅ No changes needed (generic template)
  - .specify/templates/tasks-template.md - ✅ No changes needed (generic template)

  Follow-up TODOs: None
-->

# TeleDeck Constitution

## Core Principles

### I. System IME Architecture

TeleDeck operates as a System-Level Input Method Service (IME), not a standalone application.

- The keyboard MUST render on secondary displays via Android Presentation API
- Primary display MUST receive 0-height input view to avoid blocking host applications
- All text input MUST flow through standard Android `InputConnection` API
- MethodChannel (`tele_deck/ime`) MUST be used for Flutter-to-native communication
- The app launcher activity serves ONLY as settings/onboarding, never as keyboard UI

**Rationale**: System IME architecture enables TeleDeck to work as a keyboard for ANY app on the device, not just within its own process.

### II. Preserve Cyberpunk Aesthetic

The keyboard UI MUST maintain its distinctive Cyberpunk visual identity.

- Color scheme: Dark background (`0xFF0D0D0D`), neon cyan (`0xFF00F5FF`), neon magenta (`0xFFFF00FF`)
- Typography: Monospace fonts (JetBrains Mono, Roboto Mono) with letter-spacing
- Visual effects: Glow animations, gradient borders, pulsing indicators
- Key styling: Rounded corners with neon border highlights on press/active states

**Rationale**: Visual identity differentiates TeleDeck from generic keyboards and provides consistent brand recognition.

### III. Multi-Display Awareness

TeleDeck MUST gracefully handle dynamic display configurations.

- MUST detect secondary displays via `DisplayManager` at runtime
- MUST respond to `onDisplayAdded`/`onDisplayRemoved` events
- MUST persist keyboard rotation preference per-display orientation
- MUST NOT crash when secondary display disconnects mid-session
- Settings MUST auto-refresh (via periodic `SharedPreferences.reload()`) for cross-engine sync

**Rationale**: Dual-screen devices like Ayaneo Pocket DS may connect/disconnect displays dynamically.

### IV. Physical Button Integration

External physical button bindings MUST remain functional.

- BroadcastReceiver MUST handle: `TOGGLE_KEYBOARD`, `SHOW_KEYBOARD`, `HIDE_KEYBOARD` intents
- Intent namespace: `app.gsmlg.tele_deck.*`
- Actions MUST work regardless of host app focus
- IME service MUST expose toggle methods accessible from broadcast receiver

**Rationale**: Gaming handhelds rely on physical button mappings for quick keyboard access.

### V. Keyboard Feature Completeness

The virtual keyboard MUST provide full input capability.

- 6-row Magic Keyboard layout: F1-F12, modifiers (Ctrl/Alt/Super/Fn), arrows
- Shift key: Tap to toggle, long-press to lock
- Fn key: Tap toggles F-row media functions, long-press opens mode selector
- Three keyboard modes: Standard QWERTY, Numpad+Navigation, Emoji
- All punctuation keys MUST show shifted variants visually

**Rationale**: TeleDeck replaces the system keyboard entirely; incomplete functionality forces users back to alternatives.

### VI. Monorepo Architecture

TeleDeck MUST maintain a Melos-managed monorepo structure with clear package boundaries.

- Package categories MUST be organized as:
  - `app_lib/` - Core library packages (theme, models, services, logging, constants)
  - `app_bloc/` - BLoC state management packages (keyboard_bloc, settings_bloc, setup_bloc)
  - `app_widget/` - UI component packages (keyboard_widgets, settings_widgets, common_widgets)
- Entry points (`lib/main.dart`, `lib/main_ime.dart`) MUST only bootstrap and wire packages
- Packages MUST have explicit dependencies declared in their `pubspec.yaml`
- Cross-package imports MUST follow the dependency hierarchy: app_lib → app_bloc → app_widget
- State management MUST use flutter_bloc for all user-facing state

**Rationale**: Monorepo architecture enables better separation of concerns, faster incremental builds, and clearer ownership boundaries for each feature domain.

## Platform Requirements

**Target**: Android 8.0+ (API 26+) with secondary display support

**Technology Stack**:
- Framework: Flutter 3.x / Dart 3.8+
- State Management: flutter_bloc v9.x (BLoC pattern)
- Forms: form_bloc + flutter_form_bloc
- Workspace: Melos for monorepo management
- Native: Kotlin (InputMethodService, Presentation API)
- Persistence: shared_preferences (cross-engine compatible)
- Typography: google_fonts (JetBrains Mono, Roboto Mono)

**Package Structure**:
```
tele_deck/
├── lib/                    # Entry points only
│   ├── main.dart           # Launcher app (settings/setup)
│   └── main_ime.dart       # IME keyboard entry point
├── app_lib/                # Core library packages
│   ├── tele_theme/         # TeleDeckColors, TeleDeckTheme
│   ├── tele_models/        # AppSettings, DisplayState, SetupGuideState
│   ├── tele_services/      # SettingsService, ImeChannelService
│   ├── tele_logging/       # CrashLogEntry, CrashLogService
│   └── tele_constants/     # IPC constants, KeyboardLayout, DisplayMode
├── app_bloc/               # BLoC state management
│   ├── keyboard_bloc/      # Keyboard state (modifiers, mode, connection)
│   ├── settings_bloc/      # Settings persistence
│   └── setup_bloc/         # IME onboarding flow
├── app_widget/             # UI components
│   ├── keyboard_widgets/   # KeyboardView, KeyboardKey, layouts
│   ├── settings_widgets/   # SettingsView, SetupGuideView
│   └── common_widgets/     # CrashLogViewer, shared widgets
├── third_party/            # Third-party packages (forked)
│   ├── form_bloc/          # Form state management
│   └── flutter_form_bloc/  # Flutter form widgets
└── android/                # Native Kotlin code
```

**Build Verification**:
- `melos bootstrap` MUST succeed for workspace setup
- `flutter analyze` MUST pass with no errors (warnings/info acceptable)
- `flutter build apk --debug` MUST succeed before any PR merge
- Kotlin code MUST compile without errors

## Development Workflow

### Code Review Requirements

- All PRs MUST verify IME functionality on a device with secondary display (emulator acceptable for layout-only changes)
- Changes to `TeleDeckIMEService.kt` require manual testing
- Keyboard rotation settings MUST be tested when modifying keyboard_widgets
- BLoC changes MUST include verification that state transitions work correctly

### Testing Gates

- Unit tests: Optional but encouraged for BLoC logic and pure Dart functions
- Integration tests: Required for MethodChannel communication changes
- Manual validation: Required for any UI/UX changes visible to users

### Commit Standards

- Use semantic commit messages: `feat:`, `fix:`, `refactor:`, `docs:`
- Reference relevant principles if architectural decisions are made
- Package-specific changes should mention package name: `feat(keyboard_bloc):`

## Governance

This Constitution supersedes all other practices for TeleDeck development.

**Amendment Process**:
1. Propose change in a dedicated PR with rationale
2. Update constitution version according to semantic versioning:
   - MAJOR: Principle removal or incompatible redefinition
   - MINOR: New principle or material expansion
   - PATCH: Clarification or wording refinement
3. Update dependent templates if principle names/scopes change
4. Document migration steps if breaking changes affect existing code

**Compliance Review**:
- All PRs MUST be reviewed against applicable principles
- Violations require explicit justification in Complexity Tracking (see plan-template.md)

**Version**: 1.2.0 | **Ratified**: 2025-01-05 | **Last Amended**: 2025-01-05
