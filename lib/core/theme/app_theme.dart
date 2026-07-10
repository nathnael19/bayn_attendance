import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light {
    final base = ColorScheme.fromSeed(
      seedColor: const Color(0xFFCA8A04),
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: base.copyWith(
        primary: const Color(0xFFCA8A04),
        secondary: const Color(0xFF0EA5E9),
        surface: const Color(0xFFF7F2E8),
        onSurface: const Color(0xFF1F1A14),
      ),
      scaffoldBackgroundColor: const Color(0xFFF7F2E8),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF7F2E8),
        foregroundColor: Color(0xFF1F1A14),
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      switchTheme: SwitchThemeData(
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(0xFFCA8A04).withValues(alpha: 0.45);
          }
          return const Color(0xFFB5A78F);
        }),
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(0xFFCA8A04);
          }
          return Colors.white;
        }),
      ),
    );
  }

  static ThemeData get dark {
    final base = ColorScheme.fromSeed(
      seedColor: const Color(0xFFCA8A04),
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: base.copyWith(
        primary: const Color(0xFFCA8A04),
        secondary: const Color(0xFF00E5FF),
        surface: const Color(0xFF111117),
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF07070C),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF07070C),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF111117),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      switchTheme: SwitchThemeData(
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(0xFFCA8A04).withValues(alpha: 0.5);
          }
          return Colors.white.withValues(alpha: 0.2);
        }),
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(0xFFCA8A04);
          }
          return Colors.white;
        }),
      ),
    );
  }
}
