import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presentation_displays/display.dart';
import 'package:presentation_displays/displays_manager.dart';

import 'main_screen/views/main_display_view.dart';
import 'shared/constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI for immersive dark experience
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(TeleDeckColors.darkBackground),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    const ProviderScope(
      child: TeleDeckApp(),
    ),
  );
}

class TeleDeckApp extends StatefulWidget {
  const TeleDeckApp({super.key});

  @override
  State<TeleDeckApp> createState() => _TeleDeckAppState();
}

class _TeleDeckAppState extends State<TeleDeckApp> {
  DisplayManager? _displayManager;
  bool _secondaryLaunched = false;
  StreamSubscription<int?>? _displaySubscription;

  @override
  void initState() {
    super.initState();
    _initDisplayManager();
  }

  Future<void> _initDisplayManager() async {
    _displayManager = DisplayManager();

    // Get available displays
    final displays = await _displayManager?.getDisplays();

    // Check for secondary display and launch keyboard
    if (displays != null && displays.length > 1) {
      _launchSecondaryScreen(displays[1]);
    }

    // Listen for display changes (e.g., device folding/unfolding)
    // Stream returns 1 for connected, 0 for disconnected
    _displaySubscription =
        _displayManager?.connectedDisplaysChangedStream?.listen((status) async {
      if (status == 1 && !_secondaryLaunched) {
        // New display connected, try to get displays and launch
        final updatedDisplays = await _displayManager?.getDisplays();
        if (updatedDisplays != null && updatedDisplays.length > 1) {
          _launchSecondaryScreen(updatedDisplays[1]);
        }
      }
    });
  }

  Future<void> _launchSecondaryScreen(Display display) async {
    if (_secondaryLaunched) return;

    final displayId = display.displayId;
    if (displayId == null) return;

    try {
      await _displayManager?.showSecondaryDisplay(
        displayId: displayId,
        routerName: 'keyboard',
      );
      _secondaryLaunched = true;
    } catch (e) {
      debugPrint('Failed to launch secondary display: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TeleDeck',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color(TeleDeckColors.darkBackground),
        colorScheme: ColorScheme.dark(
          primary: Color(TeleDeckColors.neonCyan),
          secondary: Color(TeleDeckColors.neonMagenta),
          surface: Color(TeleDeckColors.secondaryBackground),
        ),
      ),
      home: const MainDisplayView(),
    );
  }

  @override
  void dispose() {
    _displaySubscription?.cancel();
    super.dispose();
  }
}
