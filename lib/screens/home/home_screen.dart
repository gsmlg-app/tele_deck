import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:setup_bloc/setup_bloc.dart';
import 'package:tele_theme/tele_theme.dart';

/// Home screen showing IME status with conditional enable/activate buttons
class HomeScreen extends StatelessWidget {
  static const name = 'Home';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(TeleDeckColors.darkBackground),
      appBar: AppBar(
        backgroundColor: const Color(TeleDeckColors.secondaryBackground),
        title: Text(
          'TELEDECK',
          style: GoogleFonts.robotoMono(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(TeleDeckColors.neonCyan),
            letterSpacing: 4,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Color(TeleDeckColors.neonCyan),
            ),
            onPressed: () =>
                context.read<SetupBloc>().add(const SetupCheckRequested()),
            tooltip: 'Refresh Status',
          ),
        ],
      ),
      body: BlocBuilder<SetupBloc, SetupState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(TeleDeckColors.neonCyan),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                _buildImeStatusCard(state),
                const SizedBox(height: 32),
                _buildActionSection(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildImeStatusCard(SetupState state) {
    final isEnabled = state.imeEnabled;
    final isActive = state.imeActive;

    final statusText = isActive
        ? 'Active'
        : isEnabled
        ? 'Enabled (not selected)'
        : 'Not Enabled';

    final statusColor = isActive
        ? Colors.green
        : isEnabled
        ? Colors.orange
        : Colors.red;

    final statusIcon = isActive
        ? Icons.check_circle
        : isEnabled
        ? Icons.warning_amber
        : Icons.error_outline;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(TeleDeckColors.secondaryBackground),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.2),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 48),
          ),
          const SizedBox(height: 16),
          Text(
            'TeleDeck Keyboard',
            style: GoogleFonts.robotoMono(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(TeleDeckColors.textPrimary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            statusText,
            style: GoogleFonts.robotoMono(
              fontSize: 16,
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection(BuildContext context, SetupState state) {
    final bloc = context.read<SetupBloc>();

    // If not enabled, show Enable button
    if (!state.imeEnabled) {
      return _ActionButton(
        title: 'Enable TeleDeck Keyboard',
        subtitle: 'Open system settings to enable this keyboard',
        icon: Icons.settings,
        onTap: () => bloc.add(const SetupOpenImeSettings()),
        isHighlighted: true,
      );
    }

    // If enabled but not active, show Activate button
    if (!state.imeActive) {
      return _ActionButton(
        title: 'Activate TeleDeck Keyboard',
        subtitle: 'Switch to TeleDeck as your active input method',
        icon: Icons.keyboard,
        onTap: () => bloc.add(const SetupOpenImePicker()),
        isHighlighted: true,
      );
    }

    // If both done, show success message
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(TeleDeckColors.secondaryBackground),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(TeleDeckColors.neonCyan).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.celebration,
            color: const Color(TeleDeckColors.neonMagenta),
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            'Ready to Use!',
            style: GoogleFonts.robotoMono(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(TeleDeckColors.textPrimary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'TeleDeck is your active keyboard.\nOpen any text field to start typing.',
            textAlign: TextAlign.center,
            style: GoogleFonts.robotoMono(
              fontSize: 12,
              color: const Color(
                TeleDeckColors.textPrimary,
              ).withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          // Optional: Switch to another keyboard button
          TextButton.icon(
            onPressed: () => bloc.add(const SetupOpenImePicker()),
            icon: const Icon(
              Icons.swap_horiz,
              size: 18,
              color: Color(TeleDeckColors.neonCyan),
            ),
            label: Text(
              'Switch Keyboard',
              style: GoogleFonts.robotoMono(
                fontSize: 12,
                color: const Color(TeleDeckColors.neonCyan),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isHighlighted;

  const _ActionButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isHighlighted
          ? const Color(TeleDeckColors.neonCyan).withValues(alpha: 0.15)
          : const Color(TeleDeckColors.secondaryBackground),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHighlighted
                  ? const Color(TeleDeckColors.neonCyan)
                  : const Color(TeleDeckColors.neonCyan).withValues(alpha: 0.3),
              width: isHighlighted ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(
                    TeleDeckColors.neonCyan,
                  ).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(TeleDeckColors.neonCyan),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.robotoMono(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(TeleDeckColors.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.robotoMono(
                        fontSize: 12,
                        color: const Color(
                          TeleDeckColors.textPrimary,
                        ).withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: const Color(
                  TeleDeckColors.neonCyan,
                ).withValues(alpha: 0.5),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
