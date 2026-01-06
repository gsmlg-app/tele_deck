import 'package:{{package_prefix.snakeCase()}}_{{name.snakeCase()}}_platform_interface/{{package_prefix.snakeCase()}}_{{name.snakeCase()}}_platform_interface.dart';

/// The iOS implementation of [{{name.pascalCase()}}Platform].
class {{name.pascalCase()}}IOS extends {{name.pascalCase()}}Platform {
  /// Registers this class as the default instance of [{{name.pascalCase()}}Platform].
  static void registerWith() {
    {{name.pascalCase()}}Platform.instance = {{name.pascalCase()}}IOS();
  }
}
