import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:tele_theme/tele_theme.dart';

import '../home/home_screen.dart';
import '../logs/log_screen.dart';
import '../settings/setting_screen.dart';

/// Main shell screen with adaptive navigation (bottom nav / rail)
class ShellScreen extends StatefulWidget {
  static const name = 'Shell';
  static const path = '/shell';

  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _selectedIndex = 0;

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.bug_report_outlined),
      selectedIcon: Icon(Icons.bug_report),
      label: 'Logs',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      destinations: _destinations,
      selectedIndex: _selectedIndex,
      onSelectedIndexChange: (index) {
        setState(() => _selectedIndex = index);
      },
      body: (_) => _buildBody(),
      useDrawer: false,
      internalAnimations: false,
      // Customize colors for cyberpunk theme
      appBarBreakpoint: Breakpoints.small,
    );
  }

  Widget _buildBody() {
    return ColoredBox(
      color: const Color(TeleDeckColors.darkBackground),
      child: switch (_selectedIndex) {
        0 => const HomeScreen(),
        1 => const LogScreen(),
        2 => const SettingScreen(),
        _ => const HomeScreen(),
      },
    );
  }
}
