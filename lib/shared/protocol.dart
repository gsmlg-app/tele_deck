// TeleDeck IPC Protocol
// Defines the event types for communication between screens

/// Sealed class for keyboard events
/// Uses simple Map serialization for performance over JSON libraries
sealed class KeyboardEvent {
  const KeyboardEvent();

  /// Serialize event to a Map for IPC transmission
  Map<String, dynamic> toMap();

  /// Deserialize event from Map
  static KeyboardEvent fromMap(Map<String, dynamic> map) {
    final type = map['type'] as String;
    return switch (type) {
      'key_down' => KeyDown(map['char'] as String),
      'key_up' => KeyUp(map['char'] as String),
      'backspace' => const Backspace(),
      'enter' => const Enter(),
      'space' => const Space(),
      'clear' => const Clear(),
      'shift' => Shift(map['enabled'] as bool),
      _ => throw ArgumentError('Unknown event type: $type'),
    };
  }
}

/// Key pressed event - character input
class KeyDown extends KeyboardEvent {
  final String char;

  const KeyDown(this.char);

  @override
  Map<String, dynamic> toMap() => {
        'type': 'key_down',
        'char': char,
      };

  @override
  String toString() => 'KeyDown($char)';
}

/// Key released event (optional, for future haptic/visual feedback)
class KeyUp extends KeyboardEvent {
  final String char;

  const KeyUp(this.char);

  @override
  Map<String, dynamic> toMap() => {
        'type': 'key_up',
        'char': char,
      };

  @override
  String toString() => 'KeyUp($char)';
}

/// Backspace command - delete last character
class Backspace extends KeyboardEvent {
  const Backspace();

  @override
  Map<String, dynamic> toMap() => {'type': 'backspace'};

  @override
  String toString() => 'Backspace()';
}

/// Enter command - submit/newline
class Enter extends KeyboardEvent {
  const Enter();

  @override
  Map<String, dynamic> toMap() => {'type': 'enter'};

  @override
  String toString() => 'Enter()';
}

/// Space command
class Space extends KeyboardEvent {
  const Space();

  @override
  Map<String, dynamic> toMap() => {'type': 'space'};

  @override
  String toString() => 'Space()';
}

/// Clear command - clear all text
class Clear extends KeyboardEvent {
  const Clear();

  @override
  Map<String, dynamic> toMap() => {'type': 'clear'};

  @override
  String toString() => 'Clear()';
}

/// Shift state change
class Shift extends KeyboardEvent {
  final bool enabled;

  const Shift(this.enabled);

  @override
  Map<String, dynamic> toMap() => {
        'type': 'shift',
        'enabled': enabled,
      };

  @override
  String toString() => 'Shift($enabled)';
}
