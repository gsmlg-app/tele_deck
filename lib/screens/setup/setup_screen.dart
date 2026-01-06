import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:settings_widgets/settings_widgets.dart';
import 'package:setup_bloc/setup_bloc.dart';
import 'package:tele_deck/screens/settings/settings_screen.dart';
import 'package:tele_theme/tele_theme.dart';

class SetupScreen extends StatelessWidget {
  static const name = 'Setup';
  static const path = '/setup';

  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<SetupBloc, SetupState>(
      listenWhen: (previous, current) =>
          !previous.isComplete && current.isComplete,
      listener: (context, state) {
        // Navigate to settings when setup completes
        context.goNamed(SettingsScreen.name);
      },
      child: Scaffold(
        backgroundColor: const Color(TeleDeckColors.darkBackground),
        appBar: AppBar(
          backgroundColor: const Color(TeleDeckColors.secondaryBackground),
          title: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Color(TeleDeckColors.neonCyan),
                Color(TeleDeckColors.neonMagenta),
              ],
            ).createShader(bounds),
            child: const Text(
              'TELEDECK',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: SetupGuideView(
              onComplete: () {
                context.goNamed(SettingsScreen.name);
              },
            ),
          ),
        ),
      ),
    );
  }
}
