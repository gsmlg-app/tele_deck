/// Data class representing display information
class DisplayInfo {
  /// Creates a new [DisplayInfo] instance
  const DisplayInfo({
    required this.displayId,
    required this.name,
    required this.width,
    required this.height,
    required this.rotation,
    required this.isValid,
  });

  /// Display ID (0 is primary display)
  final int displayId;

  /// Display name
  final String name;

  /// Display width in pixels
  final int width;

  /// Display height in pixels
  final int height;

  /// Display rotation (0, 90, 180, 270)
  final int rotation;

  /// Whether the display is valid/connected
  final bool isValid;

  /// Creates a [DisplayInfo] from a map
  factory DisplayInfo.fromMap(Map<dynamic, dynamic> map) {
    return DisplayInfo(
      displayId: map['displayId'] as int? ?? 0,
      name: map['name'] as String? ?? '',
      width: map['width'] as int? ?? 0,
      height: map['height'] as int? ?? 0,
      rotation: map['rotation'] as int? ?? 0,
      isValid: map['isValid'] as bool? ?? false,
    );
  }

  /// Converts this info to a map
  Map<String, dynamic> toMap() {
    return {
      'displayId': displayId,
      'name': name,
      'width': width,
      'height': height,
      'rotation': rotation,
      'isValid': isValid,
    };
  }

  /// Whether this is the primary display
  bool get isPrimary => displayId == 0;

  /// Whether this is a secondary/external display
  bool get isSecondary => displayId != 0;

  @override
  String toString() {
    return 'DisplayInfo(id: $displayId, name: $name, ${width}x$height)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DisplayInfo && other.displayId == displayId;
  }

  @override
  int get hashCode => displayId.hashCode;
}

/// Display event types
enum DisplayEventType {
  /// A display was added/connected
  added,

  /// A display was removed/disconnected
  removed,

  /// A display configuration changed
  changed,
}

/// Data class representing a display change event
class DisplayEvent {
  /// Creates a new [DisplayEvent] instance
  const DisplayEvent({
    required this.type,
    this.display,
    this.displayId,
  });

  /// Event type
  final DisplayEventType type;

  /// Display info (for added/changed events)
  final DisplayInfo? display;

  /// Display ID (for removed events)
  final int? displayId;

  /// Creates a [DisplayEvent] from a map
  factory DisplayEvent.fromMap(Map<dynamic, dynamic> map) {
    final eventStr = map['event'] as String?;
    final type = switch (eventStr) {
      'displayAdded' => DisplayEventType.added,
      'displayRemoved' => DisplayEventType.removed,
      'displayChanged' => DisplayEventType.changed,
      _ => DisplayEventType.changed,
    };

    final displayMap = map['display'] as Map<dynamic, dynamic>?;

    return DisplayEvent(
      type: type,
      display: displayMap != null ? DisplayInfo.fromMap(displayMap) : null,
      displayId: map['displayId'] as int?,
    );
  }

  @override
  String toString() {
    return 'DisplayEvent(type: $type, displayId: ${display?.displayId ?? displayId})';
  }
}
