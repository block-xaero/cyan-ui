// ============================================================================
// THEME & CONSTANTS
// ============================================================================

import 'dart:ui';

import 'package:flutter/material.dart';

class CyanTheme {
  static const Color background = Color(0xFF272822);
  static const Color surface = Color(0xFF3E3D32);
  static const Color primary = Color(0xFF66D9EF);
  static const Color secondary = Color(0xFFA6E22E);
  static const Color accent = Color(0xFFF92672);
  static const Color text = Color(0xFFF8F8F2);
  static const Color textSecondary = Color(0xFF75715E);
  static const Color warning = Color(0xFFE6DB74);

  static ThemeData get theme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          background: background,
          surface: surface,
          primary: primary,
          secondary: secondary,
          error: accent,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          foregroundColor: text,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: text, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: text),
          bodyMedium: TextStyle(color: textSecondary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: background,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: textSecondary),
        ),
      );
}
