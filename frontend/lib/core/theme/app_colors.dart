import 'package:flutter/material.dart';

class AppColors {
  // Primary palette
  static const Color primary = Color(0xFF667EEA);
  static const Color primaryDark = Color(0xFF5A67D8);
  static const Color accent = Color(0xFF48BB78);

  // Background
  static const Color background = Color(0xFF0A0E27);
  static const Color surface = Color(0xFF131836);
  static const Color cardBackground = Color(0xFF1A1F44);

  // Status colors
  static const Color success = Color(0xFF48BB78);
  static const Color warning = Color(0xFFECC94B);
  static const Color danger = Color(0xFFF56565);
  static const Color info = Color(0xFF4299E1);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF48BB78), Color(0xFF38A169)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFF56565), Color(0xFFE53E3E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFECC94B), Color(0xFFD69E2E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0A0E27), Color(0xFF131836), Color(0xFF1A1F44)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Score colors based on credibility
  static Color getScoreColor(int score) {
    if (score >= 70) return success;
    if (score >= 40) return warning;
    return danger;
  }

  static LinearGradient getScoreGradient(int score) {
    if (score >= 70) return successGradient;
    if (score >= 40) return warningGradient;
    return dangerGradient;
  }
}
