import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presentation_displays/secondary_display.dart';

import 'keyboard_screen/views/keyboard_view.dart';
import 'shared/constants.dart';

/// Secondary entry point for the keyboard display
/// This is called by presentation_displays when launching on secondary screen
@pragma('vm:entry-point')
void secondaryMain() {
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
      child: KeyboardApp(),
    ),
  );
}

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
      home: const KeyboardDisplayWrapper(),
    );
  }
}

/// Secondary display widget that handles presentation_displays callbacks
class KeyboardDisplayWrapper extends StatelessWidget {
  const KeyboardDisplayWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return SecondaryDisplay(
      callback: (argument) {
        // Handle data transfer from main display if needed
        debugPrint('Received data from main display: $argument');
      },
      child: const KeyboardView(),
    );
  }
}
