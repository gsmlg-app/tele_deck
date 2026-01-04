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
      'tab' => const Tab(),
      'escape' => const Escape(),
      'delete' => const Delete(),
      'function_key' => FunctionKey(map['number'] as int),
      'arrow' => ArrowKey(ArrowDirection.values.byName(map['direction'] as String)),
      'modifier' => Modifier(
          ModifierType.values.byName(map['modifier'] as String),
          pressed: map['pressed'] as bool,
        ),
      'caps_lock' => CapsLock(map['enabled'] as bool),
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

/// Tab key
class Tab extends KeyboardEvent {
  const Tab();

  @override
  Map<String, dynamic> toMap() => {'type': 'tab'};

  @override
  String toString() => 'Tab()';
}

/// Escape key
class Escape extends KeyboardEvent {
  const Escape();

  @override
  Map<String, dynamic> toMap() => {'type': 'escape'};

  @override
  String toString() => 'Escape()';
}

/// Delete key (forward delete)
class Delete extends KeyboardEvent {
  const Delete();

  @override
  Map<String, dynamic> toMap() => {'type': 'delete'};

  @override
  String toString() => 'Delete()';
}

/// Function key (F1-F12)
class FunctionKey extends KeyboardEvent {
  final int number;

  const FunctionKey(this.number);

  @override
  Map<String, dynamic> toMap() => {
        'type': 'function_key',
        'number': number,
      };

  @override
  String toString() => 'FunctionKey(F$number)';
}

/// Arrow key direction
enum ArrowDirection { up, down, left, right }

/// Arrow key event
class ArrowKey extends KeyboardEvent {
  final ArrowDirection direction;

  const ArrowKey(this.direction);

  @override
  Map<String, dynamic> toMap() => {
        'type': 'arrow',
        'direction': direction.name,
      };

  @override
  String toString() => 'ArrowKey(${direction.name})';
}

/// Modifier key state (Ctrl, Alt, Super/Meta)
enum ModifierType { ctrl, alt, super_ }

/// Modifier key pressed/released
class Modifier extends KeyboardEvent {
  final ModifierType modifier;
  final bool pressed;

  const Modifier(this.modifier, {required this.pressed});

  @override
  Map<String, dynamic> toMap() => {
        'type': 'modifier',
        'modifier': modifier.name,
        'pressed': pressed,
      };

  @override
  String toString() => 'Modifier(${modifier.name}, pressed: $pressed)';
}

/// Caps Lock toggle
class CapsLock extends KeyboardEvent {
  final bool enabled;

  const CapsLock(this.enabled);

  @override
  Map<String, dynamic> toMap() => {
        'type': 'caps_lock',
        'enabled': enabled,
      };

  @override
  String toString() => 'CapsLock($enabled)';
}
