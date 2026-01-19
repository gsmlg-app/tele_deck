import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:keyboard_widgets/keyboard_widgets.dart';
import 'package:settings_bloc/settings_bloc.dart';

/// Fullscreen keyboard screen - outside the shell navigation
class FullscreenKeyboardScreen extends StatelessWidget {
  static const name = 'FullscreenKeyboard';
  static const path = '/keyboard';

  const FullscreenKeyboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        final rotation = settingsState.status == SettingsStatus.success
            ? settingsState.settings.keyboardRotation
            : 0;
        return KeyboardView(
          rotation: rotation,
          onClose: () => context.pop(),
        );
      },
    );
  }
}
