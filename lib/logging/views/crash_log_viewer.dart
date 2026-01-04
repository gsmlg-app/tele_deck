import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../crash_log_entry.dart';

/// MethodChannel for crash log operations
const _crashLogChannel = MethodChannel('app.gsmlg.tele_deck/crash_logs');

/// Provider for crash logs from native
final nativeCrashLogsProvider = FutureProvider<List<CrashLogEntry>>((ref) async {
  try {
    final result = await _crashLogChannel.invokeMethod<List<dynamic>>('getCrashLogs');
    if (result == null) return [];

    return result
        .map((jsonStr) {
          try {
            final json = jsonDecode(jsonStr as String) as Map<String, dynamic>;
            return CrashLogEntry.fromJson(json);
          } catch (e) {
            return null;
          }
        })
        .whereType<CrashLogEntry>()
        .toList();
  } catch (e) {
    return [];
  }
});

/// Crash log viewer widget with list and detail views
class CrashLogViewer extends ConsumerWidget {
  const CrashLogViewer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(nativeCrashLogsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text('Crash Logs'),
        backgroundColor: const Color(0xFF2D2D2D),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(nativeCrashLogsProvider),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => _showClearConfirmation(context, ref),
            tooltip: 'Clear All',
          ),
        ],
      ),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error: $error',
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(nativeCrashLogsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'No crash logs',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your keyboard has been running smoothly!',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return _CrashLogCard(
                entry: log,
                onTap: () => _showLogDetail(context, log),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showClearConfirmation(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text('Clear All Crash Logs?'),
        content: const Text(
          'This will permanently delete all crash logs. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _crashLogChannel.invokeMethod('clearCrashLogs');
        ref.invalidate(nativeCrashLogsProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to clear logs: $e')),
          );
        }
      }
    }
  }

  void _showLogDetail(BuildContext context, CrashLogEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _CrashLogDetailView(entry: entry),
      ),
    );
  }
}

class _CrashLogCard extends StatelessWidget {
  final CrashLogEntry entry;
  final VoidCallback onTap;

  const _CrashLogCard({
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF2D2D2D),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.errorType,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    entry.formattedTime,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                entry.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.settings,
                    label: entry.engineState,
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.calendar_today,
                    label: entry.formattedDate,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white54),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}

class _CrashLogDetailView extends StatelessWidget {
  final CrashLogEntry entry;

  const _CrashLogDetailView({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text('Crash Details'),
        backgroundColor: const Color(0xFF2D2D2D),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () => _copyToClipboard(context),
            tooltip: 'Copy to Clipboard',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailSection(
              title: 'Error Type',
              content: entry.errorType,
            ),
            _DetailSection(
              title: 'Message',
              content: entry.message,
            ),
            _DetailSection(
              title: 'Timestamp',
              content: '${entry.formattedDate} ${entry.formattedTime}',
            ),
            _DetailSection(
              title: 'Engine State',
              content: entry.engineState,
            ),
            if (entry.displayStateMap != null) ...[
              _DetailSection(
                title: 'Display State',
                content: _formatDisplayState(entry.displayStateMap!),
              ),
            ],
            _DetailSection(
              title: 'Stack Trace',
              content: entry.stackTrace,
              isCode: true,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDisplayState(Map<String, dynamic> displayState) {
    final buffer = StringBuffer();
    displayState.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    return buffer.toString().trim();
  }

  void _copyToClipboard(BuildContext context) {
    final text = '''
Error Type: ${entry.errorType}
Message: ${entry.message}
Timestamp: ${entry.timestamp.toIso8601String()}
Engine State: ${entry.engineState}
Display State: ${entry.displayStateMap ?? 'N/A'}

Stack Trace:
${entry.stackTrace}
''';

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final String content;
  final bool isCode;

  const _DetailSection({
    required this.title,
    required this.content,
    this.isCode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              content,
              style: TextStyle(
                color: Colors.white,
                fontFamily: isCode ? 'monospace' : null,
                fontSize: isCode ? 12 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
