import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const homeLightBackground = Color(0xFFFCFAF5);
  static const homeDarkBackground = Color(0xFF16161A);
  static const homeLightText = Color(0xFF3B3C36);
  static const homeDarkText = Color(0xFFFBFAFA);
  static const homeGold = Color(0xFFD49A1C);
  static const homeSky = Color(0xFF0EA5E9);
  static const homeStatusGreen = Color(0xFF2C8B74);
  static const homeWarmSurface = Color(0xFFF4F0EC);
  static const homeDarkSurface = Color(0xFF272724);
  static const homeLightBorder = Color(0xFFE5E4E2);
  static const homeDarkBorder = Color(0xFF3B3C36);

  static ThemeData get light => _buildTheme(Brightness.light);

  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background = isDark ? homeDarkBackground : homeLightBackground;
    final onSurface = isDark ? homeDarkText : homeLightText;
    final surface = isDark ? homeDarkSurface : homeWarmSurface;
    final border = isDark ? homeDarkBorder : homeLightBorder;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: homeGold,
      brightness: brightness,
    ).copyWith(
      primary: homeGold,
      onPrimary: homeLightText,
      secondary: homeSky,
      onSecondary: Colors.white,
      surface: background,
      onSurface: onSurface,
      surfaceContainerHighest: surface,
      outline: border,
      outlineVariant: border,
    );

    final textTheme = GoogleFonts.atkinsonHyperlegibleTextTheme(
      ThemeData(brightness: brightness).textTheme,
    ).apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return homeGold.withValues(alpha: 0.45);
          }
          return isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFB5A78F);
        }),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return homeGold;
          return Colors.white;
        }),
      ),
    );
  }
}
