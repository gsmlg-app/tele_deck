import 'package:tele_models/tele_models.dart';

/// Represents a single crash log entry persisted to local storage.
class CrashLogEntry {
  /// Unique identifier (timestamp-based)
  final String id;

  /// When the crash occurred
  final DateTime timestamp;

  /// Exception class name
  final String errorType;

  /// Error message
  final String message;

  /// Full stack trace
  final String stackTrace;

  /// Display config at crash time
  final DisplayState? displayState;

  /// Flutter engine state (running/stopped)
  final String engineState;

  const CrashLogEntry({
    required this.id,
    required this.timestamp,
    required this.errorType,
    required this.message,
    required this.stackTrace,
    this.displayState,
    required this.engineState,
  });

  /// Create a new crash log entry with auto-generated ID
  factory CrashLogEntry.create({
    required String errorType,
    required String message,
    required String stackTrace,
    DisplayState? displayState,
    required String engineState,
  }) {
    final timestamp = DateTime.now();
    final id = 'crash_${timestamp.millisecondsSinceEpoch}';
    return CrashLogEntry(
      id: id,
      timestamp: timestamp,
      errorType: errorType,
      message: message,
      stackTrace: stackTrace,
      displayState: displayState,
      engineState: engineState,
    );
  }

  /// Create from JSON map (for MethodChannel communication and file storage)
  factory CrashLogEntry.fromJson(Map<String, dynamic> json) {
    return CrashLogEntry(
      id: json['id'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      errorType: json['errorType'] as String? ?? 'Unknown',
      message: json['message'] as String? ?? '',
      stackTrace: json['stackTrace'] as String? ?? '',
      displayState: json['displayState'] != null
          ? DisplayState.fromJson(json['displayState'] as Map<String, dynamic>)
          : null,
      engineState: json['engineState'] as String? ?? 'unknown',
    );
  }

  /// Convert to JSON map (for MethodChannel communication and file storage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'errorType': errorType,
      'message': message,
      'stackTrace': stackTrace,
      'displayState': displayState?.toJson(),
      'engineState': engineState,
    };
  }

  /// Create a summary version (without full stack trace) for list display
  Map<String, dynamic> toSummaryJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'errorType': errorType,
      'message': message,
    };
  }

  /// Get the log file name
  String get fileName => '$id.log';

  /// Check if this entry is older than the specified duration
  bool isOlderThan(Duration duration) {
    return DateTime.now().difference(timestamp) > duration;
  }

  /// Check if this entry should be auto-cleaned (older than 7 days)
  bool get shouldAutoClean => isOlderThan(const Duration(days: 7));

  /// Get a formatted timestamp string for display
  String get formattedTimestamp {
    return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-'
        '${timestamp.day.toString().padLeft(2, '0')} '
        '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
  }

  /// Get formatted date string (YYYY-MM-DD)
  String get formattedDate {
    return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-'
        '${timestamp.day.toString().padLeft(2, '0')}';
  }

  /// Get formatted time string (HH:MM:SS)
  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
  }

  /// Get display state as a map for display purposes
  Map<String, dynamic>? get displayStateMap {
    return displayState?.toJson();
  }

  @override
  String toString() {
    return 'CrashLogEntry('
        'id: $id, '
        'timestamp: $formattedTimestamp, '
        'errorType: $errorType, '
        'message: $message)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CrashLogEntry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
