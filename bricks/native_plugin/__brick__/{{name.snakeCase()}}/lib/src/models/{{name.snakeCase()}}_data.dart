/// Data class for {{name.pascalCase()}} plugin
class {{name.pascalCase()}}Data {
  /// Creates a new [{{name.pascalCase()}}Data] instance
  const {{name.pascalCase()}}Data({
    required this.platform,
    required this.timestamp,
    this.additionalData = const {},
  });

  /// The platform identifier (e.g., 'android', 'ios', 'linux', 'macos', 'windows')
  final String platform;

  /// Timestamp when the data was collected
  final DateTime timestamp;

  /// Additional platform-specific data
  final Map<String, dynamic> additionalData;

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
  int get hashCode => Object.hash(platform, timestamp);
}
