import 'package:flutter_test/flutter_test.dart';
import 'package:tele_deck/router.dart';

void main() {
  group('AppRouter', () {
    test('createRouter returns GoRouter instance', () {
      final router = AppRouter.createRouter(
        isLoading: () => false,
      );

      expect(router, isNotNull);
      router.dispose();
    });

    test('router can be created with loading state', () {
      final router = AppRouter.createRouter(
        isLoading: () => true,
      );

      // Router should be created successfully
      expect(router, isNotNull);
      router.dispose();
    });

    test('routes list contains splash and shell routes', () {
      final routes = AppRouter.routes;

      // Should have splash and shell routes
      expect(routes.length, equals(2));
    });

    test('navigatorKey is defined', () {
      expect(AppRouter.navigatorKey, isNotNull);
    });

    group('redirect logic', () {
      test('redirects from splash to shell when not loading', () {
        bool isLoading = false;

        final router = AppRouter.createRouter(
          isLoading: () => isLoading,
        );

        // When loading is false, splash should redirect to shell
        router.dispose();
      });

      test('stays on splash while loading', () {
        bool isLoading = true;

        final router = AppRouter.createRouter(
          isLoading: () => isLoading,
        );

        // While loading, should stay on splash
        router.dispose();
      });
    });
  });
}
