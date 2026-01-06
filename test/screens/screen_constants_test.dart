import 'package:flutter_test/flutter_test.dart';
import 'package:tele_deck/screens/app/splash_screen.dart';
import 'package:tele_deck/screens/keyboard/keyboard_screen.dart';
import 'package:tele_deck/screens/settings/crash_logs_screen.dart';
import 'package:tele_deck/screens/settings/settings_screen.dart';
import 'package:tele_deck/screens/setup/setup_screen.dart';

void main() {
  group('Screen constants', () {
    test('SplashScreen has correct name and path', () {
      expect(SplashScreen.name, equals('Splash'));
      expect(SplashScreen.path, equals('/'));
    });

    test('SetupScreen has correct name and path', () {
      expect(SetupScreen.name, equals('Setup'));
      expect(SetupScreen.path, equals('/setup'));
    });

    test('SettingsScreen has correct name and path', () {
      expect(SettingsScreen.name, equals('Settings'));
      expect(SettingsScreen.path, equals('/settings'));
    });

    test('CrashLogsScreen has correct name and path', () {
      expect(CrashLogsScreen.name, equals('Crash Logs'));
      expect(CrashLogsScreen.path, equals('crash-logs'));
    });

    test('KeyboardScreen has correct name and path', () {
      expect(KeyboardScreen.name, equals('Keyboard'));
      expect(KeyboardScreen.path, equals('/keyboard'));
    });

    test('CrashLogsScreen path is relative (child route)', () {
      // CrashLogsScreen is a child of SettingsScreen, so path should be relative
      expect(CrashLogsScreen.path.startsWith('/'), isFalse);
    });

    test('Top-level screens have absolute paths', () {
      expect(SplashScreen.path.startsWith('/'), isTrue);
      expect(SetupScreen.path.startsWith('/'), isTrue);
      expect(SettingsScreen.path.startsWith('/'), isTrue);
      expect(KeyboardScreen.path.startsWith('/'), isTrue);
    });
  });
}
