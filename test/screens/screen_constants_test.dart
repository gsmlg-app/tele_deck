import 'package:flutter_test/flutter_test.dart';
import 'package:tele_deck/screens/app/shell_screen.dart';
import 'package:tele_deck/screens/app/splash_screen.dart';
import 'package:tele_deck/screens/home/home_screen.dart';
import 'package:tele_deck/screens/keyboard/keyboard_screen.dart';
import 'package:tele_deck/screens/logs/log_screen.dart';
import 'package:tele_deck/screens/settings/setting_screen.dart';

void main() {
  group('Screen constants', () {
    test('SplashScreen has correct name and path', () {
      expect(SplashScreen.name, equals('Splash'));
      expect(SplashScreen.path, equals('/'));
    });

    test('ShellScreen has correct name and path', () {
      expect(ShellScreen.name, equals('Shell'));
      expect(ShellScreen.path, equals('/shell'));
    });

    test('HomeScreen has correct name', () {
      expect(HomeScreen.name, equals('Home'));
    });

    test('LogScreen has correct name', () {
      expect(LogScreen.name, equals('Logs'));
    });

    test('SettingScreen has correct name', () {
      expect(SettingScreen.name, equals('Settings'));
    });

    test('KeyboardScreen has correct name and path', () {
      expect(KeyboardScreen.name, equals('Keyboard'));
      expect(KeyboardScreen.path, equals('/keyboard'));
    });

    test('Top-level screens have absolute paths', () {
      expect(SplashScreen.path.startsWith('/'), isTrue);
      expect(ShellScreen.path.startsWith('/'), isTrue);
      expect(KeyboardScreen.path.startsWith('/'), isTrue);
    });
  });
}
