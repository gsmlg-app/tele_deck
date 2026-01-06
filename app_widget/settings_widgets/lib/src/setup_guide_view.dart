import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:setup_bloc/setup_bloc.dart';
import 'package:tele_theme/tele_theme.dart';

/// BLoC-based setup guide view for IME onboarding
class SetupGuideView extends StatelessWidget {
  final VoidCallback? onComplete;

  const SetupGuideView({super.key, this.onComplete});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SetupBloc, SetupState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(TeleDeckColors.secondaryBackground),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(
                TeleDeckColors.neonCyan,
              ).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepIndicator(state.currentStep),
              const SizedBox(height: 24),
              _buildStepContent(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepIndicator(int currentStep) {
    return Row(
      children: [
        for (int i = 1; i <= 3; i++) ...[
          _StepDot(stepNumber: i, currentStep: currentStep),
          if (i < 3) _StepConnector(isActive: currentStep > i),
        ],
      ],
    );
  }

  Widget _buildStepContent(BuildContext context, SetupState state) {
    final bloc = context.read<SetupBloc>();

    String title;
    String description;
    String buttonText;
    VoidCallback? onAction;

    switch (state.currentStep) {
      case 1:
        title = 'Enable TeleDeck Keyboard';
        description =
            "Enable TeleDeck in your device's keyboard settings to use it as an input method.";
        buttonText = 'Open Keyboard Settings';
        onAction = () => bloc.add(const SetupOpenImeSettings());
        break;
      case 2:
        title = 'Switch to TeleDeck';
        description =
            'Switch to TeleDeck as your active keyboard to start using it.';
        buttonText = 'Switch Keyboard';
        onAction = () => bloc.add(const SetupOpenImePicker());
        break;
      case 3:
        title = 'Setup Complete';
        description =
            'TeleDeck is now your active keyboard. Configure your preferences below.';
        buttonText = 'Go to Settings';
        onAction = onComplete;
        break;
      default:
        title = '';
        description = '';
        buttonText = '';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STEP ${state.currentStep}',
          style: GoogleFonts.robotoMono(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: const Color(TeleDeckColors.neonMagenta),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.robotoMono(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(TeleDeckColors.textPrimary),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: GoogleFonts.robotoMono(
            fontSize: 14,
            color: const Color(
              TeleDeckColors.textPrimary,
            ).withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 24),
        _ActionButton(text: buttonText, onTap: onAction),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final int stepNumber;
  final int currentStep;

  const _StepDot({required this.stepNumber, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final isActive = stepNumber <= currentStep;
    final isCurrent = stepNumber == currentStep;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive
            ? const Color(TeleDeckColors.neonCyan)
            : const Color(TeleDeckColors.keySurface),
        border: Border.all(
          color: isCurrent
              ? const Color(TeleDeckColors.neonMagenta)
              : const Color(TeleDeckColors.neonCyan).withValues(alpha: 0.3),
          width: isCurrent ? 2 : 1,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: const Color(
                    TeleDeckColors.neonCyan,
                  ).withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          '$stepNumber',
          style: GoogleFonts.robotoMono(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isActive
                ? const Color(TeleDeckColors.darkBackground)
                : const Color(TeleDeckColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

class _StepConnector extends StatelessWidget {
  final bool isActive;

  const _StepConnector({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: isActive
            ? const Color(TeleDeckColors.neonCyan)
            : const Color(TeleDeckColors.keySurface),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const _ActionButton({required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(TeleDeckColors.neonCyan).withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(TeleDeckColors.neonCyan),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.robotoMono(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(TeleDeckColors.neonCyan),
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
