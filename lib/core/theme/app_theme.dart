import 'package:flutter/material.dart';

/// Dark, minimal, high-contrast theme for Receipts.
/// Tone: direct and honest. No cartoonish gamification.
/// Supports text scaling and screen readers via standard Material text themes.
class AppTheme {
  static const Color _background = Color(0xFF0A0A0B);
  static const Color _surface = Color(0xFF131316);
  static const Color _primary = Color(0xFFF5F5F0);
  static const Color _accent = Color(0xFFFF3B30);
  static const Color _success = Color(0xFF30D158);
  static const Color _muted = Color(0xFF8E8E93);

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: _background,
      colorScheme: const ColorScheme.dark(
        primary: _primary,
        secondary: _muted,
        surface: _surface,
        error: _accent,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _background,
        foregroundColor: _primary,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: _primary,
        displayColor: _primary,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primary,
        foregroundColor: _background,
      ),
    );
  }

  static Color statusColor(bool? done, {bool paused = false}) {
    if (paused) {
      return _muted;
    }
    if (done == true) {
      return _success;
    }
    return _accent;
  }
}
