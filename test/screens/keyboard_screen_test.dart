import 'package:flutter_test/flutter_test.dart';
import 'package:tele_deck/screens/keyboard/keyboard_screen.dart';

void main() {
  group('KeyboardScreen', () {
    test('has correct name constant', () {
      expect(KeyboardScreen.name, equals('Keyboard'));
    });

    test('has correct path constant', () {
      expect(KeyboardScreen.path, equals('/keyboard'));
    });

    test('path is absolute', () {
      expect(KeyboardScreen.path.startsWith('/'), isTrue);
    });
  });
}
