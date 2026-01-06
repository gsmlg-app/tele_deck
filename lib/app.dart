import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:setup_bloc/setup_bloc.dart';
import 'package:tele_deck/router.dart';
import 'package:tele_services/tele_services.dart';
import 'package:tele_theme/tele_theme.dart';

/// Launcher app - shows shell with Home, Logs, and Settings tabs
class TeleDeckLauncherApp extends StatefulWidget {
  final ImeChannelService imeChannelService;

  const TeleDeckLauncherApp({super.key, required this.imeChannelService});

  @override
  State<TeleDeckLauncherApp> createState() => _TeleDeckLauncherAppState();
}

class _TeleDeckLauncherAppState extends State<TeleDeckLauncherApp>
    with WidgetsBindingObserver {
  late final GoRouter _router;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupMethodChannelListener();

    // Create router with loading state getter
    _router = AppRouter.createRouter(isLoading: () => _isLoading);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.imeChannelService.dispose();
    _router.dispose();
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
          // Refresh setup status when IME status changes
          if (mounted) {
            context.read<SetupBloc>().add(const SetupCheckRequested());
          }
          break;
        case 'viewCrashLogs':
          // Deep link from crash notification - logs is now a tab in shell
          // TODO: Add tab navigation support if needed
          break;
      }
    });
  }

  void _onSetupStateChanged(SetupState state) {
    final wasLoading = _isLoading;

    setState(() {
      _isLoading = state.isLoading;
    });

    // Trigger route refresh when loading state changes
    if (wasLoading != _isLoading) {
      _router.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SetupBloc, SetupState>(
      listener: (context, state) => _onSetupStateChanged(state),
      child: MaterialApp.router(
        title: 'TeleDeck',
        debugShowCheckedModeBanner: false,
        theme: TeleDeckTheme.darkTheme,
        routerConfig: _router,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.noScaling),
            child: child!,
          );
        },
      ),
    );
  }
}
