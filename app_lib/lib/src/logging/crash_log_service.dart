import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/display_state.dart';
import 'crash_log_entry.dart';

/// Service for managing crash logs with file-based persistence and 7-day cleanup.
class CrashLogService {
  static const String _crashLogsDir = 'crash_logs';
  static const Duration _retentionPeriod = Duration(days: 7);

  Directory? _logsDirectory;

  /// Get the crash logs directory, creating it if necessary
  Future<Directory> get logsDirectory async {
    if (_logsDirectory != null) return _logsDirectory!;

    final appDir = await getApplicationDocumentsDirectory();
    _logsDirectory = Directory('${appDir.path}/$_crashLogsDir');

    if (!await _logsDirectory!.exists()) {
      await _logsDirectory!.create(recursive: true);
    }

    return _logsDirectory!;
  }

  /// Log a crash with the given details
  Future<CrashLogEntry> logCrash({
    required String errorType,
    required String message,
    required String stackTrace,
    DisplayState? displayState,
    required String engineState,
  }) async {
    final entry = CrashLogEntry.create(
      errorType: errorType,
      message: message,
      stackTrace: stackTrace,
      displayState: displayState,
      engineState: engineState,
    );

    await _saveEntry(entry);
    await _cleanupOldLogs();

    return entry;
  }

  /// Log an exception
  Future<CrashLogEntry> logException(
    Object error,
    StackTrace stackTrace, {
    DisplayState? displayState,
    String engineState = 'running',
  }) async {
    return logCrash(
      errorType: error.runtimeType.toString(),
      message: error.toString(),
      stackTrace: stackTrace.toString(),
      displayState: displayState,
      engineState: engineState,
    );
  }

  /// Get all crash logs, sorted by timestamp descending (newest first)
  Future<List<CrashLogEntry>> getCrashLogs() async {
    try {
      final dir = await logsDirectory;
      final files = await dir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.log'))
          .cast<File>()
          .toList();

      final entries = <CrashLogEntry>[];

      for (final file in files) {
        try {
          final content = await file.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          entries.add(CrashLogEntry.fromJson(json));
        } catch (e) {
          // Skip corrupt log files
          debugPrint('Failed to parse crash log: ${file.path}, error: $e');
        }
      }

      // Sort by timestamp descending (newest first)
      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return entries;
    } catch (e) {
      debugPrint('Failed to get crash logs: $e');
      return [];
    }
  }

  /// Get a specific crash log by ID
  Future<CrashLogEntry?> getCrashLogDetail(String id) async {
    try {
      final dir = await logsDirectory;
      final file = File('${dir.path}/$id.log');

      if (!await file.exists()) {
        return null;
      }

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return CrashLogEntry.fromJson(json);
    } catch (e) {
      debugPrint('Failed to get crash log detail: $e');
      return null;
    }
  }

  /// Delete all crash logs
  Future<bool> clearCrashLogs() async {
    try {
      final dir = await logsDirectory;
      final files = await dir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.log'))
          .cast<File>()
          .toList();

      for (final file in files) {
        await file.delete();
      }

      return true;
    } catch (e) {
      debugPrint('Failed to clear crash logs: $e');
      return false;
    }
  }

  /// Delete a specific crash log
  Future<bool> deleteCrashLog(String id) async {
    try {
      final dir = await logsDirectory;
      final file = File('${dir.path}/$id.log');

      if (await file.exists()) {
        await file.delete();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Failed to delete crash log: $e');
      return false;
    }
  }

  /// Save a crash log entry to file
  Future<void> _saveEntry(CrashLogEntry entry) async {
    try {
      final dir = await logsDirectory;
      final file = File('${dir.path}/${entry.fileName}');
      await file.writeAsString(jsonEncode(entry.toJson()));
    } catch (e) {
      debugPrint('Failed to save crash log: $e');
    }
  }

  /// Clean up logs older than 7 days
  Future<void> _cleanupOldLogs() async {
    try {
      final dir = await logsDirectory;
      final files = await dir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.log'))
          .cast<File>()
          .toList();

      for (final file in files) {
        try {
          final content = await file.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          final entry = CrashLogEntry.fromJson(json);

          if (entry.shouldAutoClean) {
            await file.delete();
            debugPrint('Cleaned up old crash log: ${entry.id}');
          }
        } catch (e) {
          // If we can't parse the file, check file modification time
          final stat = await file.stat();
          if (DateTime.now().difference(stat.modified) > _retentionPeriod) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to cleanup old logs: $e');
    }
  }

  /// Get the count of crash logs
  Future<int> getCrashLogCount() async {
    try {
      final dir = await logsDirectory;
      final files = await dir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.log'))
          .length;
      return files;
    } catch (e) {
      debugPrint('Failed to get crash log count: $e');
      return 0;
    }
  }
}
