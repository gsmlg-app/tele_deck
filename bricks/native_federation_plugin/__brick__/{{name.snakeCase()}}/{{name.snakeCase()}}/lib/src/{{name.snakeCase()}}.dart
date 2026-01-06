import 'package:{{package_prefix.snakeCase()}}_{{name.snakeCase()}}_platform_interface/{{package_prefix.snakeCase()}}_{{name.snakeCase()}}_platform_interface.dart';
import 'models/models.dart';

/// Main class for {{name.pascalCase()}} plugin.
///
/// Provides a unified API for accessing {{name.lowerCase()}} information
/// across all supported platforms.
class {{name.pascalCase()}} {
  {{name.pascalCase()}}._();

  static {{name.pascalCase()}}? _instance;

  /// Get the singleton instance of {{name.pascalCase()}}.
  static {{name.pascalCase()}} get instance {
    _instance ??= {{name.pascalCase()}}._();
    return _instance!;
  }

  /// The platform interface instance.
  static {{name.pascalCase()}}Platform get _platform {
    return {{name.pascalCase()}}Platform.instance;
  }

  /// Get {{name.lowerCase()}} data.
  ///
  /// Returns a [{{name.pascalCase()}}Data] object containing all available
  /// {{name.lowerCase()}} information for the current platform.
  ///
  /// Example:
  /// ```dart
  /// final {{name.camelCase()}} = {{name.pascalCase()}}.instance;
  /// final data = await {{name.camelCase()}}.getData();
  /// print('Data: ${data}');
  /// ```
  Future<{{name.pascalCase()}}Data> getData() async {
    final platformData = await _platform.getData();
    return {{name.pascalCase()}}Data.fromMap(platformData);
  }

  /// Refresh {{name.lowerCase()}} data.
  ///
  /// Forces a refresh of the cached data from the platform.
  Future<void> refresh() async {
    await _platform.refresh();
  }

  /// For testing purposes only.
  @visibleForTesting
  static void setMockPlatform({{name.pascalCase()}}Platform platform) {
    {{name.pascalCase()}}Platform.instance = platform;
  }

  /// Reset the singleton instance.
  @visibleForTesting
  static void reset() {
    _instance = null;
  }
}
