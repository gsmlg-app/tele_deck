import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:settings_bloc/settings_bloc.dart';
import 'package:setup_bloc/setup_bloc.dart';
import 'package:tele_theme/tele_theme.dart';

/// BLoC-based settings view for launcher app
class SettingsView extends StatelessWidget {
  final VoidCallback? onViewCrashLogs;

  const SettingsView({super.key, this.onViewCrashLogs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(TeleDeckColors.darkBackground),
      appBar: AppBar(
        backgroundColor: const Color(TeleDeckColors.secondaryBackground),
        title: Text(
          'TELEDECK SETTINGS',
          style: GoogleFonts.robotoMono(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(TeleDeckColors.neonCyan),
            letterSpacing: 3,
          ),
        ),
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Color(TeleDeckColors.neonCyan),
                ),
                onPressed: () => context.pop(),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Color(TeleDeckColors.neonCyan),
            ),
            onPressed: () =>
                context.read<SetupBloc>().add(const SetupCheckRequested()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('IME SETUP'),
          const _IMEStatusCard(),
          const SizedBox(height: 16),
          const _SetupActions(),
          const SizedBox(height: 24),
          _buildSectionHeader('DISPLAY'),
          const _RotationSetting(),
          const SizedBox(height: 24),
          _buildSectionHeader('PHYSICAL BUTTON BINDING'),
          _buildInfoTile(
            title: 'Toggle Keyboard',
            subtitle: 'app.gsmlg.tele_deck.TOGGLE_KEYBOARD',
            icon: Icons.keyboard_double_arrow_up,
          ),
          _buildInfoTile(
            title: 'Show Keyboard',
            subtitle: 'app.gsmlg.tele_deck.SHOW_KEYBOARD',
            icon: Icons.keyboard_arrow_up,
          ),
          _buildInfoTile(
            title: 'Hide Keyboard',
            subtitle: 'app.gsmlg.tele_deck.HIDE_KEYBOARD',
            icon: Icons.keyboard_arrow_down,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Bind these actions to physical buttons on your device.',
              style: GoogleFonts.robotoMono(
                fontSize: 12,
                color: const Color(
                  TeleDeckColors.textPrimary,
                ).withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('DIAGNOSTICS'),
          _buildActionButton(
            title: 'View Crash Logs',
            subtitle: 'View keyboard crash reports and error details',
            icon: Icons.bug_report,
            onTap: onViewCrashLogs,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('ABOUT'),
          _buildInfoTile(
            title: 'TeleDeck',
            subtitle: 'System IME Keyboard v1.0.0',
            icon: Icons.info_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.robotoMono(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: const Color(TeleDeckColors.neonMagenta),
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(TeleDeckColors.secondaryBackground),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(TeleDeckColors.neonCyan).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(TeleDeckColors.neonCyan)),
        title: Text(
          title,
          style: GoogleFonts.robotoMono(
            fontSize: 14,
            color: const Color(TeleDeckColors.textPrimary),
          ),
        ),
        subtitle: SelectableText(
          subtitle,
          style: GoogleFonts.robotoMono(
            fontSize: 11,
            color: const Color(TeleDeckColors.neonCyan).withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
    bool isHighlighted = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: isHighlighted
            ? const Color(TeleDeckColors.neonCyan).withValues(alpha: 0.15)
            : const Color(TeleDeckColors.secondaryBackground),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isHighlighted
                    ? const Color(TeleDeckColors.neonCyan)
                    : const Color(
                        TeleDeckColors.neonCyan,
                      ).withValues(alpha: 0.2),
                width: isHighlighted ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: const Color(TeleDeckColors.neonCyan),
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.robotoMono(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(TeleDeckColors.textPrimary),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.robotoMono(
                          fontSize: 11,
                          color: const Color(
                            TeleDeckColors.textPrimary,
                          ).withValues(alpha: 0.6),
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
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// IME Status Card
class _IMEStatusCard extends StatelessWidget {
  const _IMEStatusCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SetupBloc, SetupState>(
      builder: (context, state) {
        final isEnabled = state.imeEnabled;
        final isSelected = state.imeActive;

        final status = isSelected
            ? 'Active'
            : isEnabled
            ? 'Enabled (not selected)'
            : 'Not Enabled';
        final statusColor = isSelected
            ? Colors.green
            : isEnabled
            ? Colors.orange
            : Colors.red;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(TeleDeckColors.secondaryBackground),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isSelected
                      ? Icons.check_circle
                      : isEnabled
                      ? Icons.warning
                      : Icons.error,
                  color: statusColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TeleDeck Keyboard',
                      style: GoogleFonts.robotoMono(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(TeleDeckColors.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status,
                      style: GoogleFonts.robotoMono(
                        fontSize: 14,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Setup action buttons
class _SetupActions extends StatelessWidget {
  const _SetupActions();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SetupBloc, SetupState>(
      builder: (context, state) {
        final bloc = context.read<SetupBloc>();

        return Column(
          children: [
            if (!state.imeEnabled)
              _ActionButton(
                title: 'Enable TeleDeck Keyboard',
                subtitle: 'Open system settings to enable this keyboard',
                icon: Icons.settings,
                onTap: () => bloc.add(const SetupOpenImeSettings()),
                isHighlighted: true,
              ),
            if (state.imeEnabled && !state.imeActive)
              _ActionButton(
                title: 'Select TeleDeck Keyboard',
                subtitle: 'Choose TeleDeck as your input method',
                icon: Icons.keyboard,
                onTap: () => bloc.add(const SetupOpenImePicker()),
                isHighlighted: true,
              ),
            if (state.imeEnabled)
              _ActionButton(
                title: 'Switch Input Method',
                subtitle: 'Change to a different keyboard',
                icon: Icons.swap_horiz,
                onTap: () => bloc.add(const SetupOpenImePicker()),
              ),
          ],
        );
      },
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: isHighlighted
            ? const Color(TeleDeckColors.neonCyan).withValues(alpha: 0.15)
            : const Color(TeleDeckColors.secondaryBackground),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isHighlighted
                    ? const Color(TeleDeckColors.neonCyan)
                    : const Color(
                        TeleDeckColors.neonCyan,
                      ).withValues(alpha: 0.2),
                width: isHighlighted ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: const Color(TeleDeckColors.neonCyan),
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.robotoMono(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(TeleDeckColors.textPrimary),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.robotoMono(
                          fontSize: 11,
                          color: const Color(
                            TeleDeckColors.textPrimary,
                          ).withValues(alpha: 0.6),
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
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rotation setting widget
class _RotationSetting extends StatelessWidget {
  const _RotationSetting();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        final rotation = state.status == SettingsStatus.success
            ? state.settings.keyboardRotation
            : 0;
        final bloc = context.read<SettingsBloc>();

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: const Color(TeleDeckColors.secondaryBackground),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(
                TeleDeckColors.neonCyan,
              ).withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: ListTile(
            title: Text(
              'Keyboard Rotation',
              style: GoogleFonts.robotoMono(
                fontSize: 14,
                color: const Color(TeleDeckColors.textPrimary),
              ),
            ),
            subtitle: Text(
              _getRotationLabel(rotation),
              style: GoogleFonts.robotoMono(
                fontSize: 11,
                color: const Color(
                  TeleDeckColors.textPrimary,
                ).withValues(alpha: 0.6),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.rotate_left,
                    color: Color(TeleDeckColors.neonCyan),
                  ),
                  onPressed: () {
                    final newRotation = (rotation - 1 + 4) % 4;
                    bloc.add(SettingsKeyboardRotationChanged(newRotation));
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.rotate_right,
                    color: Color(TeleDeckColors.neonCyan),
                  ),
                  onPressed: () {
                    final newRotation = (rotation + 1) % 4;
                    bloc.add(SettingsKeyboardRotationChanged(newRotation));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getRotationLabel(int rotation) {
    switch (rotation) {
      case 0:
        return '0° (Default)';
      case 1:
        return '90° Clockwise';
      case 2:
        return '180° Flipped';
      case 3:
        return '270° Counter-clockwise';
      default:
        return '0° (Default)';
    }
  }
}
