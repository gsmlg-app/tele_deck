import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../settings/settings_provider.dart';
import '../../shared/constants.dart';
import '../display_controller.dart';

/// Main display screen - shows the read-only virtual input field
class MainDisplayView extends ConsumerStatefulWidget {
  final VoidCallback? onToggleKeyboard;
  final VoidCallback? onShowKeyboard;
  final VoidCallback? onHideKeyboard;

  const MainDisplayView({
    super.key,
    this.onToggleKeyboard,
    this.onShowKeyboard,
    this.onHideKeyboard,
  });

  @override
  ConsumerState<MainDisplayView> createState() => _MainDisplayViewState();
}

class _MainDisplayViewState extends ConsumerState<MainDisplayView> {
  Timer? _cursorTimer;
  bool _cursorVisible = true;

  @override
  void initState() {
    super.initState();
    // Initialize display controller (starts IPC listening)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(displayControllerProvider);
    });

    // Start cursor blinking
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 530), (_) {
      if (mounted) {
        setState(() {
          _cursorVisible = !_cursorVisible;
        });
      }
    });
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inputText = ref.watch(inputTextProvider);

    return Scaffold(
      backgroundColor: Color(TeleDeckColors.darkBackground),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            // Main input display
            Expanded(
              child: _buildInputDisplay(inputText),
            ),
            // Status bar
            _buildStatusBar(inputText),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isKeyboardVisible = ref.watch(keyboardVisibleProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(TeleDeckColors.neonCyan).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Logo/Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(
                color: Color(TeleDeckColors.neonCyan),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.keyboard_alt_outlined,
              color: Color(TeleDeckColors.neonCyan),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Title - Flexible to prevent overflow
          Expanded(
            child: Text(
              'TELEDECK',
              style: GoogleFonts.robotoMono(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(TeleDeckColors.neonCyan),
                letterSpacing: 4,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Keyboard toggle button
          _buildKeyboardToggleButton(isKeyboardVisible),
          const SizedBox(width: 12),
          // Settings button
          _buildSettingsButton(context),
          const SizedBox(width: 12),
          // Connection status indicator
          _buildConnectionIndicator(),
        ],
      ),
    );
  }

  Widget _buildKeyboardToggleButton(bool isVisible) {
    return GestureDetector(
      onTap: widget.onToggleKeyboard,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isVisible
                ? Color(TeleDeckColors.neonCyan)
                : Color(TeleDeckColors.textPrimary).withValues(alpha: 0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isVisible ? Icons.keyboard_hide : Icons.keyboard,
          color: isVisible
              ? Color(TeleDeckColors.neonCyan)
              : Color(TeleDeckColors.textPrimary).withValues(alpha: 0.5),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/settings'),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(
            color: Color(TeleDeckColors.textPrimary).withValues(alpha: 0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.settings,
          color: Color(TeleDeckColors.textPrimary).withValues(alpha: 0.7),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildConnectionIndicator() {
    final controller = ref.watch(displayControllerProvider);
    final isConnected = controller.isRegistered;

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isConnected
                ? Color(TeleDeckColors.neonCyan)
                : Colors.red,
            boxShadow: [
              BoxShadow(
                color: (isConnected
                        ? Color(TeleDeckColors.neonCyan)
                        : Colors.red)
                    .withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          isConnected ? 'CONNECTED' : 'WAITING',
          style: GoogleFonts.robotoMono(
            fontSize: 12,
            color: Color(TeleDeckColors.textPrimary).withValues(alpha: 0.7),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildInputDisplay(String text) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(TeleDeckColors.secondaryBackground),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(TeleDeckColors.neonCyan).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(TeleDeckColors.neonCyan).withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Terminal-style header
          Row(
            children: [
              Icon(
                Icons.terminal,
                color: Color(TeleDeckColors.neonMagenta),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'INPUT BUFFER',
                style: GoogleFonts.robotoMono(
                  fontSize: 12,
                  color: Color(TeleDeckColors.neonMagenta),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            color: Color(TeleDeckColors.neonCyan).withValues(alpha: 0.2),
            height: 1,
          ),
          const SizedBox(height: 16),
          // Input text with blinking cursor
          Expanded(
            child: SingleChildScrollView(
              reverse: true,
              child: SizedBox(
                width: double.infinity,
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.robotoMono(
                      fontSize: 18,
                      color: Color(TeleDeckColors.textPrimary),
                      height: 1.5,
                    ),
                    children: [
                      TextSpan(text: text),
                      // Blinking cursor
                      TextSpan(
                        text: _cursorVisible ? '|' : ' ',
                        style: TextStyle(
                          color: Color(TeleDeckColors.cursorColor),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(String text) {
    final charCount = text.length;
    final wordCount = text.trim().isEmpty
        ? 0
        : text.trim().split(RegExp(r'\s+')).length;
    final lineCount = text.isEmpty ? 1 : text.split('\n').length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(TeleDeckColors.neonCyan).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatusItem('CHARS', charCount.toString()),
          _buildStatusItem('WORDS', wordCount.toString()),
          _buildStatusItem('LINES', lineCount.toString()),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.robotoMono(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(TeleDeckColors.neonCyan),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.robotoMono(
            fontSize: 10,
            color: Color(TeleDeckColors.textPrimary).withValues(alpha: 0.5),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}
