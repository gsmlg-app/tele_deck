import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:settings_widgets/settings_widgets.dart';
import 'package:tele_deck/screens/settings/crash_logs_screen.dart';

class SettingsScreen extends StatelessWidget {
  static const name = 'Settings';
  static const path = '/settings';

  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsView(
      onViewCrashLogs: () {
        context.pushNamed(CrashLogsScreen.name);
      },
    );
  }
}
