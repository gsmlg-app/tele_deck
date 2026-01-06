import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:settings_bloc/settings_bloc.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:tele_theme/tele_theme.dart';

/// Settings screen using settings_ui package
class SettingScreen extends StatelessWidget {
  static const name = 'Settings';

  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(TeleDeckColors.darkBackground),
      appBar: AppBar(
        backgroundColor: const Color(TeleDeckColors.secondaryBackground),
        title: Text(
          'SETTINGS',
          style: GoogleFonts.robotoMono(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(TeleDeckColors.neonCyan),
            letterSpacing: 3,
          ),
        ),
      ),
      body: SettingsTheme(
        themeData: SettingsThemeData(
          settingsListBackground: const Color(TeleDeckColors.darkBackground),
          settingsSectionBackground: const Color(
            TeleDeckColors.secondaryBackground,
          ),
          titleTextColor: const Color(TeleDeckColors.neonMagenta),
          settingsTileTextColor: const Color(TeleDeckColors.textPrimary),
          tileDescriptionTextColor: const Color(
            TeleDeckColors.textPrimary,
          ).withValues(alpha: 0.7),
          leadingIconsColor: const Color(TeleDeckColors.neonCyan),
          tileHighlightColor: const Color(
            TeleDeckColors.neonCyan,
          ).withValues(alpha: 0.1),
        ),
        platform: DevicePlatform.android,
        child: SettingsList(
          platform: DevicePlatform.android,
          sections: [
            // KEYBOARD section
            SettingsSection(
              title: Text(
                'KEYBOARD',
                style: GoogleFonts.robotoMono(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              tiles: [
                _buildRotationTile(context),
                _buildPhysicalButtonsTile(context),
              ],
            ),
            // ABOUT section
            SettingsSection(
              title: Text(
                'ABOUT',
                style: GoogleFonts.robotoMono(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              tiles: [
                SettingsTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text('TeleDeck', style: GoogleFonts.robotoMono()),
                  value: Text(
                    'System IME Keyboard v1.0.0',
                    style: GoogleFonts.robotoMono(fontSize: 12),
                  ),
                ),
                SettingsTile(
                  leading: const Icon(Icons.code),
                  title: Text('Source Code', style: GoogleFonts.robotoMono()),
                  value: Text(
                    'github.com/gsmlg-app/tele_deck',
                    style: GoogleFonts.robotoMono(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  AbstractSettingsTile _buildRotationTile(BuildContext context) {
    return CustomSettingsTile(
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          final rotation = state.status == SettingsStatus.success
              ? state.settings.keyboardRotation
              : 0;
          final bloc = context.read<SettingsBloc>();

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(TeleDeckColors.secondaryBackground),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.rotate_90_degrees_ccw,
                  color: Color(TeleDeckColors.neonCyan),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Keyboard Rotation',
                        style: GoogleFonts.robotoMono(
                          color: const Color(TeleDeckColors.textPrimary),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getRotationLabel(rotation),
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
          );
        },
      ),
    );
  }

  AbstractSettingsTile _buildPhysicalButtonsTile(BuildContext context) {
    return CustomSettingsTile(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(TeleDeckColors.secondaryBackground),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.gamepad_outlined,
                  color: Color(TeleDeckColors.neonCyan),
                ),
                const SizedBox(width: 16),
                Text(
                  'Physical Button Bindings',
                  style: GoogleFonts.robotoMono(
                    color: const Color(TeleDeckColors.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildBindingRow(
              'Toggle Keyboard',
              'app.gsmlg.tele_deck.TOGGLE_KEYBOARD',
            ),
            _buildBindingRow(
              'Show Keyboard',
              'app.gsmlg.tele_deck.SHOW_KEYBOARD',
            ),
            _buildBindingRow(
              'Hide Keyboard',
              'app.gsmlg.tele_deck.HIDE_KEYBOARD',
            ),
            const SizedBox(height: 8),
            Text(
              'Bind these actions to physical buttons on your device.',
              style: GoogleFonts.robotoMono(
                fontSize: 10,
                color: const Color(
                  TeleDeckColors.textPrimary,
                ).withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBindingRow(String label, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.robotoMono(
                fontSize: 12,
                color: const Color(
                  TeleDeckColors.textPrimary,
                ).withValues(alpha: 0.8),
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              action,
              style: GoogleFonts.robotoMono(
                fontSize: 10,
                color: const Color(
                  TeleDeckColors.neonCyan,
                ).withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRotationLabel(int rotation) {
    return switch (rotation) {
      0 => '0° (Default)',
      1 => '90° Clockwise',
      2 => '180° Flipped',
      3 => '270° Counter-clockwise',
      _ => '0° (Default)',
    };
  }
}
