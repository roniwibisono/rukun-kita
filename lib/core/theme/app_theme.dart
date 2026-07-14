import 'package:flutter/material.dart';

/// Theme dasar — silakan sesuaikan warna brand "Rukun Kita" di sini.
class AppTheme {
  AppTheme._();

  static const _seedColor = Color(0xFF00B800);
  static const _darkSurface = Color(0xFF171816);
  static const _darkBackground = Color(0xFF272824);
  static const _inputFill = Color(0xFF40413D);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: _seedColor,
        brightness: Brightness.light,
        inputDecorationTheme: const InputDecorationTheme(filled: true),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: _seedColor,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _darkBackground,
        cardTheme: CardThemeData(
          color: _darkSurface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _darkBackground,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _inputFill,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF5A5B56)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _seedColor, width: 1.4),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF053108),
            foregroundColor: _seedColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            minimumSize: const Size.fromHeight(48),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFF5A5B56)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        chipTheme: const ChipThemeData(
          backgroundColor: Color(0xFF171816),
          selectedColor: Color(0xFF003B0C),
          labelStyle: TextStyle(fontWeight: FontWeight.w700),
          side: BorderSide.none,
        ),
        tabBarTheme: const TabBarThemeData(
          dividerHeight: 0,
          labelColor: Colors.white,
          unselectedLabelColor: Color(0xFF969891),
          indicatorSize: TabBarIndicatorSize.tab,
        ),
      );
}
