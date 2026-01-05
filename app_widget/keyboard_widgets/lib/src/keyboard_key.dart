import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tele_theme/tele_theme.dart';

/// A single keyboard key with cyberpunk styling
class KeyboardKey extends StatefulWidget {
  final String label;
  final String? displayLabel;
  final VoidCallback onTap;
  final double flex;
  final bool isSpecial;
  final Color? accentColor;
  final IconData? icon;

  const KeyboardKey({
    super.key,
    required this.label,
    this.displayLabel,
    required this.onTap,
    this.flex = 1.0,
    this.isSpecial = false,
    this.accentColor,
    this.icon,
  });

  @override
  State<KeyboardKey> createState() => _KeyboardKeyState();
}

class _KeyboardKeyState extends State<KeyboardKey>
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
    final accentColor = widget.accentColor ?? const Color(TeleDeckColors.neonCyan);

    return Expanded(
      flex: (widget.flex * 10).toInt(),
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
                        ? const Color(TeleDeckColors.keyPressed)
                        : const Color(TeleDeckColors.keySurface),
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
                      if (_isPressed)
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.2),
                          blurRadius: 4,
                          spreadRadius: -2,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Center(
                    child: widget.icon != null
                        ? Icon(
                            widget.icon,
                            color: widget.isSpecial
                                ? accentColor
                                : const Color(TeleDeckColors.textPrimary),
                            size: 20,
                          )
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              widget.displayLabel ?? widget.label,
                              style: GoogleFonts.robotoMono(
                                fontSize: widget.isSpecial ? 11 : 14,
                                fontWeight: FontWeight.w600,
                                color: widget.isSpecial
                                    ? accentColor
                                    : const Color(TeleDeckColors.textPrimary),
                                letterSpacing: widget.isSpecial ? 1 : 0,
                              ),
                            ),
                          ),
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
