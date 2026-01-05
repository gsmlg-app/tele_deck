import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:common_widgets/common_widgets.dart';
import 'package:settings_bloc/settings_bloc.dart';
import 'package:settings_widgets/settings_widgets.dart';
import 'package:setup_bloc/setup_bloc.dart';
import 'package:tele_services/tele_services.dart';
import 'package:tele_theme/tele_theme.dart';

// Export imeMain entry point to ensure it's included in the AOT build
export 'main_ime.dart' show imeMain;

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

  // Initialize services
  final imeChannelService = ImeChannelService();
  imeChannelService.init();

  final settingsService = SettingsService();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<SettingsBloc>(
          create: (context) =>
              SettingsBloc(settingsService: settingsService)..add(const SettingsLoaded()),
        ),
        BlocProvider<SetupBloc>(
          create: (context) =>
              SetupBloc(imeService: imeChannelService)..add(const SetupCheckRequested()),
        ),
      ],
      child: TeleDeckLauncherApp(imeChannelService: imeChannelService),
    ),
  );
}

/// Launcher app - shows setup guide or settings
class TeleDeckLauncherApp extends StatefulWidget {
  final ImeChannelService imeChannelService;

  const TeleDeckLauncherApp({
    super.key,
    required this.imeChannelService,
  });

  @override
  State<TeleDeckLauncherApp> createState() => _TeleDeckLauncherAppState();
}

class _TeleDeckLauncherAppState extends State<TeleDeckLauncherApp>
    with WidgetsBindingObserver {
  bool _showCrashLogs = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupMethodChannelListener();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.imeChannelService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh IME status when app resumes (user might have changed settings)
    if (state == AppLifecycleState.resumed) {
      context.read<SetupBloc>().add(const SetupCheckRequested());
    }
  }

  void _setupMethodChannelListener() {
    const settingsChannel = MethodChannel('app.gsmlg.tele_deck/settings');
    settingsChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onIMEStatusChanged':
          // Refresh setup guide when IME status changes
          if (mounted) {
            context.read<SetupBloc>().add(const SetupCheckRequested());
          }
          break;
        case 'viewCrashLogs':
          // Deep link from crash notification
          setState(() => _showCrashLogs = true);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TeleDeck',
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
      home: _LauncherHome(
        showCrashLogs: _showCrashLogs,
        onCrashLogsShown: () => setState(() => _showCrashLogs = false),
      ),
    );
  }
}

/// Home widget that decides which view to show based on IME status
class _LauncherHome extends StatelessWidget {
  final bool showCrashLogs;
  final VoidCallback onCrashLogsShown;

  const _LauncherHome({
    required this.showCrashLogs,
    required this.onCrashLogsShown,
  });

  @override
  Widget build(BuildContext context) {
    // Handle deep link to crash logs
    if (showCrashLogs) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onCrashLogsShown();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const CrashLogViewer()),
        );
      });
    }

    return BlocBuilder<SetupBloc, SetupState>(
      builder: (context, setupState) {
        // If setup is complete, show settings view
        if (setupState.isComplete) {
          return SettingsView(
            onViewCrashLogs: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CrashLogViewer()),
              );
            },
          );
        }

        // Otherwise show setup guide
        return Scaffold(
          backgroundColor: const Color(TeleDeckColors.darkBackground),
          appBar: AppBar(
            backgroundColor: const Color(TeleDeckColors.secondaryBackground),
            title: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(TeleDeckColors.neonCyan),
                  Color(TeleDeckColors.neonMagenta),
                ],
              ).createShader(bounds),
              child: const Text(
                'TELEDECK',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
            ),
            centerTitle: true,
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: SetupGuideView(
                onComplete: () {
                  // Navigate to settings when setup is complete
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => SettingsView(
                        onViewCrashLogs: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (context) => const CrashLogViewer()),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
