import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../shared/constants.dart';
import '../keyboard_service.dart';
import 'keyboard_key.dart';

/// Secondary screen keyboard view - Cyberpunk QWERTY layout
class KeyboardView extends ConsumerWidget {
  const KeyboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Color(TeleDeckColors.darkBackground),
      body: SafeArea(
        child: Column(
          children: [
            // Header bar
            _buildHeader(context, ref),
            // Keyboard area
            Expanded(
              child: _buildKeyboard(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final service = ref.watch(keyboardServiceProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(TeleDeckColors.neonMagenta).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Settings button (like Gboard)
          GestureDetector(
            onTap: () => _openSettings(context),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Color(TeleDeckColors.textPrimary).withValues(alpha: 0.3),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.settings,
                color: Color(TeleDeckColors.textPrimary).withValues(alpha: 0.7),
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Cyberpunk styled title
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                Color(TeleDeckColors.neonCyan),
                Color(TeleDeckColors.neonMagenta),
              ],
            ).createShader(bounds),
            child: Text(
              'CONTROL DECK',
              style: GoogleFonts.robotoMono(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 3,
              ),
            ),
          ),
          const Spacer(),
          // Connection indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(
                color: service.isConnected
                    ? Color(TeleDeckColors.neonCyan)
                    : Colors.red.withValues(alpha: 0.5),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: service.isConnected
                        ? Color(TeleDeckColors.neonCyan)
                        : Colors.red,
                    boxShadow: [
                      BoxShadow(
                        color: (service.isConnected
                                ? Color(TeleDeckColors.neonCyan)
                                : Colors.red)
                            .withValues(alpha: 0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  service.isConnected ? 'LINKED' : 'SYNC',
                  style: GoogleFonts.robotoMono(
                    fontSize: 10,
                    color: Color(TeleDeckColors.textPrimary),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openSettings(BuildContext context) {
    // Show a dialog with settings info since we can't navigate to main screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(TeleDeckColors.secondaryBackground),
        title: Text(
          'SETTINGS',
          style: GoogleFonts.robotoMono(
            color: Color(TeleDeckColors.neonCyan),
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Open the TeleDeck app on the main screen to access settings.',
              style: GoogleFonts.robotoMono(
                color: Color(TeleDeckColors.textPrimary),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Physical Button Actions:',
              style: GoogleFonts.robotoMono(
                color: Color(TeleDeckColors.neonMagenta),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildActionInfo('Toggle', 'TOGGLE_KEYBOARD'),
            _buildActionInfo('Show', 'SHOW_KEYBOARD'),
            _buildActionInfo('Hide', 'HIDE_KEYBOARD'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CLOSE',
              style: GoogleFonts.robotoMono(
                color: Color(TeleDeckColors.neonCyan),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionInfo(String label, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.robotoMono(
              color: Color(TeleDeckColors.textPrimary),
              fontSize: 11,
            ),
          ),
          Expanded(
            child: Text(
              'app.gsmlg.tele_deck.$action',
              style: GoogleFonts.robotoMono(
                color: Color(TeleDeckColors.neonCyan).withValues(alpha: 0.8),
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboard(BuildContext context, WidgetRef ref) {
    final service = ref.watch(keyboardServiceProvider);
    final isShiftEnabled = ref.watch(shiftEnabledProvider);
    final isCapsLock = ref.watch(capsLockProvider);
    final isUpperCase = isShiftEnabled || isCapsLock;

    return Container(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          // Number row
          Expanded(
            child: _buildRow(
              KeyboardLayout.qwertyRows[0],
              service,
              isUpperCase: false,
              isNumberRow: true,
            ),
          ),
          // QWERTY row
          Expanded(
            child: _buildRow(
              KeyboardLayout.qwertyRows[1],
              service,
              isUpperCase: isUpperCase,
            ),
          ),
          // ASDF row
          Expanded(
            child: _buildRow(
              KeyboardLayout.qwertyRows[2],
              service,
              isUpperCase: isUpperCase,
              leftPadding: 0.5,
              rightPadding: 0.5,
            ),
          ),
          // ZXCV row with shift and backspace
          Expanded(
            child: _buildShiftRow(context, ref, service, isUpperCase),
          ),
          // Bottom row: special keys and space
          Expanded(
            child: _buildBottomRow(context, ref, service),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    List<String> keys,
    KeyboardService service, {
    required bool isUpperCase,
    bool isNumberRow = false,
    double leftPadding = 0,
    double rightPadding = 0,
  }) {
    return Row(
      children: [
        if (leftPadding > 0) Spacer(flex: (leftPadding * 10).toInt()),
        ...keys.map((key) {
          final displayKey = isNumberRow
              ? key
              : (isUpperCase ? key.toUpperCase() : key.toLowerCase());
          return KeyboardKey(
            label: key,
            displayLabel: displayKey,
            onTap: () => service.sendKeyDown(displayKey),
          );
        }),
        if (rightPadding > 0) Spacer(flex: (rightPadding * 10).toInt()),
      ],
    );
  }

  Widget _buildShiftRow(
    BuildContext context,
    WidgetRef ref,
    KeyboardService service,
    bool isUpperCase,
  ) {
    final isShiftEnabled = ref.watch(shiftEnabledProvider);

    return Row(
      children: [
        // Shift key
        KeyboardKey(
          label: KeyboardLayout.shiftKey,
          icon: Icons.arrow_upward,
          onTap: () {
            ref.read(shiftEnabledProvider.notifier).state = !isShiftEnabled;
          },
          flex: 1.5,
          isSpecial: true,
          accentColor: isShiftEnabled
              ? Color(TeleDeckColors.neonMagenta)
              : null,
        ),
        // ZXCV keys
        ...KeyboardLayout.qwertyRows[3].map((key) {
          final displayKey = isUpperCase ? key.toUpperCase() : key.toLowerCase();
          return KeyboardKey(
            label: key,
            displayLabel: displayKey,
            onTap: () {
              service.sendKeyDown(displayKey);
              // Auto-disable shift after character
              if (isShiftEnabled && !ref.read(capsLockProvider)) {
                ref.read(shiftEnabledProvider.notifier).state = false;
              }
            },
          );
        }),
        // Backspace key
        KeyboardKey(
          label: KeyboardLayout.backspaceKey,
          icon: Icons.backspace_outlined,
          onTap: () => service.sendBackspace(),
          flex: 1.5,
          isSpecial: true,
          accentColor: Color(TeleDeckColors.neonMagenta),
        ),
      ],
    );
  }

  Widget _buildBottomRow(
    BuildContext context,
    WidgetRef ref,
    KeyboardService service,
  ) {
    return Row(
      children: [
        // Clear button
        KeyboardKey(
          label: KeyboardLayout.clearKey,
          displayLabel: 'CLR',
          onTap: () => service.sendClear(),
          flex: 1.2,
          isSpecial: true,
          accentColor: Colors.red.withValues(alpha: 0.8),
        ),
        // Comma
        KeyboardKey(
          label: ',',
          onTap: () => service.sendKeyDown(','),
          flex: 0.8,
        ),
        // Space bar
        KeyboardKey(
          label: KeyboardLayout.spaceKey,
          displayLabel: '─────',
          onTap: () => service.sendSpace(),
          flex: 4,
          isSpecial: true,
        ),
        // Period
        KeyboardKey(
          label: '.',
          onTap: () => service.sendKeyDown('.'),
          flex: 0.8,
        ),
        // Enter key
        KeyboardKey(
          label: KeyboardLayout.enterKey,
          icon: Icons.keyboard_return,
          onTap: () => service.sendEnter(),
          flex: 1.5,
          isSpecial: true,
          accentColor: Color(TeleDeckColors.neonCyan),
        ),
      ],
    );
  }
}
