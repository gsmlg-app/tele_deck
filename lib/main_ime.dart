import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'keyboard_screen/views/keyboard_view.dart';
import 'shared/constants.dart';

/// MethodChannel for IME communication with native Android
const imeChannel = MethodChannel('tele_deck/ime');

/// Provider for IME connection status
final imeConnectionProvider = StateProvider<bool>((ref) => false);

/// Provider for current display mode (secondary or primary_fallback)
final displayModeProvider = StateProvider<String>((ref) => 'secondary');

/// Provider for display dimensions
final displayDimensionsProvider = StateProvider<Size>((ref) => Size.zero);

/// IME entry point - called by TeleDeckIMEService via DartExecutor
@pragma('vm:entry-point')
void imeMain() {
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
      child: TeleDeckKeyboardApp(),
    ),
  );
}

/// Keyboard app - renders on secondary display (or primary fallback) via IME Service
class TeleDeckKeyboardApp extends ConsumerStatefulWidget {
  const TeleDeckKeyboardApp({super.key});

  @override
  ConsumerState<TeleDeckKeyboardApp> createState() => _TeleDeckKeyboardAppState();
}

class _TeleDeckKeyboardAppState extends ConsumerState<TeleDeckKeyboardApp> {
  @override
  void initState() {
    super.initState();
    _setupIMEChannel();
  }

  void _setupIMEChannel() {
    // Listen for callbacks from native IME service
    imeChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'connectionStatus':
          final connected = call.arguments['connected'] as bool? ?? false;
          ref.read(imeConnectionProvider.notifier).state = connected;
          break;
        case 'displayModeChanged':
          final mode = call.arguments['mode'] as String? ?? 'secondary';
          final width = call.arguments['displayWidth'] as int? ?? 0;
          final height = call.arguments['displayHeight'] as int? ?? 0;
          ref.read(displayModeProvider.notifier).state = mode;
          ref.read(displayDimensionsProvider.notifier).state = Size(
            width.toDouble(),
            height.toDouble(),
          );
          break;
      }
    });
  }

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
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: child!,
        );
      },
      home: const KeyboardView(),
    );
  }
}
