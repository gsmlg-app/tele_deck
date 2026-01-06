import 'package:flutter/services.dart';

import 'models/models.dart';

/// Main plugin class for {{name.pascalCase()}}
///
/// Provides a simple interface to access {{name.snakeCase()}} functionality
/// across all supported platforms.
class {{name.pascalCase()}} {
  {{name.pascalCase()}}._();

  static final {{name.pascalCase()}} _instance = {{name.pascalCase()}}._();

  /// Returns the singleton instance of [{{name.pascalCase()}}]
  static {{name.pascalCase()}} get instance => _instance;

  /// Method channel for platform communication
  static const MethodChannel _channel = MethodChannel(
    '{{package_prefix.snakeCase()}}_{{name.snakeCase()}}',
  );

  {{name.pascalCase()}}Data? _cachedData;

  /// Gets data from the native platform
  ///
  /// Returns cached data if available, otherwise fetches from platform.
  Future<{{name.pascalCase()}}Data> getData() async {
    if (_cachedData != null) {
      return _cachedData!;
    }
    return refresh();
  }

  /// Refreshes data from the native platform
  ///
  /// Forces a fresh fetch from the platform and updates the cache.
  Future<{{name.pascalCase()}}Data> refresh() async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getData');

    _cachedData = {{name.pascalCase()}}Data(
      platform: result?['platform'] as String? ?? 'unknown',
      timestamp: DateTime.now(),
      additionalData: Map<String, dynamic>.from(result ?? {}),
    );

    return _cachedData!;
  }

  /// Clears cached data
  void clearCache() {
    _cachedData = null;
  }
}
