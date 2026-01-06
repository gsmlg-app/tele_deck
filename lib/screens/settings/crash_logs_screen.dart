import 'package:common_widgets/common_widgets.dart';
import 'package:flutter/material.dart';

class CrashLogsScreen extends StatelessWidget {
  static const name = 'Crash Logs';
  static const path = 'crash-logs';

  const CrashLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CrashLogViewer();
  }
}
