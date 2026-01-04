import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'keyboard_screen/views/keyboard_view.dart';
import 'shared/constants.dart';

/// Secondary entry point for the keyboard display
/// This is called by sub_screen when launching on secondary screen
@pragma('vm:entry-point')
void keyboardEntry() {
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
      home: const KeyboardView(),
    );
  }
}
