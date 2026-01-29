import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:keyboard_widgets/keyboard_widgets.dart';

/// Fullscreen keyboard screen - outside the shell navigation.
/// Uses rotation: 0 so the keyboard follows the device's natural orientation.
/// (The keyboardRotation setting is for the dual-screen IME context only.)
class FullscreenKeyboardScreen extends StatelessWidget {
  static const name = 'FullscreenKeyboard';
  static const path = '/keyboard';

  const FullscreenKeyboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return KeyboardView(
      onClose: () => context.pop(),
    );
  }
}
