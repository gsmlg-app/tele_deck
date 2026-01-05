import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keyboard_bloc/keyboard_bloc.dart';
import 'package:keyboard_widgets/keyboard_widgets.dart';
import 'package:settings_bloc/settings_bloc.dart';
import 'package:tele_services/tele_services.dart';
import 'package:tele_theme/tele_theme.dart';

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

  // Initialize services
  final imeChannelService = ImeChannelService();
  imeChannelService.init();

  final settingsService = SettingsService();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<KeyboardBloc>(
          create: (context) => KeyboardBloc(imeService: imeChannelService),
        ),
        BlocProvider<SettingsBloc>(
          create: (context) =>
              SettingsBloc(settingsService: settingsService)..add(const SettingsLoaded()),
        ),
      ],
      child: TeleDeckKeyboardApp(imeChannelService: imeChannelService),
    ),
  );
}

/// Keyboard app - renders on secondary display (or primary fallback) via IME Service
class TeleDeckKeyboardApp extends StatefulWidget {
  final ImeChannelService imeChannelService;

  const TeleDeckKeyboardApp({
    super.key,
    required this.imeChannelService,
  });

  @override
  State<TeleDeckKeyboardApp> createState() => _TeleDeckKeyboardAppState();
}

class _TeleDeckKeyboardAppState extends State<TeleDeckKeyboardApp> {
  @override
  void initState() {
    super.initState();
    _setupIMECallbacks();
  }

  void _setupIMECallbacks() {
    // Listen for connection status changes
    widget.imeChannelService.onConnectionStatusChanged = (isConnected) {
      if (mounted) {
        context.read<KeyboardBloc>().add(KeyboardConnectionChanged(isConnected));
      }
    };

    // Listen for display mode changes
    widget.imeChannelService.onDisplayModeChanged = (mode) {
      if (mounted) {
        context.read<KeyboardBloc>().add(KeyboardDisplayModeChanged(mode));
      }
    };
  }

  @override
  void dispose() {
    widget.imeChannelService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TeleDeck Keyboard',
      debugShowCheckedModeBanner: false,
      theme: TeleDeckTheme.darkTheme,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: child!,
        );
      },
      home: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          final rotation = settingsState.status == SettingsStatus.success
              ? settingsState.settings.keyboardRotation
              : 0;
          return KeyboardView(rotation: rotation);
        },
      ),
    );
  }
}
