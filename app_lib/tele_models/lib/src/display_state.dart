import 'package:equatable/equatable.dart';

/// Represents the current display configuration detected by the IME service.
class DisplayState extends Equatable {
  /// True if a secondary display is connected
  final bool hasSecondaryDisplay;

  /// Display ID of secondary (null if none)
  final int? secondaryDisplayId;

  /// Primary display width in pixels
  final int primaryWidth;

  /// Primary display height in pixels
  final int primaryHeight;

  /// Secondary display width (null if none)
  final int? secondaryWidth;

  /// Secondary display height (null if none)
  final int? secondaryHeight;

  const DisplayState({
    required this.hasSecondaryDisplay,
    this.secondaryDisplayId,
    required this.primaryWidth,
    required this.primaryHeight,
    this.secondaryWidth,
    this.secondaryHeight,
  });

  /// No secondary display state
  factory DisplayState.noSecondary({
    required int primaryWidth,
    required int primaryHeight,
  }) {
    return DisplayState(
      hasSecondaryDisplay: false,
      secondaryDisplayId: null,
      primaryWidth: primaryWidth,
      primaryHeight: primaryHeight,
      secondaryWidth: null,
      secondaryHeight: null,
    );
  }

  /// With secondary display state
  factory DisplayState.withSecondary({
    required int secondaryDisplayId,
    required int primaryWidth,
    required int primaryHeight,
    required int secondaryWidth,
    required int secondaryHeight,
  }) {
    return DisplayState(
      hasSecondaryDisplay: true,
      secondaryDisplayId: secondaryDisplayId,
      primaryWidth: primaryWidth,
      primaryHeight: primaryHeight,
      secondaryWidth: secondaryWidth,
      secondaryHeight: secondaryHeight,
    );
  }

  /// Create from JSON map (for MethodChannel communication)
  factory DisplayState.fromJson(Map<String, dynamic> json) {
    return DisplayState(
      hasSecondaryDisplay: json['hasSecondaryDisplay'] as bool? ?? false,
      secondaryDisplayId: json['secondaryDisplayId'] as int?,
      primaryWidth: json['primaryWidth'] as int? ?? 0,
      primaryHeight: json['primaryHeight'] as int? ?? 0,
      secondaryWidth: json['secondaryWidth'] as int?,
      secondaryHeight: json['secondaryHeight'] as int?,
    );
  }

  /// Convert to JSON map (for MethodChannel communication)
  Map<String, dynamic> toJson() {
    return {
      'hasSecondaryDisplay': hasSecondaryDisplay,
      'secondaryDisplayId': secondaryDisplayId,
      'primaryWidth': primaryWidth,
      'primaryHeight': primaryHeight,
      'secondaryWidth': secondaryWidth,
      'secondaryHeight': secondaryHeight,
    };
  }

  /// Get the active display dimensions (secondary if available, otherwise primary)
  (int width, int height) get activeDisplaySize {
    if (hasSecondaryDisplay &&
        secondaryWidth != null &&
        secondaryHeight != null) {
      return (secondaryWidth!, secondaryHeight!);
    }
    return (primaryWidth, primaryHeight);
  }

  @override
  List<Object?> get props => [
    hasSecondaryDisplay,
    secondaryDisplayId,
    primaryWidth,
    primaryHeight,
    secondaryWidth,
    secondaryHeight,
  ];

  @override
  String toString() {
    return 'DisplayState('
        'hasSecondary: $hasSecondaryDisplay, '
        'secondaryId: $secondaryDisplayId, '
        'primary: ${primaryWidth}x$primaryHeight, '
        'secondary: ${secondaryWidth}x$secondaryHeight)';
  }
}
