import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../logging/views/crash_log_viewer.dart';
import '../../shared/constants.dart';
import '../settings_provider.dart';

/// MethodChannel for IME settings operations
const _settingsChannel = MethodChannel('app.gsmlg.tele_deck/settings');

/// Provider for IME enabled status
final imeEnabledProvider = StateProvider<bool>((ref) => false);

/// Provider for IME selected status
final imeSelectedProvider = StateProvider<bool>((ref) => false);

/// Settings screen UI - IME Setup and Configuration
class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  @override
  void initState() {
    super.initState();
    _setupChannelListener();
    _checkIMEStatus();
  }

  void _setupChannelListener() {
    _settingsChannel.setMethodCallHandler((call) async {
      if (call.method == 'onIMEStatusChanged') {
        final enabled = call.arguments['enabled'] as bool? ?? false;
        final selected = call.arguments['selected'] as bool? ?? false;
        ref.read(imeEnabledProvider.notifier).state = enabled;
        ref.read(imeSelectedProvider.notifier).state = selected;
      }
    });
  }

  Future<void> _checkIMEStatus() async {
    try {
      final status = await _settingsChannel.invokeMethod('getIMEStatus');
      if (status is Map) {
        ref.read(imeEnabledProvider.notifier).state = status['enabled'] ?? false;
        ref.read(imeSelectedProvider.notifier).state = status['selected'] ?? false;
      }
    } catch (e) {
      debugPrint('Error checking IME status: $e');
    }
  }

  Future<void> _openIMESettings() async {
    try {
      await _settingsChannel.invokeMethod('openIMESettings');
    } catch (e) {
      debugPrint('Error opening IME settings: $e');
    }
  }

  Future<void> _openIMEPicker() async {
    try {
      await _settingsChannel.invokeMethod('openIMEPicker');
    } catch (e) {
      debugPrint('Error opening IME picker: $e');
    }
  }

  void _openCrashLogViewer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CrashLogViewer(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final isIMEEnabled = ref.watch(imeEnabledProvider);
    final isIMESelected = ref.watch(imeSelectedProvider);

    return Scaffold(
      backgroundColor: Color(TeleDeckColors.darkBackground),
      appBar: AppBar(
        backgroundColor: Color(TeleDeckColors.secondaryBackground),
        title: Text(
          'TELEDECK SETTINGS',
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
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Color(TeleDeckColors.neonCyan),
            ),
            onPressed: _checkIMEStatus,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // IME Setup Section
          _buildSectionHeader('IME SETUP'),
          _buildIMEStatusCard(isIMEEnabled, isIMESelected),
          const SizedBox(height: 16),

          // Setup Buttons
          if (!isIMEEnabled)
            _buildActionButton(
              title: 'Enable TeleDeck Keyboard',
              subtitle: 'Open system settings to enable this keyboard',
              icon: Icons.settings,
              onTap: _openIMESettings,
              isHighlighted: true,
            ),

          if (isIMEEnabled && !isIMESelected)
            _buildActionButton(
              title: 'Select TeleDeck Keyboard',
              subtitle: 'Choose TeleDeck as your input method',
              icon: Icons.keyboard,
              onTap: _openIMEPicker,
              isHighlighted: true,
            ),

          if (isIMEEnabled)
            _buildActionButton(
              title: 'Switch Input Method',
              subtitle: 'Change to a different keyboard',
              icon: Icons.swap_horiz,
              onTap: _openIMEPicker,
            ),

          const SizedBox(height: 24),

          // Display Section
          _buildSectionHeader('DISPLAY'),
          _buildSettingsTile(
            title: 'Keyboard Rotation',
            subtitle: _getRotationLabel(settings.keyboardRotation),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.rotate_left,
                    color: Color(TeleDeckColors.neonCyan),
                  ),
                  onPressed: () {
                    final newRotation = (settings.keyboardRotation - 1 + 4) % 4;
                    ref
                        .read(appSettingsProvider.notifier)
                        .setKeyboardRotation(newRotation);
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.rotate_right,
                    color: Color(TeleDeckColors.neonCyan),
                  ),
                  onPressed: () {
                    final newRotation = (settings.keyboardRotation + 1) % 4;
                    ref
                        .read(appSettingsProvider.notifier)
                        .setKeyboardRotation(newRotation);
                  },
                ),
              ],
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

          // Diagnostics Section
          _buildSectionHeader('DIAGNOSTICS'),
          _buildActionButton(
            title: 'View Crash Logs',
            subtitle: 'View keyboard crash reports and error details',
            icon: Icons.bug_report,
            onTap: () => _openCrashLogViewer(context),
          ),
          const SizedBox(height: 24),

          // About Section
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

  Widget _buildIMEStatusCard(bool isEnabled, bool isSelected) {
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
        color: Color(TeleDeckColors.secondaryBackground),
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
                    color: Color(TeleDeckColors.textPrimary),
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
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: isHighlighted
            ? Color(TeleDeckColors.neonCyan).withValues(alpha: 0.15)
            : Color(TeleDeckColors.secondaryBackground),
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
                    ? Color(TeleDeckColors.neonCyan)
                    : Color(TeleDeckColors.neonCyan).withValues(alpha: 0.2),
                width: isHighlighted ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Color(TeleDeckColors.neonCyan),
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
                          color: Color(TeleDeckColors.textPrimary),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.robotoMono(
                          fontSize: 11,
                          color: Color(TeleDeckColors.textPrimary).withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Color(TeleDeckColors.neonCyan).withValues(alpha: 0.5),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
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
