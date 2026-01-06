import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keyboard_widgets/keyboard_widgets.dart';
import 'package:settings_bloc/settings_bloc.dart';

class KeyboardScreen extends StatelessWidget {
  static const name = 'Keyboard';
  static const path = '/keyboard';

  const KeyboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        final rotation = settingsState.status == SettingsStatus.success
            ? settingsState.settings.keyboardRotation
            : 0;
        return KeyboardView(rotation: rotation);
      },
    );
  }
}
