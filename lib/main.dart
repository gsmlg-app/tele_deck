import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'logging/views/crash_log_viewer.dart';
import 'settings/settings_provider.dart';
import 'settings/views/settings_view.dart';
import 'settings/views/setup_guide_view.dart';
import 'shared/constants.dart';

/// Provider to track if we should show crash logs (from deep link)
final showCrashLogsProvider = StateProvider<bool>((ref) => false);

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
      child: TeleDeckLauncherApp(),
    ),
  );
}

/// Launcher app - shows setup guide or settings
class TeleDeckLauncherApp extends ConsumerStatefulWidget {
  const TeleDeckLauncherApp({super.key});

  @override
  ConsumerState<TeleDeckLauncherApp> createState() =>
      _TeleDeckLauncherAppState();
}

class _TeleDeckLauncherAppState extends ConsumerState<TeleDeckLauncherApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupMethodChannelListener();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh IME status when app resumes (user might have changed settings)
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(setupGuideProvider);
    }
  }

  void _setupMethodChannelListener() {
    const settingsChannel = MethodChannel('app.gsmlg.tele_deck/settings');
    settingsChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onIMEStatusChanged':
          // Refresh setup guide when IME status changes
          ref.invalidate(setupGuideProvider);
          break;
        case 'viewCrashLogs':
          // Deep link from crash notification
          ref.read(showCrashLogsProvider.notifier).state = true;
          break;
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
        scaffoldBackgroundColor: const Color(TeleDeckColors.darkBackground),
        colorScheme: ColorScheme.dark(
          primary: const Color(TeleDeckColors.neonCyan),
          secondary: const Color(TeleDeckColors.neonMagenta),
          surface: const Color(TeleDeckColors.secondaryBackground),
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
      home: const _LauncherHome(),
    );
  }
}

/// Home widget that decides which view to show based on IME status
class _LauncherHome extends ConsumerWidget {
  const _LauncherHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showCrashLogs = ref.watch(showCrashLogsProvider);
    final setupStateAsync = ref.watch(setupGuideProvider);

    // Handle deep link to crash logs
    if (showCrashLogs) {
      // Reset the flag and show crash logs
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(showCrashLogsProvider.notifier).state = false;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const CrashLogViewer()),
        );
      });
    }

    return setupStateAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(TeleDeckColors.darkBackground),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: const Color(TeleDeckColors.darkBackground),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error loading IME status',
                style: TextStyle(color: Colors.red.shade300),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(setupGuideProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (setupState) {
        // If setup is complete, show settings view
        if (setupState.isComplete) {
          return const SettingsView();
        }
        // Otherwise show setup guide
        return SetupGuideView(
          onComplete: () {
            // Refresh to transition to settings view
            ref.invalidate(setupGuideProvider);
          },
        );
      },
    );
  }
}
