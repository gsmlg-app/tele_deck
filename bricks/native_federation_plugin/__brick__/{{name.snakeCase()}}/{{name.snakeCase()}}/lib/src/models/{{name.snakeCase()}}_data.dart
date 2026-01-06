/// Data model for {{name.pascalCase()}}.
class {{name.pascalCase()}}Data {
  /// Creates a {{name.pascalCase()}}Data instance.
  const {{name.pascalCase()}}Data({
    required this.platform,
    required this.timestamp,
    this.additionalData = const {},
  });

  /// The platform name (e.g., 'android', 'ios', 'linux').
  final String platform;

  /// The timestamp when this data was collected.
  final DateTime timestamp;

  /// Additional platform-specific data.
  final Map<String, dynamic> additionalData;

  /// Creates a {{name.pascalCase()}}Data from a map.
  factory {{name.pascalCase()}}Data.fromMap(Map<String, dynamic> map) {
    return {{name.pascalCase()}}Data(
      platform: map['platform'] as String? ?? 'unknown',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'] as String)
          : DateTime.now(),
      additionalData: Map<String, dynamic>.from(
        (map['additionalData'] as Map<dynamic, dynamic>?) ?? {},
      ),
    );
  }

  /// Converts this {{name.pascalCase()}}Data to a map.
  Map<String, dynamic> toMap() {
    return {
      'platform': platform,
      'timestamp': timestamp.toIso8601String(),
      'additionalData': additionalData,
    };
  }

  @override
  String toString() {
    return '{{name.pascalCase()}}Data(platform: $platform, timestamp: $timestamp, additionalData: $additionalData)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is {{name.pascalCase()}}Data &&
        other.platform == platform &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => platform.hashCode ^ timestamp.hashCode;
}
