import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'method_channel_{{name.snakeCase()}}.dart';

/// The interface that platform-specific implementations of
/// `{{package_prefix.snakeCase()}}_{{name.snakeCase()}}` must extend.
abstract class {{name.pascalCase()}}Platform extends PlatformInterface {
  /// Constructs a {{name.pascalCase()}}Platform.
  {{name.pascalCase()}}Platform() : super(token: _token);

  static final Object _token = Object();

  static {{name.pascalCase()}}Platform _instance = MethodChannel{{name.pascalCase()}}();

  /// The default instance of [{{name.pascalCase()}}Platform] to use.
  ///
  /// Defaults to [MethodChannel{{name.pascalCase()}}].
  static {{name.pascalCase()}}Platform get instance => _instance;

  /// Platform-specific plugins should set this with their own
  /// platform-specific class that extends [{{name.pascalCase()}}Platform] when
  /// they register themselves.
  static set instance({{name.pascalCase()}}Platform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  /// Get {{name.lowerCase()}} data from the platform.
  ///
  /// Returns a map containing platform-specific {{name.lowerCase()}} data.
  Future<Map<String, dynamic>> getData() {
    throw UnimplementedError('getData() has not been implemented.');
  }

  /// Refresh the cached {{name.lowerCase()}} data.
  Future<void> refresh() {
    throw UnimplementedError('refresh() has not been implemented.');
  }
}
