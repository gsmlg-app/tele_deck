import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../shared/constants.dart';
import '../settings_provider.dart';

/// Settings screen UI
class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final isKeyboardVisible = ref.watch(keyboardVisibleProvider);

    return Scaffold(
      backgroundColor: Color(TeleDeckColors.darkBackground),
      appBar: AppBar(
        backgroundColor: Color(TeleDeckColors.secondaryBackground),
        title: Text(
          'SETTINGS',
          style: GoogleFonts.robotoMono(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(TeleDeckColors.neonCyan),
            letterSpacing: 3,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Color(TeleDeckColors.neonCyan),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Keyboard Visibility Section
          _buildSectionHeader('KEYBOARD'),
          _buildSettingsTile(
            title: 'Keyboard Visible',
            subtitle: 'Current keyboard visibility state',
            trailing: Switch(
              value: isKeyboardVisible,
              onChanged: (value) {
                ref.read(keyboardVisibleProvider.notifier).state = value;
              },
              activeTrackColor: Color(TeleDeckColors.neonCyan).withValues(alpha: 0.5),
              activeThumbColor: Color(TeleDeckColors.neonCyan),
            ),
          ),
          const SizedBox(height: 24),

          // Startup Behavior Section
          _buildSectionHeader('STARTUP BEHAVIOR'),
          _buildSettingsTile(
            title: 'Show Keyboard on Startup',
            subtitle: 'Automatically show keyboard when app launches',
            trailing: Switch(
              value: settings.showKeyboardOnStartup,
              onChanged: (value) {
                ref
                    .read(appSettingsProvider.notifier)
                    .setShowKeyboardOnStartup(value);
              },
              activeTrackColor: Color(TeleDeckColors.neonCyan).withValues(alpha: 0.5),
              activeThumbColor: Color(TeleDeckColors.neonCyan),
            ),
          ),
          _buildSettingsTile(
            title: 'Remember Last State',
            subtitle: 'Restore keyboard visibility from previous session',
            trailing: Switch(
              value: settings.rememberLastState,
              onChanged: (value) {
                ref
                    .read(appSettingsProvider.notifier)
                    .setRememberLastState(value);
              },
              activeTrackColor: Color(TeleDeckColors.neonCyan).withValues(alpha: 0.5),
              activeThumbColor: Color(TeleDeckColors.neonCyan),
            ),
          ),
          const SizedBox(height: 24),

          // Hotkey Info Section
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
              'Bind these actions to physical buttons on your Ayaneo Pocket DS through the device settings.',
              style: GoogleFonts.robotoMono(
                fontSize: 12,
                color: Color(TeleDeckColors.textPrimary).withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader('ABOUT'),
          _buildInfoTile(
            title: 'TeleDeck',
            subtitle: 'Dual-Screen Custom Keyboard v1.0.0',
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
          color: Color(TeleDeckColors.neonMagenta),
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Color(TeleDeckColors.secondaryBackground),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Color(TeleDeckColors.neonCyan).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        title: Text(
          title,
          style: GoogleFonts.robotoMono(
            fontSize: 14,
            color: Color(TeleDeckColors.textPrimary),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.robotoMono(
            fontSize: 11,
            color: Color(TeleDeckColors.textPrimary).withValues(alpha: 0.6),
          ),
        ),
        trailing: trailing,
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
        color: Color(TeleDeckColors.secondaryBackground),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Color(TeleDeckColors.neonCyan).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: Color(TeleDeckColors.neonCyan),
        ),
        title: Text(
          title,
          style: GoogleFonts.robotoMono(
            fontSize: 14,
            color: Color(TeleDeckColors.textPrimary),
          ),
        ),
        subtitle: SelectableText(
          subtitle,
          style: GoogleFonts.robotoMono(
            fontSize: 11,
            color: Color(TeleDeckColors.neonCyan).withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}
