import 'package:flutter/services.dart';
import '{{name.snakeCase()}}_platform.dart';

/// An implementation of [{{name.pascalCase()}}Platform] that uses method channels.
class MethodChannel{{name.pascalCase()}} extends {{name.pascalCase()}}Platform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('{{package_prefix.snakeCase()}}_{{name.snakeCase()}}');

  @override
  Future<Map<String, dynamic>> getData() async {
    final result = await methodChannel.invokeMethod<Map<Object?, Object?>>('getData');
    if (result == null) {
      throw PlatformException(
        code: 'NULL_RESULT',
        message: 'Platform returned null result',
      );
    }
    return Map<String, dynamic>.from(result);
  }

  @override
  Future<void> refresh() async {
    await methodChannel.invokeMethod<void>('refresh');
  }
}
