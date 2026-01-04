import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/constants.dart';
import '../keyboard_service.dart';
import 'keyboard_key.dart';

/// Provider for keyboard rotation setting (read from shared_preferences)
/// Uses autoDispose so it refreshes when invalidated
final keyboardRotationProvider = FutureProvider.autoDispose<int>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  // Force reload from disk
  await prefs.reload();
  final jsonString = prefs.getString('teledeck_settings');
  if (jsonString == null) return 0;
  try {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return json['keyboardRotation'] as int? ?? 0;
  } catch (e) {
    return 0;
  }
});

/// Provider to trigger periodic refresh of rotation settings
final rotationRefreshProvider = StreamProvider.autoDispose<int>((ref) async* {
  // Refresh every 2 seconds to pick up settings changes
  while (true) {
    await Future.delayed(const Duration(seconds: 2));
    ref.invalidate(keyboardRotationProvider);
    yield DateTime.now().millisecondsSinceEpoch;
  }
});

/// Secondary screen keyboard view - Cyberpunk QWERTY layout
class KeyboardView extends ConsumerWidget {
  const KeyboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orientation = MediaQuery.of(context).orientation;
    final rotationAsync = ref.watch(keyboardRotationProvider);
    // Watch refresh provider to trigger periodic updates
    ref.watch(rotationRefreshProvider);

    return Scaffold(
      backgroundColor: Color(TeleDeckColors.darkBackground),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Log actual dimensions for debugging
            debugPrint('Keyboard screen: ${constraints.maxWidth}x${constraints.maxHeight}, orientation: $orientation');

            // Get rotation value (default to 0 if loading or error)
            final rotation = rotationAsync.when(
              data: (value) {
                debugPrint('Keyboard rotation loaded: $value');
                return value;
              },
              loading: () {
                debugPrint('Keyboard rotation loading...');
                return 0;
              },
              error: (e, __) {
                debugPrint('Keyboard rotation error: $e');
                return 0;
              },
            );
            debugPrint('Applied rotation: $rotation quarterTurns');

            // Determine if rotation swaps width/height
            final bool isRotated90or270 = rotation == 1 || rotation == 3;

            // For 90/270 rotation, we need to build content for swapped dimensions
            // then rotate it back to fit the screen
            final contentWidth = isRotated90or270 ? constraints.maxHeight : constraints.maxWidth;
            final contentHeight = isRotated90or270 ? constraints.maxWidth : constraints.maxHeight;

            // Build layout based on content dimensions (what user sees after rotation)
            final isPortrait = contentHeight > contentWidth;
            debugPrint('Building layout: ${isPortrait ? "portrait" : "landscape"} for content ${contentWidth}x$contentHeight');

            // Build the keyboard content
            Widget keyboardContent;
            if (isPortrait) {
              keyboardContent = _buildPortraitLayout(context, ref);
            } else {
              keyboardContent = _buildLandscapeLayout(context, ref);
            }

            // Apply rotation if needed
            if (rotation != 0) {
              // Wrap content in sized box with swapped dimensions, then rotate
              keyboardContent = Center(
                child: RotatedBox(
                  quarterTurns: rotation,
                  child: SizedBox(
                    width: contentWidth,
                    height: contentHeight,
                    child: keyboardContent,
                  ),
                ),
              );
            }

            return keyboardContent;
          },
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Header bar (compact)
        _buildHeader(context, ref),
        // Keyboard area - takes all remaining space
        Expanded(
          child: _buildKeyboard(context, ref),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Header bar (compact)
        _buildHeader(context, ref),
        // Keyboard area
        Expanded(
          child: _buildKeyboard(context, ref),
        ),
      ],
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
          const SizedBox(width: 8),
          // Refresh button to reload settings
          GestureDetector(
            onTap: () => ref.invalidate(keyboardRotationProvider),
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
                Icons.refresh,
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

  void _showKeyboardModeSelector(WidgetRef ref) {
    // Toggle the inline mode selector overlay
    ref.read(showModeSelectorProvider.notifier).state = true;
  }

  /// Build the inline mode selector overlay (replaces bottom sheet)
  Widget _buildModeSelectorOverlay(WidgetRef ref) {
    final currentMode = ref.watch(keyboardModeProvider);

    return Container(
      color: Color(TeleDeckColors.darkBackground).withValues(alpha: 0.95),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(TeleDeckColors.secondaryBackground),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Color(TeleDeckColors.neonCyan).withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(TeleDeckColors.neonCyan).withValues(alpha: 0.2),
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
                  color: Color(TeleDeckColors.neonCyan),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildModeButtonInline(
                    ref,
                    icon: Icons.keyboard,
                    label: 'Standard',
                    mode: KeyboardMode.standard,
                    isSelected: currentMode == KeyboardMode.standard,
                  ),
                  const SizedBox(width: 16),
                  _buildModeButtonInline(
                    ref,
                    icon: Icons.dialpad,
                    label: 'Numpad',
                    mode: KeyboardMode.numpad,
                    isSelected: currentMode == KeyboardMode.numpad,
                  ),
                  const SizedBox(width: 16),
                  _buildModeButtonInline(
                    ref,
                    icon: Icons.emoji_emotions,
                    label: 'Emoji',
                    mode: KeyboardMode.emoji,
                    isSelected: currentMode == KeyboardMode.emoji,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Close button
              GestureDetector(
                onTap: () {
                  ref.read(showModeSelectorProvider.notifier).state = false;
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Color(TeleDeckColors.neonMagenta),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'CLOSE',
                    style: GoogleFonts.robotoMono(
                      color: Color(TeleDeckColors.neonMagenta),
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
  }

  Widget _buildModeButtonInline(
    WidgetRef ref, {
    required IconData icon,
    required String label,
    required KeyboardMode mode,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        ref.read(keyboardModeProvider.notifier).state = mode;
        ref.read(showModeSelectorProvider.notifier).state = false;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Color(TeleDeckColors.neonCyan).withValues(alpha: 0.2)
              : Color(TeleDeckColors.keySurface),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Color(TeleDeckColors.neonCyan)
                : Color(TeleDeckColors.neonCyan).withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(TeleDeckColors.neonCyan).withValues(alpha: 0.3),
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
                  ? Color(TeleDeckColors.neonCyan)
                  : Color(TeleDeckColors.textPrimary),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.robotoMono(
                color: isSelected
                    ? Color(TeleDeckColors.neonCyan)
                    : Color(TeleDeckColors.textPrimary),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
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
    final keyboardMode = ref.watch(keyboardModeProvider);
    final showModeSelector = ref.watch(showModeSelectorProvider);

    // Build different layouts based on mode
    Widget keyboardContent;
    switch (keyboardMode) {
      case KeyboardMode.numpad:
        keyboardContent = _buildNumpadLayout(context, ref, service);
      case KeyboardMode.emoji:
        keyboardContent = _buildEmojiLayout(context, ref, service);
      case KeyboardMode.standard:
      default:
        keyboardContent = _buildStandardLayout(context, ref, service);
    }

    // Stack the keyboard with the mode selector overlay
    return Stack(
      children: [
        keyboardContent,
        // Mode selector overlay (shown on top when triggered)
        if (showModeSelector)
          Positioned.fill(
            child: _buildModeSelectorOverlay(ref),
          ),
      ],
    );
  }

  /// Standard QWERTY keyboard layout
  Widget _buildStandardLayout(BuildContext context, WidgetRef ref, KeyboardService service) {
    final isShiftEnabled = ref.watch(shiftEnabledProvider);
    final isCapsLock = ref.watch(capsLockProvider);
    final isUpperCase = isShiftEnabled || isCapsLock;

    return Container(
      padding: const EdgeInsets.all(2),
      child: Column(
        children: [
          // Row 1: Function keys (ESC, F1-F12, DEL)
          Expanded(child: _buildFunctionRow(ref, service)),
          // Row 2: Number row (or symbols when shifted)
          Expanded(child: _buildNumberRow(ref, service, isShiftEnabled)),
          // Row 3: QWERTY row
          Expanded(child: _buildQwertyRow(ref, service, isUpperCase)),
          // Row 4: ASDF row
          Expanded(child: _buildAsdfRow(ref, service, isUpperCase)),
          // Row 5: ZXCV row
          Expanded(child: _buildZxcvRow(ref, service, isUpperCase)),
          // Row 6: Modifier row (Ctrl, Alt, Super, Space, arrows)
          Expanded(child: _buildModifierRow(context, ref, service)),
        ],
      ),
    );
  }

  /// Numpad + Navigation keys layout
  Widget _buildNumpadLayout(BuildContext context, WidgetRef ref, KeyboardService service) {
    return Container(
      padding: const EdgeInsets.all(2),
      child: Row(
        children: [
          // Left side: Navigation keys
          Expanded(
            flex: 4,
            child: Column(
              children: [
                // Row 1: Ins, Home, PgUp
                Expanded(
                  child: Row(
                    children: [
                      KeyboardKey(label: 'Ins', displayLabel: 'Ins', onTap: () => service.sendKeyDown('Insert'), isSpecial: true),
                      KeyboardKey(label: 'Home', displayLabel: 'Home', onTap: () => service.sendKeyDown('Home'), isSpecial: true),
                      KeyboardKey(label: 'PgUp', displayLabel: 'PgUp', onTap: () => service.sendKeyDown('PageUp'), isSpecial: true),
                    ],
                  ),
                ),
                // Row 2: Del, End, PgDn
                Expanded(
                  child: Row(
                    children: [
                      KeyboardKey(label: 'Del', displayLabel: 'Del', onTap: () => service.sendDelete(), isSpecial: true),
                      KeyboardKey(label: 'End', displayLabel: 'End', onTap: () => service.sendKeyDown('End'), isSpecial: true),
                      KeyboardKey(label: 'PgDn', displayLabel: 'PgDn', onTap: () => service.sendKeyDown('PageDown'), isSpecial: true),
                    ],
                  ),
                ),
                // Row 3: Empty, Up, Empty
                Expanded(
                  child: Row(
                    children: [
                      const Spacer(),
                      KeyboardKey(label: 'Up', icon: Icons.arrow_upward, onTap: () => service.sendArrowKey(ArrowDirection.up), isSpecial: true),
                      const Spacer(),
                    ],
                  ),
                ),
                // Row 4: Left, Down, Right
                Expanded(
                  child: Row(
                    children: [
                      KeyboardKey(label: 'Left', icon: Icons.arrow_back, onTap: () => service.sendArrowKey(ArrowDirection.left), isSpecial: true),
                      KeyboardKey(label: 'Down', icon: Icons.arrow_downward, onTap: () => service.sendArrowKey(ArrowDirection.down), isSpecial: true),
                      KeyboardKey(label: 'Right', icon: Icons.arrow_forward, onTap: () => service.sendArrowKey(ArrowDirection.right), isSpecial: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Right side: Numpad
          Expanded(
            flex: 5,
            child: Column(
              children: [
                // Row 1: NumLock, /, *, -
                Expanded(
                  child: Row(
                    children: [
                      KeyboardKey(label: 'Num', displayLabel: 'Num', onTap: () {}, isSpecial: true),
                      KeyboardKey(label: '/', onTap: () => service.sendKeyDown('/')),
                      KeyboardKey(label: '*', onTap: () => service.sendKeyDown('*')),
                      KeyboardKey(label: '-', onTap: () => service.sendKeyDown('-')),
                    ],
                  ),
                ),
                // Row 2: 7, 8, 9, +
                Expanded(
                  child: Row(
                    children: [
                      KeyboardKey(label: '7', onTap: () => service.sendKeyDown('7')),
                      KeyboardKey(label: '8', onTap: () => service.sendKeyDown('8')),
                      KeyboardKey(label: '9', onTap: () => service.sendKeyDown('9')),
                      KeyboardKey(label: '+', onTap: () => service.sendKeyDown('+')),
                    ],
                  ),
                ),
                // Row 3: 4, 5, 6
                Expanded(
                  child: Row(
                    children: [
                      KeyboardKey(label: '4', onTap: () => service.sendKeyDown('4')),
                      KeyboardKey(label: '5', onTap: () => service.sendKeyDown('5')),
                      KeyboardKey(label: '6', onTap: () => service.sendKeyDown('6')),
                      const Spacer(),
                    ],
                  ),
                ),
                // Row 4: 1, 2, 3, Enter
                Expanded(
                  child: Row(
                    children: [
                      KeyboardKey(label: '1', onTap: () => service.sendKeyDown('1')),
                      KeyboardKey(label: '2', onTap: () => service.sendKeyDown('2')),
                      KeyboardKey(label: '3', onTap: () => service.sendKeyDown('3')),
                      KeyboardKey(label: 'Enter', icon: Icons.keyboard_return, onTap: () => service.sendEnter(), isSpecial: true, accentColor: Color(TeleDeckColors.neonCyan)),
                    ],
                  ),
                ),
                // Row 5: 0, ., Back to standard
                Expanded(
                  child: Row(
                    children: [
                      KeyboardKey(label: '0', onTap: () => service.sendKeyDown('0'), flex: 2),
                      KeyboardKey(label: '.', onTap: () => service.sendKeyDown('.')),
                      KeyboardKey(
                        label: 'ABC',
                        displayLabel: 'ABC',
                        onTap: () => ref.read(keyboardModeProvider.notifier).state = KeyboardMode.standard,
                        isSpecial: true,
                        accentColor: Color(TeleDeckColors.neonMagenta),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Emoji keyboard layout
  Widget _buildEmojiLayout(BuildContext context, WidgetRef ref, KeyboardService service) {
    // Common emojis organized by category
    const emojis = [
      // Smileys
      '😀', '😃', '😄', '😁', '😅', '😂', '🤣', '😊', '😇', '🙂', '😉', '😌',
      '😍', '🥰', '😘', '😗', '😙', '😚', '😋', '😛', '😜', '🤪', '😝', '🤑',
      '🤗', '🤭', '🤫', '🤔', '🤐', '🤨', '😐', '😑', '😶', '😏', '😒', '🙄',
      '😬', '😮', '😯', '😲', '😳', '🥺', '😢', '😭', '😤', '😡', '🤬', '😈',
      // Gestures
      '👍', '👎', '👌', '✌️', '🤞', '🤟', '🤘', '🤙', '👋', '🖐️', '✋', '👏',
      // Hearts
      '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '💔', '💕', '💖', '💗',
    ];

    return Container(
      padding: const EdgeInsets.all(2),
      child: Column(
        children: [
          // Emoji grid
          Expanded(
            flex: 5,
            child: GridView.builder(
              padding: const EdgeInsets.all(4),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: emojis.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => service.sendKeyDown(emojis[index]),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(TeleDeckColors.keySurface),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Color(TeleDeckColors.neonCyan).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        emojis[index],
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Bottom row: Back to standard, Backspace, Space, Enter
          Expanded(
            child: Row(
              children: [
                KeyboardKey(
                  label: 'ABC',
                  displayLabel: 'ABC',
                  onTap: () => ref.read(keyboardModeProvider.notifier).state = KeyboardMode.standard,
                  isSpecial: true,
                  accentColor: Color(TeleDeckColors.neonMagenta),
                  flex: 1.5,
                ),
                KeyboardKey(
                  label: 'Backspace',
                  icon: Icons.backspace_outlined,
                  onTap: () => service.sendBackspace(),
                  isSpecial: true,
                  flex: 1.5,
                ),
                KeyboardKey(
                  label: 'Space',
                  displayLabel: '',
                  onTap: () => service.sendSpace(),
                  isSpecial: true,
                  flex: 4,
                ),
                KeyboardKey(
                  label: 'Enter',
                  icon: Icons.keyboard_return,
                  onTap: () => service.sendEnter(),
                  isSpecial: true,
                  accentColor: Color(TeleDeckColors.neonCyan),
                  flex: 1.5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Function key mappings when FN is pressed (media/system controls)
  static const Map<String, Map<String, dynamic>> _fnKeyMappings = {
    'F1': {'icon': Icons.brightness_low, 'label': '☀-', 'action': 'brightness_down'},
    'F2': {'icon': Icons.brightness_high, 'label': '☀+', 'action': 'brightness_up'},
    'F3': {'icon': Icons.apps, 'label': '⊞', 'action': 'app_switch'},
    'F4': {'icon': Icons.search, 'label': '🔍', 'action': 'search'},
    'F5': {'icon': Icons.mic, 'label': '🎤', 'action': 'dictation'},
    'F6': {'icon': Icons.do_not_disturb, 'label': '🔕', 'action': 'dnd'},
    'F7': {'icon': Icons.skip_previous, 'label': '⏮', 'action': 'media_prev'},
    'F8': {'icon': Icons.play_arrow, 'label': '⏯', 'action': 'media_play'},
    'F9': {'icon': Icons.skip_next, 'label': '⏭', 'action': 'media_next'},
    'F10': {'icon': Icons.volume_off, 'label': '🔇', 'action': 'mute'},
    'F11': {'icon': Icons.volume_down, 'label': '🔉', 'action': 'vol_down'},
    'F12': {'icon': Icons.volume_up, 'label': '🔊', 'action': 'vol_up'},
  };

  /// Build function key row (ESC, F1-F12, DEL)
  Widget _buildFunctionRow(WidgetRef ref, KeyboardService service) {
    final isFnEnabled = ref.watch(fnEnabledProvider);

    return Row(
      children: KeyboardLayout.functionRow.map((key) {
        if (key == 'ESC') {
          return KeyboardKey(
            label: key,
            displayLabel: 'Esc',
            onTap: () => service.sendEscape(),
            isSpecial: true,
          );
        } else if (key == 'DEL') {
          return KeyboardKey(
            label: key,
            displayLabel: 'Del',
            onTap: () => service.sendDelete(),
            isSpecial: true,
          );
        } else if (key.startsWith('F')) {
          final num = int.parse(key.substring(1));
          final fnMapping = _fnKeyMappings[key];

          if (isFnEnabled && fnMapping != null) {
            // Show media/system function when FN is pressed
            return KeyboardKey(
              label: key,
              icon: fnMapping['icon'] as IconData,
              onTap: () {
                // Send the function action
                service.sendKeyDown('FN_${fnMapping['action']}');
              },
              isSpecial: true,
              accentColor: Color(TeleDeckColors.neonCyan),
            );
          } else {
            // Normal F-key
            return KeyboardKey(
              label: key,
              onTap: () => service.sendFunctionKey(num),
              isSpecial: true,
            );
          }
        }
        return KeyboardKey(label: key, onTap: () {});
      }).toList(),
    );
  }

  /// Build number row - shows both number and symbol
  Widget _buildNumberRow(WidgetRef ref, KeyboardService service, bool isShifted) {
    // Map of number keys to their shifted symbols
    const numberSymbolMap = {
      '`': '~', '1': '!', '2': '@', '3': '#', '4': '\$', '5': '%',
      '6': '^', '7': '&', '8': '*', '9': '(', '0': ')', '-': '_', '=': '+',
    };

    return Row(
      children: KeyboardLayout.numberRow.map((key) {
        if (key == 'BACKSPACE') {
          return KeyboardKey(
            label: key,
            icon: Icons.backspace_outlined,
            onTap: () => service.sendBackspace(),
            flex: KeyboardLayout.keyFlex['BACKSPACE'] ?? 1.0,
            isSpecial: true,
            accentColor: Color(TeleDeckColors.neonMagenta),
          );
        }
        // For number keys, show symbol above number
        final symbol = numberSymbolMap[key] ?? key;
        final actualKey = isShifted ? symbol : key;
        return _NumberSymbolKey(
          number: key,
          symbol: symbol,
          isShifted: isShifted,
          onTap: () => service.sendKeyDown(actualKey),
        );
      }).toList(),
    );
  }

  /// Build QWERTY row (Tab, Q-P, brackets, backslash)
  Widget _buildQwertyRow(WidgetRef ref, KeyboardService service, bool isUpperCase) {
    final isShifted = ref.watch(shiftEnabledProvider);
    // Shifted symbols for punctuation keys
    const shiftedSymbols = {'[': '{', ']': '}', '\\': '|'};

    return Row(
      children: KeyboardLayout.qwertyRow.map((key) {
        if (key == 'TAB') {
          return KeyboardKey(
            label: key,
            displayLabel: 'Tab',
            onTap: () => service.sendTab(),
            flex: KeyboardLayout.keyFlex['TAB'] ?? 1.0,
            isSpecial: true,
          );
        }
        // Letter keys
        if (key.length == 1 && key.toUpperCase() != key.toLowerCase()) {
          final displayKey = isUpperCase ? key.toUpperCase() : key.toLowerCase();
          return KeyboardKey(
            label: key,
            displayLabel: displayKey,
            onTap: () {
              service.sendKeyDown(displayKey);
              _autoDisableShift(ref);
            },
          );
        }
        // Punctuation keys with shifted symbols
        if (shiftedSymbols.containsKey(key)) {
          final symbol = shiftedSymbols[key]!;
          final actualKey = isShifted ? symbol : key;
          return _NumberSymbolKey(
            number: key,
            symbol: symbol,
            isShifted: isShifted,
            onTap: () {
              service.sendKeyDown(actualKey);
              _autoDisableShift(ref);
            },
          );
        }
        // Other symbol keys
        return KeyboardKey(
          label: key,
          onTap: () => service.sendKeyDown(key),
        );
      }).toList(),
    );
  }

  /// Build ASDF row (Caps, A-L, semicolon, quote, Enter)
  Widget _buildAsdfRow(WidgetRef ref, KeyboardService service, bool isUpperCase) {
    final isCapsLock = ref.watch(capsLockProvider);
    final isShifted = ref.watch(shiftEnabledProvider);
    // Shifted symbols for punctuation keys
    const shiftedSymbols = {';': ':', "'": '"'};

    return Row(
      children: KeyboardLayout.asdfRow.map((key) {
        if (key == 'CAPS') {
          return KeyboardKey(
            label: key,
            displayLabel: 'Caps',
            onTap: () {
              final newState = !isCapsLock;
              ref.read(capsLockProvider.notifier).state = newState;
              service.sendCapsLock(newState);
            },
            flex: KeyboardLayout.keyFlex['CAPS'] ?? 1.0,
            isSpecial: true,
            accentColor: isCapsLock ? Color(TeleDeckColors.neonMagenta) : null,
          );
        } else if (key == 'ENTER') {
          return KeyboardKey(
            label: key,
            icon: Icons.keyboard_return,
            onTap: () => service.sendEnter(),
            flex: KeyboardLayout.keyFlex['ENTER'] ?? 1.0,
            isSpecial: true,
            accentColor: Color(TeleDeckColors.neonCyan),
          );
        }
        // Letter keys
        if (key.length == 1 && key.toUpperCase() != key.toLowerCase()) {
          final displayKey = isUpperCase ? key.toUpperCase() : key.toLowerCase();
          return KeyboardKey(
            label: key,
            displayLabel: displayKey,
            onTap: () {
              service.sendKeyDown(displayKey);
              _autoDisableShift(ref);
            },
          );
        }
        // Punctuation keys with shifted symbols
        if (shiftedSymbols.containsKey(key)) {
          final symbol = shiftedSymbols[key]!;
          final actualKey = isShifted ? symbol : key;
          return _NumberSymbolKey(
            number: key,
            symbol: symbol,
            isShifted: isShifted,
            onTap: () {
              service.sendKeyDown(actualKey);
              _autoDisableShift(ref);
            },
          );
        }
        // Other symbol keys
        return KeyboardKey(
          label: key,
          onTap: () => service.sendKeyDown(key),
        );
      }).toList(),
    );
  }

  /// Build ZXCV row (Shift, Z-M, comma, period, slash, Shift)
  Widget _buildZxcvRow(WidgetRef ref, KeyboardService service, bool isUpperCase) {
    final isShiftEnabled = ref.watch(shiftEnabledProvider);
    final isShiftLocked = ref.watch(shiftLockedProvider);
    // Shifted symbols for punctuation keys
    const shiftedSymbols = {',': '<', '.': '>', '/': '?'};

    return Row(
      children: KeyboardLayout.zxcvRow.map((key) {
        if (key == 'SHIFT') {
          return _ShiftKey(
            isEnabled: isShiftEnabled,
            isLocked: isShiftLocked,
            onTap: () {
              if (isShiftLocked) {
                // If locked, unlock and disable
                ref.read(shiftLockedProvider.notifier).state = false;
                ref.read(shiftEnabledProvider.notifier).state = false;
              } else {
                // Toggle shift
                ref.read(shiftEnabledProvider.notifier).state = !isShiftEnabled;
              }
            },
            onLongPress: () {
              // Long press to lock shift
              ref.read(shiftLockedProvider.notifier).state = true;
              ref.read(shiftEnabledProvider.notifier).state = true;
            },
            flex: KeyboardLayout.keyFlex['SHIFT'] ?? 1.0,
          );
        }
        // Letter keys
        if (key.length == 1 && key.toUpperCase() != key.toLowerCase()) {
          final displayKey = isUpperCase ? key.toUpperCase() : key.toLowerCase();
          return KeyboardKey(
            label: key,
            displayLabel: displayKey,
            onTap: () {
              service.sendKeyDown(displayKey);
              _autoDisableShift(ref);
            },
          );
        }
        // Punctuation keys with shifted symbols
        if (shiftedSymbols.containsKey(key)) {
          final symbol = shiftedSymbols[key]!;
          final actualKey = isShiftEnabled ? symbol : key;
          return _NumberSymbolKey(
            number: key,
            symbol: symbol,
            isShifted: isShiftEnabled,
            onTap: () {
              service.sendKeyDown(actualKey);
              _autoDisableShift(ref);
            },
          );
        }
        // Other symbol keys
        return KeyboardKey(
          label: key,
          onTap: () => service.sendKeyDown(key),
        );
      }).toList(),
    );
  }

  /// Build modifier row (Ctrl, Alt, Super, Space, Fn, arrows)
  Widget _buildModifierRow(BuildContext context, WidgetRef ref, KeyboardService service) {
    final isCtrlEnabled = ref.watch(ctrlEnabledProvider);
    final isAltEnabled = ref.watch(altEnabledProvider);
    final isSuperEnabled = ref.watch(superEnabledProvider);
    final isFnEnabled = ref.watch(fnEnabledProvider);

    return Row(
      children: KeyboardLayout.modifierRow.map((key) {
        switch (key) {
          case 'CTRL':
            return KeyboardKey(
              label: key,
              displayLabel: 'Ctrl',
              onTap: () {
                final newState = !isCtrlEnabled;
                ref.read(ctrlEnabledProvider.notifier).state = newState;
                service.sendModifier(ModifierType.ctrl, pressed: newState);
              },
              flex: KeyboardLayout.keyFlex['CTRL'] ?? 1.0,
              isSpecial: true,
              accentColor: isCtrlEnabled ? Color(TeleDeckColors.neonPurple) : null,
            );
          case 'ALT':
            return KeyboardKey(
              label: key,
              displayLabel: 'Alt',
              onTap: () {
                final newState = !isAltEnabled;
                ref.read(altEnabledProvider.notifier).state = newState;
                service.sendModifier(ModifierType.alt, pressed: newState);
              },
              flex: KeyboardLayout.keyFlex['ALT'] ?? 1.0,
              isSpecial: true,
              accentColor: isAltEnabled ? Color(TeleDeckColors.neonPurple) : null,
            );
          case 'SUPER':
            return KeyboardKey(
              label: key,
              displayLabel: '⌘',
              onTap: () {
                final newState = !isSuperEnabled;
                ref.read(superEnabledProvider.notifier).state = newState;
                service.sendModifier(ModifierType.super_, pressed: newState);
              },
              flex: KeyboardLayout.keyFlex['SUPER'] ?? 1.0,
              isSpecial: true,
              accentColor: isSuperEnabled ? Color(TeleDeckColors.neonPurple) : null,
            );
          case 'FN':
            return _FnKey(
              isEnabled: isFnEnabled,
              onTap: () {
                final newState = !isFnEnabled;
                ref.read(fnEnabledProvider.notifier).state = newState;
              },
              onLongPress: () => _showKeyboardModeSelector(ref),
              flex: KeyboardLayout.keyFlex['FN'] ?? 1.0,
            );
          case 'SPACE':
            return KeyboardKey(
              label: key,
              displayLabel: '',
              onTap: () => service.sendSpace(),
              flex: KeyboardLayout.keyFlex['SPACE'] ?? 1.0,
              isSpecial: true,
            );
          case 'LEFT':
            return KeyboardKey(
              label: key,
              icon: Icons.arrow_left,
              onTap: () => service.sendArrowKey(ArrowDirection.left),
              flex: KeyboardLayout.keyFlex['LEFT'] ?? 1.0,
              isSpecial: true,
            );
          case 'RIGHT':
            return KeyboardKey(
              label: key,
              icon: Icons.arrow_right,
              onTap: () => service.sendArrowKey(ArrowDirection.right),
              flex: KeyboardLayout.keyFlex['RIGHT'] ?? 1.0,
              isSpecial: true,
            );
          case 'UP':
            return KeyboardKey(
              label: key,
              icon: Icons.arrow_drop_up,
              onTap: () => service.sendArrowKey(ArrowDirection.up),
              flex: KeyboardLayout.keyFlex['UP'] ?? 1.0,
              isSpecial: true,
            );
          case 'DOWN':
            return KeyboardKey(
              label: key,
              icon: Icons.arrow_drop_down,
              onTap: () => service.sendArrowKey(ArrowDirection.down),
              flex: KeyboardLayout.keyFlex['DOWN'] ?? 1.0,
              isSpecial: true,
            );
          default:
            return KeyboardKey(label: key, onTap: () {});
        }
      }).toList(),
    );
  }

  /// Auto-disable shift after typing a character (unless caps lock or shift lock is on)
  void _autoDisableShift(WidgetRef ref) {
    final isShiftEnabled = ref.read(shiftEnabledProvider);
    final isCapsLock = ref.read(capsLockProvider);
    final isShiftLocked = ref.read(shiftLockedProvider);
    if (isShiftEnabled && !isCapsLock && !isShiftLocked) {
      ref.read(shiftEnabledProvider.notifier).state = false;
    }
  }
}

/// A key that shows both number and symbol (like physical keyboard keys)
class _NumberSymbolKey extends StatefulWidget {
  final String number;
  final String symbol;
  final bool isShifted;
  final VoidCallback onTap;

  const _NumberSymbolKey({
    required this.number,
    required this.symbol,
    required this.isShifted,
    required this.onTap,
  });

  @override
  State<_NumberSymbolKey> createState() => _NumberSymbolKeyState();
}

class _NumberSymbolKeyState extends State<_NumberSymbolKey>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _glowController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _glowController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _glowController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Color(TeleDeckColors.neonCyan);

    return Expanded(
      flex: 10,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          child: AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return SizedBox.expand(
                child: Container(
                  decoration: BoxDecoration(
                    color: _isPressed
                        ? Color(TeleDeckColors.keyPressed)
                        : Color(TeleDeckColors.keySurface),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: accentColor.withValues(
                        alpha: 0.3 + (_glowAnimation.value * 0.5),
                      ),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(
                          alpha: _glowAnimation.value * 0.4,
                        ),
                        blurRadius: 8 * _glowAnimation.value,
                        spreadRadius: 1 * _glowAnimation.value,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Symbol (top, smaller, highlighted when shifted)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          widget.symbol,
                          style: GoogleFonts.robotoMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: widget.isShifted
                                ? Color(TeleDeckColors.neonMagenta)
                                : Color(TeleDeckColors.textPrimary).withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      // Number (bottom, larger, highlighted when not shifted)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          widget.number,
                          style: GoogleFonts.robotoMono(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: widget.isShifted
                                ? Color(TeleDeckColors.textPrimary).withValues(alpha: 0.5)
                                : Color(TeleDeckColors.textPrimary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// FN key with long press for settings
class _FnKey extends StatefulWidget {
  final bool isEnabled;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final double flex;

  const _FnKey({
    required this.isEnabled,
    required this.onTap,
    required this.onLongPress,
    required this.flex,
  });

  @override
  State<_FnKey> createState() => _FnKeyState();
}

class _FnKeyState extends State<_FnKey>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.isEnabled
        ? Color(TeleDeckColors.neonCyan)
        : Color(TeleDeckColors.neonCyan);

    return Expanded(
      flex: (widget.flex * 10).toInt(),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: GestureDetector(
          onTapDown: (_) {
            setState(() => _isPressed = true);
            _glowController.forward();
          },
          onTapUp: (_) {
            setState(() => _isPressed = false);
            _glowController.reverse();
            widget.onTap();
          },
          onTapCancel: () {
            setState(() => _isPressed = false);
            _glowController.reverse();
          },
          onLongPress: () {
            widget.onLongPress();
          },
          child: AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return SizedBox.expand(
                child: Container(
                  decoration: BoxDecoration(
                    color: _isPressed
                        ? Color(TeleDeckColors.keyPressed)
                        : Color(TeleDeckColors.keySurface),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: accentColor.withValues(
                        alpha: widget.isEnabled ? 0.8 : 0.3 + (_glowAnimation.value * 0.5),
                      ),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(
                          alpha: widget.isEnabled ? 0.4 : _glowAnimation.value * 0.4,
                        ),
                        blurRadius: widget.isEnabled ? 8 : 8 * _glowAnimation.value,
                        spreadRadius: widget.isEnabled ? 1 : 1 * _glowAnimation.value,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Fn',
                        style: GoogleFonts.robotoMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: widget.isEnabled
                              ? accentColor
                              : Color(TeleDeckColors.textPrimary),
                          letterSpacing: 1,
                        ),
                      ),
                      // Show hint for long press
                      Icon(
                        Icons.settings,
                        color: Color(TeleDeckColors.textPrimary).withValues(alpha: 0.3),
                        size: 10,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Shift key with long press to lock
class _ShiftKey extends StatefulWidget {
  final bool isEnabled;
  final bool isLocked;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final double flex;

  const _ShiftKey({
    required this.isEnabled,
    required this.isLocked,
    required this.onTap,
    required this.onLongPress,
    required this.flex,
  });

  @override
  State<_ShiftKey> createState() => _ShiftKeyState();
}

class _ShiftKeyState extends State<_ShiftKey>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Different colors for different states
    Color accentColor;
    if (widget.isLocked) {
      accentColor = Color(TeleDeckColors.neonCyan); // Cyan when locked
    } else if (widget.isEnabled) {
      accentColor = Color(TeleDeckColors.neonMagenta); // Magenta when enabled
    } else {
      accentColor = Color(TeleDeckColors.neonCyan); // Default cyan
    }

    return Expanded(
      flex: (widget.flex * 10).toInt(),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: GestureDetector(
          onTapDown: (_) {
            setState(() => _isPressed = true);
            _glowController.forward();
          },
          onTapUp: (_) {
            setState(() => _isPressed = false);
            _glowController.reverse();
            widget.onTap();
          },
          onTapCancel: () {
            setState(() => _isPressed = false);
            _glowController.reverse();
          },
          onLongPress: () {
            widget.onLongPress();
          },
          child: AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return SizedBox.expand(
                child: Container(
                  decoration: BoxDecoration(
                    color: _isPressed
                        ? Color(TeleDeckColors.keyPressed)
                        : Color(TeleDeckColors.keySurface),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: accentColor.withValues(
                        alpha: (widget.isEnabled || widget.isLocked) ? 0.8 : 0.3 + (_glowAnimation.value * 0.5),
                      ),
                      width: widget.isLocked ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(
                          alpha: (widget.isEnabled || widget.isLocked) ? 0.4 : _glowAnimation.value * 0.4,
                        ),
                        blurRadius: (widget.isEnabled || widget.isLocked) ? 8 : 8 * _glowAnimation.value,
                        spreadRadius: (widget.isEnabled || widget.isLocked) ? 1 : 1 * _glowAnimation.value,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.isLocked ? Icons.lock : Icons.arrow_upward,
                        color: accentColor,
                        size: 18,
                      ),
                      if (widget.isLocked)
                        Text(
                          'LOCK',
                          style: GoogleFonts.robotoMono(
                            fontSize: 8,
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Helper for building animated containers
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
