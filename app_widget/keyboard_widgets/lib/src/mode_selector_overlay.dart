import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keyboard_bloc/keyboard_bloc.dart';
import 'package:tele_theme/tele_theme.dart';

/// Inline mode selector overlay for switching keyboard modes
class ModeSelectorOverlay extends StatelessWidget {
  const ModeSelectorOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KeyboardBloc, KeyboardState>(
      builder: (context, state) {
        return Container(
          color: const Color(
            TeleDeckColors.darkBackground,
          ).withValues(alpha: 0.95),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(TeleDeckColors.secondaryBackground),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(
                    TeleDeckColors.neonCyan,
                  ).withValues(alpha: 0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      TeleDeckColors.neonCyan,
                    ).withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'KEYBOARD MODE',
                    style: GoogleFonts.robotoMono(
                      color: const Color(TeleDeckColors.neonCyan),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ModeButton(
                        icon: Icons.keyboard,
                        label: 'Standard',
                        mode: KeyboardMode.standard,
                        isSelected: state.mode == KeyboardMode.standard,
                      ),
                      const SizedBox(width: 16),
                      _ModeButton(
                        icon: Icons.dialpad,
                        label: 'Numpad',
                        mode: KeyboardMode.numpad,
                        isSelected: state.mode == KeyboardMode.numpad,
                      ),
                      const SizedBox(width: 16),
                      _ModeButton(
                        icon: Icons.emoji_emotions,
                        label: 'Emoji',
                        mode: KeyboardMode.emoji,
                        isSelected: state.mode == KeyboardMode.emoji,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Close button
                  GestureDetector(
                    onTap: () {
                      context.read<KeyboardBloc>().add(
                        const KeyboardModeSelectorChanged(false),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(TeleDeckColors.neonMagenta),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'CLOSE',
                        style: GoogleFonts.robotoMono(
                          color: const Color(TeleDeckColors.neonMagenta),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final KeyboardMode mode;
  final bool isSelected;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.mode,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<KeyboardBloc>().add(KeyboardModeChanged(mode));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(TeleDeckColors.neonCyan).withValues(alpha: 0.2)
              : const Color(TeleDeckColors.keySurface),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(TeleDeckColors.neonCyan)
                : const Color(TeleDeckColors.neonCyan).withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(
                      TeleDeckColors.neonCyan,
                    ).withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(TeleDeckColors.neonCyan)
                  : const Color(TeleDeckColors.textPrimary),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.robotoMono(
                color: isSelected
                    ? const Color(TeleDeckColors.neonCyan)
                    : const Color(TeleDeckColors.textPrimary),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
