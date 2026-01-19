import 'package:common_widgets/common_widgets.dart';
import 'package:flutter/material.dart';

/// Log screen showing crash logs (used as a tab in ShellScreen)
class LogScreen extends StatelessWidget {
  static const name = 'Logs';

  const LogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use CrashLogViewer without back button (navigation handled by ShellScreen)
    return const CrashLogViewer(showBackButton: false);
  }
}
