import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keyboard_bloc/keyboard_bloc.dart';
import 'package:settings_bloc/settings_bloc.dart';
import 'package:tele_deck/screens/keyboard/keyboard_screen.dart';
import 'package:tele_services/tele_services.dart';
import 'package:tele_theme/tele_theme.dart';

/// IME entry point - called by TeleDeckIMEService via DartExecutor
@pragma('vm:entry-point')
void imeMain() {
  // ignore: avoid_print
  print('imeMain: Starting IME entry point');
  WidgetsFlutterBinding.ensureInitialized();
  // ignore: avoid_print
  print('imeMain: WidgetsFlutterBinding initialized');

  // Set system UI for immersive dark experience
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(TeleDeckColors.darkBackground),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize services
  final imeChannelService = ImeChannelService();
  imeChannelService.init();

  final settingsService = SettingsService();

  // ignore: avoid_print
  print('imeMain: About to call runApp');
  runApp(
    TeleDeckKeyboardApp(
      imeChannelService: imeChannelService,
      settingsService: settingsService,
    ),
  );
  // ignore: avoid_print
  print('imeMain: runApp completed');
}

/// Keyboard app - renders on secondary display (or primary fallback) via IME Service
class TeleDeckKeyboardApp extends StatefulWidget {
  final ImeChannelService imeChannelService;
  final SettingsService settingsService;

  const TeleDeckKeyboardApp({
    super.key,
    required this.imeChannelService,
    required this.settingsService,
  });

  @override
  State<TeleDeckKeyboardApp> createState() => _TeleDeckKeyboardAppState();
}

class _TeleDeckKeyboardAppState extends State<TeleDeckKeyboardApp> {
  late final KeyboardBloc _keyboardBloc;
  late final SettingsBloc _settingsBloc;

  @override
  void initState() {
    super.initState();
    // Create blocs here so we can set up callbacks with them
    _keyboardBloc = KeyboardBloc(imeService: widget.imeChannelService);
    _settingsBloc = SettingsBloc(settingsService: widget.settingsService)
      ..add(const SettingsLoaded());
    _setupIMECallbacks();
  }

  void _setupIMECallbacks() {
    // Listen for connection status changes
    widget.imeChannelService.onConnectionStatusChanged = (isConnected) {
      if (mounted) {
        _keyboardBloc.add(KeyboardConnectionChanged(isConnected));
      }
    };

    // Listen for display mode changes
    widget.imeChannelService.onDisplayModeChanged = (mode) {
      if (mounted) {
        _keyboardBloc.add(KeyboardDisplayModeChanged(mode));
      }
    };
  }

  @override
  void dispose() {
    widget.imeChannelService.dispose();
    _keyboardBloc.close();
    _settingsBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: avoid_print
    print('TeleDeckKeyboardApp: build() called');
    return MaterialApp(
      title: 'TeleDeck Keyboard',
      debugShowCheckedModeBanner: false,
      theme: TeleDeckTheme.darkTheme,
      builder: (context, child) {
        // ignore: avoid_print
        print('TeleDeckKeyboardApp: MaterialApp builder called');
        // Provide blocs inside MaterialApp's builder so they're available
        // to all widgets in the Navigator
        return MultiBlocProvider(
          providers: [
            BlocProvider<KeyboardBloc>.value(value: _keyboardBloc),
            BlocProvider<SettingsBloc>.value(value: _settingsBloc),
          ],
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.noScaling,
            ),
            child: child!,
          ),
        );
      },
      home: const KeyboardScreen(),
    );
  }
}
