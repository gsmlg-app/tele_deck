import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keyboard_bloc/keyboard_bloc.dart';
import 'package:keyboard_widgets/keyboard_widgets.dart';
import 'package:settings_bloc/settings_bloc.dart';

class KeyboardScreen extends StatelessWidget {
  static const name = 'Keyboard';
  static const path = '/keyboard';

  const KeyboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsBloc, SettingsState>(
      listenWhen: (previous, current) {
        // Listen when settings loaded or keyboard type changed
        if (previous.status != SettingsStatus.success &&
            current.status == SettingsStatus.success) {
          return true;
        }
        if (previous.status == SettingsStatus.success &&
            current.status == SettingsStatus.success &&
            previous.settings.keyboardType != current.settings.keyboardType) {
          return true;
        }
        return false;
      },
      listener: (context, settingsState) {
        // Sync keyboard type to KeyboardBloc when settings change
        if (settingsState.status == SettingsStatus.success) {
          context.read<KeyboardBloc>().add(
                KeyboardTypeChanged(settingsState.settings.keyboardType),
              );
        }
      },
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          final rotation = settingsState.status == SettingsStatus.success
              ? settingsState.settings.keyboardRotation
              : 0;
          return KeyboardView(rotation: rotation);
        },
      ),
    );
  }
}
