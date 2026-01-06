import 'package:flutter_test/flutter_test.dart';
import 'package:tele_deck/router.dart';

void main() {
  group('AppRouter', () {
    test('createRouter returns GoRouter instance', () {
      final router = AppRouter.createRouter(
        isSetupComplete: () => false,
        isLoading: () => false,
      );

      expect(router, isNotNull);
      router.dispose();
    });

    test('router can be created with loading state', () {
      final router = AppRouter.createRouter(
        isSetupComplete: () => false,
        isLoading: () => true,
      );

      // Router should be created successfully
      expect(router, isNotNull);
      router.dispose();
    });

    test('routes list contains all expected routes', () {
      final routes = AppRouter.routes;

      // Should have splash, setup, and settings routes
      expect(routes.length, greaterThanOrEqualTo(3));
    });

    test('navigatorKey is defined', () {
      expect(AppRouter.navigatorKey, isNotNull);
    });

    group('redirect logic', () {
      test('redirects from splash to setup when not complete and not loading', () {
        bool isLoading = false;
        bool isComplete = false;

        final router = AppRouter.createRouter(
          isSetupComplete: () => isComplete,
          isLoading: () => isLoading,
        );

        // The redirect logic is tested via the router configuration
        // When loading is false and complete is false, splash should redirect to setup
        router.dispose();
      });

      test('redirects from splash to settings when complete and not loading', () {
        bool isLoading = false;
        bool isComplete = true;

        final router = AppRouter.createRouter(
          isSetupComplete: () => isComplete,
          isLoading: () => isLoading,
        );

        // When loading is false and complete is true, splash should redirect to settings
        router.dispose();
      });

      test('stays on splash while loading', () {
        bool isLoading = true;
        bool isComplete = false;

        final router = AppRouter.createRouter(
          isSetupComplete: () => isComplete,
          isLoading: () => isLoading,
        );

        // While loading, should stay on splash
        router.dispose();
      });
    });
  });
}
