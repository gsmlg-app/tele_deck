import 'package:flutter/services.dart';

import 'models/models.dart';

export 'models/models.dart';

/// Native crash logging service
///
/// Provides crash logging functionality with native platform integration.
/// Logs are stored on device and can show notifications when crashes occur.
class TeleCrashLogger {
  TeleCrashLogger._();

  static final TeleCrashLogger _instance = TeleCrashLogger._();

  /// Returns the singleton instance of [TeleCrashLogger]
  static TeleCrashLogger get instance => _instance;

  /// Method channel for platform communication
  static const MethodChannel _channel = MethodChannel('tele_crash_logger');

  /// Log a crash with the given details
  ///
  /// Returns the crash ID if successful, null otherwise
  Future<String?> logCrash({
    required String errorType,
    required String message,
    String stackTrace = '',
    Map<String, dynamic>? displayState,
    String engineState = 'running',
    bool showNotification = true,
  }) async {
    try {
      final result = await _channel.invokeMethod<String>('logCrash', {
        'errorType': errorType,
        'message': message,
        'stackTrace': stackTrace,
        'displayState': displayState,
        'engineState': engineState,
        'showNotification': showNotification,
      });
      return result;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Failed to log crash: ${e.message}');
      return null;
    }
  }

  /// Log an exception
  Future<String?> logException(
    Object exception, {
    StackTrace? stackTrace,
    Map<String, dynamic>? displayState,
    String engineState = 'running',
    bool showNotification = true,
  }) {
    return logCrash(
      errorType: exception.runtimeType.toString(),
      message: exception.toString(),
      stackTrace: stackTrace?.toString() ?? '',
      displayState: displayState,
      engineState: engineState,
      showNotification: showNotification,
    );
  }

  /// Get all crash logs
  Future<List<CrashLogEntry>> getCrashLogs() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getCrashLogs');
      if (result == null) return [];

      return result
          .map((e) => CrashLogEntry.fromMap(e as Map<dynamic, dynamic>))
          .toList();
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Failed to get crash logs: ${e.message}');
      return [];
    }
  }

  /// Get a specific crash log by ID
  Future<CrashLogEntry?> getCrashLogDetail(String id) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getCrashLogDetail',
        {'id': id},
      );
      if (result == null) return null;
      return CrashLogEntry.fromMap(result);
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Failed to get crash log detail: ${e.message}');
      return null;
    }
  }

  /// Clear all crash logs
  Future<bool> clearCrashLogs() async {
    try {
      final result = await _channel.invokeMethod<bool>('clearCrashLogs');
      return result ?? false;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Failed to clear crash logs: ${e.message}');
      return false;
    }
  }
}
