import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tele_deck_colors.dart';

/// TeleDeck application theme
class TeleDeckTheme {
  TeleDeckTheme._();

  /// Get the dark theme for TeleDeck
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(TeleDeckColors.darkBackground),
      colorScheme: const ColorScheme.dark(
        primary: Color(TeleDeckColors.neonCyan),
        secondary: Color(TeleDeckColors.neonMagenta),
        tertiary: Color(TeleDeckColors.neonPurple),
        surface: Color(TeleDeckColors.secondaryBackground),
        onPrimary: Color(TeleDeckColors.darkBackground),
        onSecondary: Color(TeleDeckColors.darkBackground),
        onSurface: Color(TeleDeckColors.textPrimary),
      ),
      textTheme: GoogleFonts.jetBrainsMonoTextTheme(
        ThemeData.dark().textTheme,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(TeleDeckColors.darkBackground),
        foregroundColor: Color(TeleDeckColors.textPrimary),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(TeleDeckColors.secondaryBackground),
        elevation: 4,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(TeleDeckColors.neonCyan),
          foregroundColor: const Color(TeleDeckColors.darkBackground),
        ),
      ),
      iconTheme: const IconThemeData(
        color: Color(TeleDeckColors.neonCyan),
      ),
    );
  }
}
