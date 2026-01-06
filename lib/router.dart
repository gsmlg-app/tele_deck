import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tele_deck/screens/app/splash_screen.dart';
import 'package:tele_deck/screens/settings/crash_logs_screen.dart';
import 'package:tele_deck/screens/settings/settings_screen.dart';
import 'package:tele_deck/screens/setup/setup_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'routerKey',
  );

  /// Create router - starts at splash, then redirects based on setup status
  static GoRouter createRouter({
    required bool Function() isSetupComplete,
    required bool Function() isLoading,
  }) {
    return GoRouter(
      navigatorKey: navigatorKey,
      debugLogDiagnostics: true,
      initialLocation: SplashScreen.path,
      routes: routes,
      redirect: (context, state) {
        final path = state.uri.path;

        // While loading, stay on splash
        if (isLoading()) {
          return path == SplashScreen.path ? null : SplashScreen.path;
        }

        // After loading, redirect from splash to appropriate screen
        if (path == SplashScreen.path) {
          return isSetupComplete() ? SettingsScreen.path : SetupScreen.path;
        }

        // If on setup but already complete, go to settings
        if (path == SetupScreen.path && isSetupComplete()) {
          return SettingsScreen.path;
        }

        return null;
      },
      errorBuilder: (context, state) {
        return Scaffold(
          body: Center(
            child: Text('Route not found: ${state.uri}'),
          ),
        );
      },
    );
  }

  static List<RouteBase> routes = [
    GoRoute(
      name: SplashScreen.name,
      path: SplashScreen.path,
      pageBuilder: (context, state) {
        return NoTransitionPage<void>(
          key: state.pageKey,
          restorationId: state.pageKey.value,
          child: const SplashScreen(),
        );
      },
    ),
    GoRoute(
      name: SetupScreen.name,
      path: SetupScreen.path,
      pageBuilder: (context, state) {
        return NoTransitionPage<void>(
          key: state.pageKey,
          restorationId: state.pageKey.value,
          child: const SetupScreen(),
        );
      },
    ),
    GoRoute(
      name: SettingsScreen.name,
      path: SettingsScreen.path,
      pageBuilder: (context, state) {
        return NoTransitionPage<void>(
          key: state.pageKey,
          restorationId: state.pageKey.value,
          child: const SettingsScreen(),
        );
      },
      routes: [
        GoRoute(
          name: CrashLogsScreen.name,
          path: CrashLogsScreen.path,
          pageBuilder: (context, state) {
            return MaterialPage<void>(
              key: state.pageKey,
              restorationId: state.pageKey.value,
              child: const CrashLogsScreen(),
            );
          },
        ),
      ],
    ),
  ];
}
