import 'package:flutter/material.dart';
import 'package:tele_theme/tele_theme.dart';

class SplashScreen extends StatelessWidget {
  static const name = 'Splash';
  static const path = '/';

  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(TeleDeckColors.darkBackground),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(TeleDeckColors.neonCyan),
                  Color(TeleDeckColors.neonMagenta),
                ],
              ).createShader(bounds),
              child: const Text(
                'TELEDECK',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 8,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(TeleDeckColors.neonCyan),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
