import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sub_screen/model.dart';
import 'package:sub_screen/sub_screen.dart';

import 'keyboard_screen/views/keyboard_view.dart';
import 'main_screen/views/main_display_view.dart';
import 'settings/settings_provider.dart';
import 'settings/views/settings_view.dart';
import 'shared/constants.dart';

/// Secondary entry point for the keyboard display
/// This MUST be in the same library as main() for the engine to find it
@pragma('vm:entry-point')
void keyboardEntry() {
  WidgetsFlutterBinding.ensureInitialized();

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
      child: KeyboardApp(),
    ),
  );
}

/// Keyboard app for secondary display
class KeyboardApp extends StatelessWidget {
  const KeyboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TeleDeck Keyboard',
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
      home: const KeyboardView(),
    );
  }
}

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
  int? _secondaryDisplayId;

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

    // Initialize display monitoring
    await _initDisplayMonitoring();

    // Setup native method channel listener for keyboard toggle
    _setupToggleListener();

    // Check initial visibility based on settings
    final settings = ref.read(appSettingsProvider);
    if (settings.initialKeyboardVisible && _secondaryDisplayId != null) {
      ref.read(keyboardVisibleProvider.notifier).state = true;
    }
  }

  Future<void> _initDisplayMonitoring() async {
    // Set up display change listeners
    SubScreenPlugin.setOnMultiDisplayListener(OnMultiDisplayListener(
      onDisplayAdded: (Display display) {
        if (!display.isDefault) {
          setState(() {
            _secondaryDisplayId = display.id;
          });
          // Auto-show keyboard if settings allow
          final settings = ref.read(appSettingsProvider);
          if (settings.initialKeyboardVisible) {
            ref.read(keyboardVisibleProvider.notifier).state = true;
          }
        }
      },
      onDisplayChanged: (Display display) {
        // Handle display changes if needed
      },
      onDisplayRemoved: (int displayId) {
        if (displayId == _secondaryDisplayId) {
          setState(() {
            _secondaryDisplayId = null;
          });
          ref.read(keyboardVisibleProvider.notifier).state = false;
        }
      },
    ));

    // Check for existing secondary displays
    final displays = await SubScreenPlugin.getDisplays();
    for (var display in displays) {
      if (!display.isDefault) {
        setState(() {
          _secondaryDisplayId = display.id;
        });
        break;
      }
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
    if (_secondaryDisplayId == null) return;

    ref.read(keyboardVisibleProvider.notifier).state = true;
    ref.read(appSettingsProvider.notifier).saveVisibilityState(true);
  }

  void _hideKeyboard() {
    if (_secondaryDisplayId == null) return;

    ref.read(keyboardVisibleProvider.notifier).state = false;
    ref.read(appSettingsProvider.notifier).saveVisibilityState(false);
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
}
