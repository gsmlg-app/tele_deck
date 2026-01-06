/// Data class representing a crash log entry
class CrashLogEntry {
  /// Creates a new [CrashLogEntry] instance
  const CrashLogEntry({
    required this.id,
    required this.timestamp,
    required this.errorType,
    required this.message,
    required this.stackTrace,
    required this.engineState,
  });

  /// Unique identifier for the crash log
  final String id;

  /// ISO 8601 timestamp when the crash occurred
  final String timestamp;

  /// Type of error that caused the crash
  final String errorType;

  /// Error message
  final String message;

  /// Stack trace at the time of the crash
  final String stackTrace;

  /// State of the engine when the crash occurred
  final String engineState;

  /// Creates a [CrashLogEntry] from a map
  factory CrashLogEntry.fromMap(Map<dynamic, dynamic> map) {
    return CrashLogEntry(
      id: map['id'] as String? ?? '',
      timestamp: map['timestamp'] as String? ?? '',
      errorType: map['errorType'] as String? ?? '',
      message: map['message'] as String? ?? '',
      stackTrace: map['stackTrace'] as String? ?? '',
      engineState: map['engineState'] as String? ?? '',
    );
  }

  /// Converts this entry to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp,
      'errorType': errorType,
      'message': message,
      'stackTrace': stackTrace,
      'engineState': engineState,
    };
  }

  @override
  String toString() {
    return 'CrashLogEntry(id: $id, errorType: $errorType, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CrashLogEntry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
