import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presentation_displays/display.dart';
import 'package:presentation_displays/displays_manager.dart';

import 'main_screen/views/main_display_view.dart';
import 'settings/settings_provider.dart';
import 'settings/views/settings_view.dart';
import 'shared/constants.dart';

/// MethodChannel for receiving keyboard toggle commands from native Android
const _toggleChannel = MethodChannel('app.gsmlg.tele_deck/keyboard_toggle');

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

class TeleDeckApp extends ConsumerStatefulWidget {
  const TeleDeckApp({super.key});

  @override
  ConsumerState<TeleDeckApp> createState() => _TeleDeckAppState();
}

class _TeleDeckAppState extends ConsumerState<TeleDeckApp> {
  DisplayManager? _displayManager;
  Display? _secondaryDisplay;
  bool _secondaryLaunched = false;
  StreamSubscription<int?>? _displaySubscription;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // Initialize settings
    await ref.read(settingsServiceProvider).init();
    await ref.read(appSettingsProvider.notifier).loadSettings();
    ref.read(settingsInitializedProvider.notifier).state = true;

    // Initialize display manager
    await _initDisplayManager();

    // Setup native method channel listener for keyboard toggle
    _setupToggleListener();

    // Check initial visibility based on settings
    final settings = ref.read(appSettingsProvider);
    if (settings.initialKeyboardVisible && _secondaryDisplay != null) {
      _showKeyboard();
    }
  }

  void _setupToggleListener() {
    _toggleChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'toggleKeyboard':
          _toggleKeyboard();
          break;
        case 'showKeyboard':
          _showKeyboard();
          break;
        case 'hideKeyboard':
          _hideKeyboard();
          break;
      }
    });
  }

  void _toggleKeyboard() {
    final isVisible = ref.read(keyboardVisibleProvider);
    if (isVisible) {
      _hideKeyboard();
    } else {
      _showKeyboard();
    }
  }

  void _showKeyboard() {
    if (_secondaryDisplay == null) return;

    final displayId = _secondaryDisplay!.displayId;
    if (displayId == null) return;

    if (!_secondaryLaunched) {
      _displayManager?.showSecondaryDisplay(
        displayId: displayId,
        routerName: 'keyboard',
      );
      _secondaryLaunched = true;
    }

    ref.read(keyboardVisibleProvider.notifier).state = true;
    ref.read(appSettingsProvider.notifier).saveVisibilityState(true);
  }

  void _hideKeyboard() {
    if (_secondaryDisplay == null) return;

    final displayId = _secondaryDisplay!.displayId;
    if (displayId == null) return;

    if (_secondaryLaunched) {
      _displayManager?.hideSecondaryDisplay(displayId: displayId);
      _secondaryLaunched = false;
    }

    ref.read(keyboardVisibleProvider.notifier).state = false;
    ref.read(appSettingsProvider.notifier).saveVisibilityState(false);
  }

  Future<void> _initDisplayManager() async {
    _displayManager = DisplayManager();

    // Get available displays
    final displays = await _displayManager?.getDisplays();

    // Store secondary display reference
    if (displays != null && displays.length > 1) {
      _secondaryDisplay = displays[1];
    }

    // Listen for display changes (e.g., device folding/unfolding)
    _displaySubscription =
        _displayManager?.connectedDisplaysChangedStream?.listen((status) async {
      if (status == 1) {
        // New display connected
        final updatedDisplays = await _displayManager?.getDisplays();
        if (updatedDisplays != null && updatedDisplays.length > 1) {
          _secondaryDisplay = updatedDisplays[1];

          // Auto-show if settings allow
          final settings = ref.read(appSettingsProvider);
          if (settings.initialKeyboardVisible) {
            _showKeyboard();
          }
        }
      } else if (status == 0) {
        // Display disconnected
        _secondaryDisplay = null;
        _secondaryLaunched = false;
        ref.read(keyboardVisibleProvider.notifier).state = false;
      }
    });
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
      initialRoute: '/',
      routes: {
        '/': (context) => MainDisplayView(
              onToggleKeyboard: _toggleKeyboard,
              onShowKeyboard: _showKeyboard,
              onHideKeyboard: _hideKeyboard,
            ),
        '/settings': (context) => const SettingsView(),
      },
    );
  }

  @override
  void dispose() {
    _displaySubscription?.cancel();
    super.dispose();
  }
}
