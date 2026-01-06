import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tele_logging/tele_logging.dart';
import 'package:tele_theme/tele_theme.dart';

/// Crash log viewer widget
class CrashLogViewer extends StatefulWidget {
  /// Whether to show back button in AppBar (for standalone usage)
  final bool showBackButton;

  const CrashLogViewer({
    super.key,
    this.showBackButton = true,
  });

  @override
  State<CrashLogViewer> createState() => _CrashLogViewerState();
}

class _CrashLogViewerState extends State<CrashLogViewer> {
  final CrashLogService _service = CrashLogService();
  List<CrashLogEntry> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final logs = await _service.getCrashLogs();
    setState(() {
      _logs = logs;
      _isLoading = false;
    });
  }

  Future<void> _clearLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(TeleDeckColors.secondaryBackground),
        title: Text(
          'Clear Crash Logs?',
          style: GoogleFonts.robotoMono(
            color: const Color(TeleDeckColors.neonCyan),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This will permanently delete all crash logs.',
          style: GoogleFonts.robotoMono(
            color: const Color(TeleDeckColors.textPrimary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.robotoMono(
                color: const Color(TeleDeckColors.textPrimary),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Clear',
              style: GoogleFonts.robotoMono(
                color: const Color(TeleDeckColors.neonMagenta),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _service.clearCrashLogs();
      await _loadLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(TeleDeckColors.darkBackground),
      appBar: AppBar(
        backgroundColor: const Color(TeleDeckColors.secondaryBackground),
        title: Text(
          'CRASH LOGS',
          style: GoogleFonts.robotoMono(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(TeleDeckColors.neonCyan),
            letterSpacing: 3,
          ),
        ),
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Color(TeleDeckColors.neonCyan),
                ),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Color(TeleDeckColors.neonCyan),
            ),
            onPressed: _loadLogs,
          ),
          if (_logs.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Color(TeleDeckColors.neonMagenta),
              ),
              onPressed: _clearLogs,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(TeleDeckColors.neonCyan),
              ),
            )
          : _logs.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: const Color(
                      TeleDeckColors.neonCyan,
                    ).withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No crash logs',
                    style: GoogleFonts.robotoMono(
                      fontSize: 16,
                      color: const Color(
                        TeleDeckColors.textPrimary,
                      ).withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                return _CrashLogCard(
                  log: log,
                  onTap: () => _showLogDetail(log),
                );
              },
            ),
    );
  }

  void _showLogDetail(CrashLogEntry log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(TeleDeckColors.secondaryBackground),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Color(TeleDeckColors.neonCyan),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      log.errorType,
                      style: GoogleFonts.robotoMono(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(TeleDeckColors.neonMagenta),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Color(TeleDeckColors.textPrimary),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  _DetailRow(label: 'Time', value: log.formattedTimestamp),
                  _DetailRow(label: 'Message', value: log.message),
                  _DetailRow(label: 'Engine State', value: log.engineState),
                  const SizedBox(height: 16),
                  Text(
                    'Stack Trace',
                    style: GoogleFonts.robotoMono(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(TeleDeckColors.neonCyan),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(TeleDeckColors.darkBackground),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      log.stackTrace,
                      style: GoogleFonts.robotoMono(
                        fontSize: 10,
                        color: const Color(
                          TeleDeckColors.textPrimary,
                        ).withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CrashLogCard extends StatelessWidget {
  final CrashLogEntry log;
  final VoidCallback? onTap;

  const _CrashLogCard({required this.log, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(TeleDeckColors.secondaryBackground),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(TeleDeckColors.neonMagenta),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      log.errorType,
                      style: GoogleFonts.robotoMono(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(TeleDeckColors.textPrimary),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: const Color(
                      TeleDeckColors.neonCyan,
                    ).withValues(alpha: 0.5),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                log.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.robotoMono(
                  fontSize: 12,
                  color: const Color(
                    TeleDeckColors.textPrimary,
                  ).withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                log.formattedTimestamp,
                style: GoogleFonts.robotoMono(
                  fontSize: 10,
                  color: const Color(
                    TeleDeckColors.neonCyan,
                  ).withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.robotoMono(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: const Color(TeleDeckColors.neonCyan),
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: GoogleFonts.robotoMono(
              fontSize: 12,
              color: const Color(TeleDeckColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
