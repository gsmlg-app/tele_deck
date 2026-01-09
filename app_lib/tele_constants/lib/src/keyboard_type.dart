/// Keyboard input type determines how key presses are sent to apps.
enum KeyboardType {
  /// IME mode: uses commitText for text input (standard IME behavior).
  /// Shift transforms characters client-side (a → A).
  ime,

  /// Physical mode: uses sendKeyEvent for all input.
  /// Simulates a hardware keyboard with raw key events and modifiers.
  physical,
}
