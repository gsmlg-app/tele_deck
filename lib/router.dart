import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tele_deck/screens/app/shell_screen.dart';
import 'package:tele_deck/screens/app/splash_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'routerKey');

  /// Create router - starts at splash, then redirects to shell after loading
  static GoRouter createRouter({required bool Function() isLoading}) {
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

        // After loading, redirect from splash to shell
        if (path == SplashScreen.path) {
          return ShellScreen.path;
        }

        return null;
      },
      errorBuilder: (context, state) {
        return Scaffold(
          body: Center(child: Text('Route not found: ${state.uri}')),
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
      name: ShellScreen.name,
      path: ShellScreen.path,
      pageBuilder: (context, state) {
        return NoTransitionPage<void>(
          key: state.pageKey,
          restorationId: state.pageKey.value,
          child: const ShellScreen(),
        );
      },
    ),
  ];
}
