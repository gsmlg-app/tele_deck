<!--
  Sync Impact Report
  ==================
  Version change: 0.0.0 → 1.0.0

  Modified principles: N/A (initial constitution)

  Added sections:
  - Core Principles (5 principles)
  - Platform Requirements
  - Development Workflow
  - Governance

  Removed sections: N/A (initial constitution)

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

- Color scheme: Dark background (`0xFF0D1117`), neon cyan (`0xFF00D9FF`), neon magenta (`0xFFFF006E`)
- Typography: Monospace fonts (Roboto Mono) with letter-spacing
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

## Platform Requirements

**Target**: Android 8.0+ (API 26+) with secondary display support

**Technology Stack**:
- Framework: Flutter 3.10+ / Dart 3.0+
- State Management: flutter_riverpod v2
- Native: Kotlin (InputMethodService, Presentation API)
- Persistence: shared_preferences (cross-engine compatible)

**Build Verification**:
- `flutter analyze` MUST pass with no errors (warnings/info acceptable)
- `flutter build apk --debug` MUST succeed before any PR merge
- Kotlin code MUST compile without errors

## Development Workflow

### Code Review Requirements

- All PRs MUST verify IME functionality on a device with secondary display (emulator acceptable for layout-only changes)
- Changes to `TeleDeckIMEService.kt` or `VirtualKeyboardPresentation.kt` require manual testing
- Keyboard rotation settings MUST be tested when modifying `keyboard_view.dart`

### Testing Gates

- Unit tests: Optional but encouraged for pure Dart logic
- Integration tests: Required for MethodChannel communication changes
- Manual validation: Required for any UI/UX changes visible to users

### Commit Standards

- Use semantic commit messages: `feat:`, `fix:`, `refactor:`, `docs:`
- Reference relevant principles if architectural decisions are made

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

**Version**: 1.0.0 | **Ratified**: 2025-01-05 | **Last Amended**: 2025-01-05
