import 'package:flutter/material.dart';
import 'package:flutter/services.dart' hide KeyboardKey;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keyboard_bloc/keyboard_bloc.dart';
import 'package:tele_constants/tele_constants.dart';
import 'package:tele_theme/tele_theme.dart';

import 'keyboard_key.dart';
import 'mode_selector_overlay.dart';

/// Shift symbol mappings for special characters
const _shiftSymbolMap = {
  '[': '{',
  ']': '}',
  '\\': '|',
  ';': ':',
  "'": '"',
  ',': '<',
  '.': '>',
  '/': '?',
};

/// BLoC-based keyboard view for IME
class KeyboardView extends StatelessWidget {
  final int rotation;

  const KeyboardView({super.key, this.rotation = 0});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(TeleDeckColors.darkBackground),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Determine if rotation swaps width/height
            final bool isRotated90or270 = rotation == 1 || rotation == 3;

            // For 90/270 rotation, build content for swapped dimensions
            final contentWidth = isRotated90or270
                ? constraints.maxHeight
                : constraints.maxWidth;
            final contentHeight = isRotated90or270
                ? constraints.maxWidth
                : constraints.maxHeight;

            // Build layout based on content dimensions
            final isPortrait = contentHeight > contentWidth;

            // Build the keyboard content
            Widget keyboardContent = _buildLayout(context, isPortrait);

            // Apply rotation if needed
            if (rotation != 0) {
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

  Widget _buildLayout(BuildContext context, bool isPortrait) {
    return Column(
      children: [
        _KeyboardHeader(),
        Expanded(child: _KeyboardBody()),
      ],
    );
  }
}

/// Header bar with connection status
class _KeyboardHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KeyboardBloc, KeyboardState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: const Color(
                  TeleDeckColors.neonMagenta,
                ).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // IME picker button
              GestureDetector(
                onTap: () => _openImePicker(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(
                        TeleDeckColors.neonCyan,
                      ).withValues(alpha: 0.5),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.keyboard_alt_outlined,
                    color: const Color(TeleDeckColors.neonCyan),
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Settings info button
              GestureDetector(
                onTap: () => _showSettingsInfo(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(
                        TeleDeckColors.textPrimary,
                      ).withValues(alpha: 0.3),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.settings,
                    color: const Color(
                      TeleDeckColors.textPrimary,
                    ).withValues(alpha: 0.7),
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Title
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: state.isConnected
                        ? const Color(TeleDeckColors.neonCyan)
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
                        color: state.isConnected
                            ? const Color(TeleDeckColors.neonCyan)
                            : Colors.red,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (state.isConnected
                                        ? const Color(TeleDeckColors.neonCyan)
                                        : Colors.red)
                                    .withValues(alpha: 0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      state.isConnected ? 'LINKED' : 'SYNC',
                      style: GoogleFonts.robotoMono(
                        fontSize: 10,
                        color: const Color(TeleDeckColors.textPrimary),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Hide keyboard button
              GestureDetector(
                onTap: () => _hideKeyboard(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(
                        TeleDeckColors.neonMagenta,
                      ).withValues(alpha: 0.5),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.keyboard_hide,
                    color: const Color(TeleDeckColors.neonMagenta),
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _hideKeyboard(BuildContext context) {
    // Use platform channel to hide keyboard
    const channel = MethodChannel('tele_deck/ime');
    channel.invokeMethod('hideKeyboard');
  }

  void _openImePicker(BuildContext context) {
    // Use platform channel to open system IME picker
    const channel = MethodChannel('tele_deck/ime');
    channel.invokeMethod('openImePicker');
  }

  void _showSettingsInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(TeleDeckColors.secondaryBackground),
        title: Text(
          'SETTINGS',
          style: GoogleFonts.robotoMono(
            color: const Color(TeleDeckColors.neonCyan),
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
                color: const Color(TeleDeckColors.textPrimary),
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CLOSE',
              style: GoogleFonts.robotoMono(
                color: const Color(TeleDeckColors.neonCyan),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Main keyboard body with mode-specific layouts
class _KeyboardBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KeyboardBloc, KeyboardState>(
      builder: (context, state) {
        Widget keyboardContent;
        switch (state.mode) {
          case KeyboardMode.numpad:
            keyboardContent = const _NumpadLayout();
          case KeyboardMode.emoji:
            keyboardContent = const _EmojiLayout();
          case KeyboardMode.standard:
          default:
            keyboardContent = const _StandardLayout();
        }

        return Stack(
          children: [
            keyboardContent,
            if (state.showModeSelector)
              const Positioned.fill(child: ModeSelectorOverlay()),
          ],
        );
      },
    );
  }
}

/// Standard QWERTY keyboard layout
class _StandardLayout extends StatelessWidget {
  const _StandardLayout();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KeyboardBloc, KeyboardState>(
      builder: (context, state) {
        final isUpperCase = state.isShiftActive;

        return Container(
          padding: const EdgeInsets.all(2),
          child: Column(
            children: [
              Expanded(child: _FunctionRow(fnEnabled: state.fnEnabled)),
              Expanded(child: _NumberRow(isShifted: state.shiftEnabled)),
              Expanded(child: _QwertyRow(isUpperCase: isUpperCase)),
              Expanded(
                child: _AsdfRow(
                  isUpperCase: isUpperCase,
                  isCapsLock: state.capsLockEnabled,
                ),
              ),
              Expanded(
                child: _ZxcvRow(
                  isUpperCase: isUpperCase,
                  isShiftEnabled: state.shiftEnabled,
                  isShiftLocked: state.shiftLocked,
                ),
              ),
              Expanded(child: _ModifierRow(state: state)),
            ],
          ),
        );
      },
    );
  }
}

/// Function row (ESC, F1-F12, DEL)
class _FunctionRow extends StatelessWidget {
  final bool fnEnabled;

  const _FunctionRow({required this.fnEnabled});

  // Media function icons for F1-F12 when Fn is pressed
  static const _fnMediaIcons = {
    'F1': Icons.brightness_low,      // Brightness down
    'F2': Icons.brightness_high,     // Brightness up
    'F3': Icons.view_carousel,       // App switcher
    'F4': Icons.search,              // Search/Spotlight
    'F5': Icons.mic_off,             // Mic off
    'F6': Icons.mic,                 // Mic on
    'F7': Icons.skip_previous,       // Previous track
    'F8': Icons.play_arrow,          // Play/Pause
    'F9': Icons.skip_next,           // Next track
    'F10': Icons.volume_off,         // Mute
    'F11': Icons.volume_down,        // Volume down
    'F12': Icons.volume_up,          // Volume up
  };

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<KeyboardBloc>();

    return Row(
      children: KeyboardLayout.functionRow.map((key) {
        if (key == 'ESC') {
          return KeyboardKey(
            label: key,
            displayLabel: 'Esc',
            onTap: () => bloc.add(const KeyboardEscapePressed()),
            isSpecial: true,
          );
        } else if (key == 'DEL') {
          return KeyboardKey(
            label: key,
            displayLabel: 'Del',
            onTap: () => bloc.add(const KeyboardDeletePressed()),
            isSpecial: true,
            enableLongPressRepeat: true,
          );
        } else if (key.startsWith('F')) {
          final num = int.parse(key.substring(1));
          final mediaIcon = _fnMediaIcons[key];
          return KeyboardKey(
            label: key,
            displayLabel: fnEnabled ? null : key,
            icon: fnEnabled ? mediaIcon : null,
            onTap: () => bloc.add(KeyboardFunctionKeyPressed(num)),
            isSpecial: true,
            accentColor: fnEnabled
                ? const Color(TeleDeckColors.neonMagenta)
                : null,
          );
        }
        return KeyboardKey(label: key, onTap: () {});
      }).toList(),
    );
  }
}

/// Number row
class _NumberRow extends StatelessWidget {
  final bool isShifted;

  const _NumberRow({required this.isShifted});

  static const _numberSymbolMap = {
    '`': '~',
    '1': '!',
    '2': '@',
    '3': '#',
    '4': '\$',
    '5': '%',
    '6': '^',
    '7': '&',
    '8': '*',
    '9': '(',
    '0': ')',
    '-': '_',
    '=': '+',
  };

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<KeyboardBloc>();

    return Row(
      children: KeyboardLayout.numberRow.map((key) {
        if (key == 'BACKSPACE') {
          return KeyboardKey(
            label: key,
            icon: Icons.backspace_outlined,
            onTap: () => bloc.add(const KeyboardBackspacePressed()),
            flex: KeyboardLayout.keyFlex['BACKSPACE'] ?? 1.0,
            isSpecial: true,
            accentColor: const Color(TeleDeckColors.neonMagenta),
            enableLongPressRepeat: true,
          );
        }
        final symbol = _numberSymbolMap[key] ?? key;
        final actualKey = isShifted ? symbol : key;
        return _NumberSymbolKey(
          number: key,
          symbol: symbol,
          isShifted: isShifted,
          onTap: () => bloc.add(KeyboardKeyPressed(actualKey)),
        );
      }).toList(),
    );
  }
}

/// QWERTY row
class _QwertyRow extends StatelessWidget {
  final bool isUpperCase;

  const _QwertyRow({required this.isUpperCase});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<KeyboardBloc>();

    return Row(
      children: KeyboardLayout.qwertyRow.map((key) {
        if (key == 'TAB') {
          return KeyboardKey(
            label: key,
            displayLabel: 'Tab',
            onTap: () => bloc.add(const KeyboardTabPressed()),
            flex: KeyboardLayout.keyFlex['TAB'] ?? 1.0,
            isSpecial: true,
          );
        }
        if (key.length == 1 && key.toUpperCase() != key.toLowerCase()) {
          // Letters: show uppercase when shifted
          final displayKey = isUpperCase
              ? key.toUpperCase()
              : key.toLowerCase();
          return KeyboardKey(
            label: key,
            displayLabel: displayKey,
            onTap: () => bloc.add(KeyboardKeyPressed(displayKey)),
            enableLongPressRepeat: true,
          );
        }
        // Special characters: show both normal and shifted symbol
        final shiftedSymbol = _shiftSymbolMap[key];
        if (shiftedSymbol != null) {
          return _SymbolKey(
            normal: key,
            shifted: shiftedSymbol,
            isShifted: isUpperCase,
            onTap: () => bloc.add(KeyboardKeyPressed(key)),
          );
        }
        return KeyboardKey(
          label: key,
          onTap: () => bloc.add(KeyboardKeyPressed(key)),
          enableLongPressRepeat: true,
        );
      }).toList(),
    );
  }
}

/// ASDF row
class _AsdfRow extends StatelessWidget {
  final bool isUpperCase;
  final bool isCapsLock;

  const _AsdfRow({required this.isUpperCase, required this.isCapsLock});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<KeyboardBloc>();

    return Row(
      children: KeyboardLayout.asdfRow.map((key) {
        if (key == 'CAPS') {
          return KeyboardKey(
            label: key,
            displayLabel: 'Caps',
            onTap: () => bloc.add(KeyboardCapsLockToggled(!isCapsLock)),
            flex: KeyboardLayout.keyFlex['CAPS'] ?? 1.0,
            isSpecial: true,
            accentColor: isCapsLock
                ? const Color(TeleDeckColors.neonMagenta)
                : null,
          );
        } else if (key == 'ENTER') {
          return KeyboardKey(
            label: key,
            icon: Icons.keyboard_return,
            onTap: () => bloc.add(const KeyboardEnterPressed()),
            flex: KeyboardLayout.keyFlex['ENTER'] ?? 1.0,
            isSpecial: true,
            accentColor: const Color(TeleDeckColors.neonCyan),
          );
        }
        if (key.length == 1 && key.toUpperCase() != key.toLowerCase()) {
          // Letters: show uppercase when shifted
          final displayKey = isUpperCase
              ? key.toUpperCase()
              : key.toLowerCase();
          return KeyboardKey(
            label: key,
            displayLabel: displayKey,
            onTap: () => bloc.add(KeyboardKeyPressed(displayKey)),
            enableLongPressRepeat: true,
          );
        }
        // Special characters: show both normal and shifted symbol
        final shiftedSymbol = _shiftSymbolMap[key];
        if (shiftedSymbol != null) {
          return _SymbolKey(
            normal: key,
            shifted: shiftedSymbol,
            isShifted: isUpperCase,
            onTap: () => bloc.add(KeyboardKeyPressed(key)),
          );
        }
        return KeyboardKey(
          label: key,
          onTap: () => bloc.add(KeyboardKeyPressed(key)),
          enableLongPressRepeat: true,
        );
      }).toList(),
    );
  }
}

/// ZXCV row
class _ZxcvRow extends StatelessWidget {
  final bool isUpperCase;
  final bool isShiftEnabled;
  final bool isShiftLocked;

  const _ZxcvRow({
    required this.isUpperCase,
    required this.isShiftEnabled,
    required this.isShiftLocked,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<KeyboardBloc>();

    return Row(
      children: KeyboardLayout.zxcvRow.map((key) {
        if (key == 'SHIFT') {
          return _ShiftKey(
            isEnabled: isShiftEnabled,
            isLocked: isShiftLocked,
            onTap: () {
              if (isShiftLocked) {
                bloc.add(const KeyboardShiftLocked(false));
              } else {
                bloc.add(KeyboardShiftToggled(!isShiftEnabled));
              }
            },
            onLongPress: () {
              bloc.add(const KeyboardShiftLocked(true));
            },
            flex: KeyboardLayout.keyFlex['SHIFT'] ?? 1.0,
          );
        }
        if (key.length == 1 && key.toUpperCase() != key.toLowerCase()) {
          // Letters: show uppercase when shifted
          final displayKey = isUpperCase
              ? key.toUpperCase()
              : key.toLowerCase();
          return KeyboardKey(
            label: key,
            displayLabel: displayKey,
            onTap: () => bloc.add(KeyboardKeyPressed(displayKey)),
            enableLongPressRepeat: true,
          );
        }
        // Special characters: show both normal and shifted symbol
        final shiftedSymbol = _shiftSymbolMap[key];
        if (shiftedSymbol != null) {
          return _SymbolKey(
            normal: key,
            shifted: shiftedSymbol,
            isShifted: isUpperCase,
            onTap: () => bloc.add(KeyboardKeyPressed(key)),
          );
        }
        return KeyboardKey(
          label: key,
          onTap: () => bloc.add(KeyboardKeyPressed(key)),
          enableLongPressRepeat: true,
        );
      }).toList(),
    );
  }
}

/// Modifier row
class _ModifierRow extends StatelessWidget {
  final KeyboardState state;

  const _ModifierRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<KeyboardBloc>();

    return Row(
      children: KeyboardLayout.modifierRow.map((key) {
        switch (key) {
          case 'CTRL':
            return KeyboardKey(
              label: key,
              displayLabel: 'Ctrl',
              onTap: () => bloc.add(KeyboardCtrlToggled(!state.ctrlEnabled)),
              flex: KeyboardLayout.keyFlex['CTRL'] ?? 1.0,
              isSpecial: true,
              accentColor: state.ctrlEnabled
                  ? const Color(TeleDeckColors.neonPurple)
                  : null,
            );
          case 'ALT':
            return KeyboardKey(
              label: key,
              displayLabel: 'Alt',
              onTap: () => bloc.add(KeyboardAltToggled(!state.altEnabled)),
              flex: KeyboardLayout.keyFlex['ALT'] ?? 1.0,
              isSpecial: true,
              accentColor: state.altEnabled
                  ? const Color(TeleDeckColors.neonPurple)
                  : null,
            );
          case 'SUPER':
            return KeyboardKey(
              label: key,
              displayLabel: '\u2318',
              onTap: () => bloc.add(KeyboardSuperToggled(!state.superEnabled)),
              flex: KeyboardLayout.keyFlex['SUPER'] ?? 1.0,
              isSpecial: true,
              accentColor: state.superEnabled
                  ? const Color(TeleDeckColors.neonPurple)
                  : null,
            );
          case 'FN':
            return _FnKey(
              isEnabled: state.fnEnabled,
              onTap: () => bloc.add(KeyboardFnToggled(!state.fnEnabled)),
              onLongPress: () =>
                  bloc.add(const KeyboardModeSelectorChanged(true)),
              flex: KeyboardLayout.keyFlex['FN'] ?? 1.0,
            );
          case 'SPACE':
            return KeyboardKey(
              label: key,
              displayLabel: '',
              onTap: () => bloc.add(const KeyboardKeyPressed(' ')),
              flex: KeyboardLayout.keyFlex['SPACE'] ?? 1.0,
              isSpecial: true,
            );
          case 'LEFT':
            return KeyboardKey(
              label: key,
              icon: Icons.arrow_left,
              onTap: () =>
                  bloc.add(const KeyboardArrowKeyPressed(ArrowDirection.left)),
              flex: KeyboardLayout.keyFlex['LEFT'] ?? 1.0,
              isSpecial: true,
            );
          case 'RIGHT':
            return KeyboardKey(
              label: key,
              icon: Icons.arrow_right,
              onTap: () =>
                  bloc.add(const KeyboardArrowKeyPressed(ArrowDirection.right)),
              flex: KeyboardLayout.keyFlex['RIGHT'] ?? 1.0,
              isSpecial: true,
            );
          case 'UP':
            return KeyboardKey(
              label: key,
              icon: Icons.arrow_drop_up,
              onTap: () =>
                  bloc.add(const KeyboardArrowKeyPressed(ArrowDirection.up)),
              flex: KeyboardLayout.keyFlex['UP'] ?? 1.0,
              isSpecial: true,
            );
          case 'DOWN':
            return KeyboardKey(
              label: key,
              icon: Icons.arrow_drop_down,
              onTap: () =>
                  bloc.add(const KeyboardArrowKeyPressed(ArrowDirection.down)),
              flex: KeyboardLayout.keyFlex['DOWN'] ?? 1.0,
              isSpecial: true,
            );
          default:
            return KeyboardKey(label: key, onTap: () {});
        }
      }).toList(),
    );
  }
}

/// Numpad layout
class _NumpadLayout extends StatelessWidget {
  const _NumpadLayout();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<KeyboardBloc>();

    return Container(
      padding: const EdgeInsets.all(2),
      child: Row(
        children: [
          // Left: Navigation
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      KeyboardKey(
                        label: 'Ins',
                        onTap: () =>
                            bloc.add(const KeyboardKeyPressed('Insert')),
                        isSpecial: true,
                      ),
                      KeyboardKey(
                        label: 'Home',
                        onTap: () => bloc.add(const KeyboardKeyPressed('Home')),
                        isSpecial: true,
                      ),
                      KeyboardKey(
                        label: 'PgUp',
                        onTap: () =>
                            bloc.add(const KeyboardKeyPressed('PageUp')),
                        isSpecial: true,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      KeyboardKey(
                        label: 'Del',
                        onTap: () => bloc.add(const KeyboardDeletePressed()),
                        isSpecial: true,
                      ),
                      KeyboardKey(
                        label: 'End',
                        onTap: () => bloc.add(const KeyboardKeyPressed('End')),
                        isSpecial: true,
                      ),
                      KeyboardKey(
                        label: 'PgDn',
                        onTap: () =>
                            bloc.add(const KeyboardKeyPressed('PageDown')),
                        isSpecial: true,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Spacer(),
                      KeyboardKey(
                        label: 'Up',
                        icon: Icons.arrow_upward,
                        onTap: () => bloc.add(
                          const KeyboardArrowKeyPressed(ArrowDirection.up),
                        ),
                        isSpecial: true,
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      KeyboardKey(
                        label: 'Left',
                        icon: Icons.arrow_back,
                        onTap: () => bloc.add(
                          const KeyboardArrowKeyPressed(ArrowDirection.left),
                        ),
                        isSpecial: true,
                      ),
                      KeyboardKey(
                        label: 'Down',
                        icon: Icons.arrow_downward,
                        onTap: () => bloc.add(
                          const KeyboardArrowKeyPressed(ArrowDirection.down),
                        ),
                        isSpecial: true,
                      ),
                      KeyboardKey(
                        label: 'Right',
                        icon: Icons.arrow_forward,
                        onTap: () => bloc.add(
                          const KeyboardArrowKeyPressed(ArrowDirection.right),
                        ),
                        isSpecial: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Right: Numpad
          Expanded(
            flex: 5,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      KeyboardKey(label: 'Num', onTap: () {}, isSpecial: true),
                      KeyboardKey(
                        label: '/',
                        onTap: () => bloc.add(const KeyboardKeyPressed('/')),
                      ),
                      KeyboardKey(
                        label: '*',
                        onTap: () => bloc.add(const KeyboardKeyPressed('*')),
                      ),
                      KeyboardKey(
                        label: '-',
                        onTap: () => bloc.add(const KeyboardKeyPressed('-')),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      KeyboardKey(
                        label: '7',
                        onTap: () => bloc.add(const KeyboardKeyPressed('7')),
                      ),
                      KeyboardKey(
                        label: '8',
                        onTap: () => bloc.add(const KeyboardKeyPressed('8')),
                      ),
                      KeyboardKey(
                        label: '9',
                        onTap: () => bloc.add(const KeyboardKeyPressed('9')),
                      ),
                      KeyboardKey(
                        label: '+',
                        onTap: () => bloc.add(const KeyboardKeyPressed('+')),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      KeyboardKey(
                        label: '4',
                        onTap: () => bloc.add(const KeyboardKeyPressed('4')),
                      ),
                      KeyboardKey(
                        label: '5',
                        onTap: () => bloc.add(const KeyboardKeyPressed('5')),
                      ),
                      KeyboardKey(
                        label: '6',
                        onTap: () => bloc.add(const KeyboardKeyPressed('6')),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      KeyboardKey(
                        label: '1',
                        onTap: () => bloc.add(const KeyboardKeyPressed('1')),
                      ),
                      KeyboardKey(
                        label: '2',
                        onTap: () => bloc.add(const KeyboardKeyPressed('2')),
                      ),
                      KeyboardKey(
                        label: '3',
                        onTap: () => bloc.add(const KeyboardKeyPressed('3')),
                      ),
                      KeyboardKey(
                        label: 'Enter',
                        icon: Icons.keyboard_return,
                        onTap: () => bloc.add(const KeyboardEnterPressed()),
                        isSpecial: true,
                        accentColor: const Color(TeleDeckColors.neonCyan),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      KeyboardKey(
                        label: '0',
                        onTap: () => bloc.add(const KeyboardKeyPressed('0')),
                        flex: 2,
                      ),
                      KeyboardKey(
                        label: '.',
                        onTap: () => bloc.add(const KeyboardKeyPressed('.')),
                      ),
                      KeyboardKey(
                        label: 'ABC',
                        onTap: () => bloc.add(
                          const KeyboardModeChanged(KeyboardMode.standard),
                        ),
                        isSpecial: true,
                        accentColor: const Color(TeleDeckColors.neonMagenta),
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
}

/// Emoji layout
class _EmojiLayout extends StatelessWidget {
  const _EmojiLayout();

  static const _emojis = [
    '\u{1F600}',
    '\u{1F603}',
    '\u{1F604}',
    '\u{1F601}',
    '\u{1F605}',
    '\u{1F602}',
    '\u{1F923}',
    '\u{1F60A}',
    '\u{1F607}',
    '\u{1F642}',
    '\u{1F609}',
    '\u{1F60C}',
    '\u{1F60D}',
    '\u{1F970}',
    '\u{1F618}',
    '\u{1F617}',
    '\u{1F619}',
    '\u{1F61A}',
    '\u{1F44D}',
    '\u{1F44E}',
    '\u{1F44C}',
    '\u{270C}\u{FE0F}',
    '\u{1F91E}',
    '\u{1F91F}',
    '\u{1F918}',
    '\u{1F919}',
    '\u{1F44B}',
    '\u{1F590}\u{FE0F}',
    '\u{2764}\u{FE0F}',
    '\u{1F9E1}',
    '\u{1F49B}',
    '\u{1F49A}',
    '\u{1F499}',
    '\u{1F49C}',
    '\u{1F5A4}',
    '\u{1F90D}',
    '\u{1F494}',
    '\u{1F495}',
    '\u{1F496}',
  ];

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<KeyboardBloc>();

    return Container(
      padding: const EdgeInsets.all(2),
      child: Column(
        children: [
          Expanded(
            flex: 5,
            child: GridView.builder(
              padding: const EdgeInsets.all(4),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: _emojis.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => bloc.add(KeyboardKeyPressed(_emojis[index])),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(TeleDeckColors.keySurface),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(
                          TeleDeckColors.neonCyan,
                        ).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _emojis[index],
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: Row(
              children: [
                KeyboardKey(
                  label: 'ABC',
                  onTap: () => bloc.add(
                    const KeyboardModeChanged(KeyboardMode.standard),
                  ),
                  isSpecial: true,
                  accentColor: const Color(TeleDeckColors.neonMagenta),
                  flex: 1.5,
                ),
                KeyboardKey(
                  label: 'Backspace',
                  icon: Icons.backspace_outlined,
                  onTap: () => bloc.add(const KeyboardBackspacePressed()),
                  isSpecial: true,
                  flex: 1.5,
                  enableLongPressRepeat: true,
                ),
                KeyboardKey(
                  label: 'Space',
                  displayLabel: '',
                  onTap: () => bloc.add(const KeyboardKeyPressed(' ')),
                  isSpecial: true,
                  flex: 4,
                ),
                KeyboardKey(
                  label: 'Enter',
                  icon: Icons.keyboard_return,
                  onTap: () => bloc.add(const KeyboardEnterPressed()),
                  isSpecial: true,
                  accentColor: const Color(TeleDeckColors.neonCyan),
                  flex: 1.5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Number/Symbol key widget
class _NumberSymbolKey extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Expanded(
      flex: 10,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(TeleDeckColors.keySurface),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(
                  TeleDeckColors.neonCyan,
                ).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  symbol,
                  style: GoogleFonts.robotoMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isShifted
                        ? const Color(TeleDeckColors.neonMagenta)
                        : const Color(
                            TeleDeckColors.textPrimary,
                          ).withValues(alpha: 0.5),
                  ),
                ),
                Text(
                  number,
                  style: GoogleFonts.robotoMono(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isShifted
                        ? const Color(
                            TeleDeckColors.textPrimary,
                          ).withValues(alpha: 0.5)
                        : const Color(TeleDeckColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Symbol key showing both normal and shifted symbol (like [ and {)
class _SymbolKey extends StatelessWidget {
  final String normal;
  final String shifted;
  final bool isShifted;
  final VoidCallback onTap;

  const _SymbolKey({
    required this.normal,
    required this.shifted,
    required this.isShifted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 10,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(TeleDeckColors.keySurface),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(
                  TeleDeckColors.neonCyan,
                ).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  shifted,
                  style: GoogleFonts.robotoMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isShifted
                        ? const Color(TeleDeckColors.neonMagenta)
                        : const Color(
                            TeleDeckColors.textPrimary,
                          ).withValues(alpha: 0.5),
                  ),
                ),
                Text(
                  normal,
                  style: GoogleFonts.robotoMono(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isShifted
                        ? const Color(
                            TeleDeckColors.textPrimary,
                          ).withValues(alpha: 0.5)
                        : const Color(TeleDeckColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shift key with long press support
class _ShiftKey extends StatelessWidget {
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
  Widget build(BuildContext context) {
    Color accentColor;
    if (isLocked) {
      accentColor = const Color(TeleDeckColors.neonCyan);
    } else if (isEnabled) {
      accentColor = const Color(TeleDeckColors.neonMagenta);
    } else {
      accentColor = const Color(TeleDeckColors.neonCyan);
    }

    return Expanded(
      flex: (flex * 10).toInt(),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(TeleDeckColors.keySurface),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: accentColor.withValues(
                  alpha: (isEnabled || isLocked) ? 0.8 : 0.3,
                ),
                width: isLocked ? 2 : 1,
              ),
              boxShadow: (isEnabled || isLocked)
                  ? [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isLocked ? Icons.lock : Icons.arrow_upward,
                  color: accentColor,
                  size: 18,
                ),
                if (isLocked)
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
        ),
      ),
    );
  }
}

/// Fn key with long press for mode selector
class _FnKey extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final accentColor = const Color(TeleDeckColors.neonCyan);

    return Expanded(
      flex: (flex * 10).toInt(),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(TeleDeckColors.keySurface),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: accentColor.withValues(alpha: isEnabled ? 0.8 : 0.3),
                width: 1,
              ),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Fn',
                  style: GoogleFonts.robotoMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isEnabled
                        ? accentColor
                        : const Color(TeleDeckColors.textPrimary),
                    letterSpacing: 1,
                  ),
                ),
                Icon(
                  Icons.settings,
                  color: const Color(
                    TeleDeckColors.textPrimary,
                  ).withValues(alpha: 0.3),
                  size: 10,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
