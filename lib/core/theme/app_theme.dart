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

  // Users page semantic tokens.
  static const usersSurface = Color(0xFFFFFFFF);
  static const usersMuted = Color(0xFF77756C);
  static const usersMutedStrong = Color(0xFF66655D);
  static const usersMutedLight = Color(0xFF9B978C);
  static const usersDivider = Color(0xFFD9D4CC);
  static const usersGoldBorder = Color(0xFFC08716);
  static const usersGoldSoft = Color(0xFFFFF5D6);
  static const usersGoldText = Color(0xFF665018);
  static const usersSuccessDark = Color(0xFF276C5B);
  static const usersStatusSurface = Color(0xFFEFF8F5);
  static const usersStatusBorder = Color(0xFFB6DAD5);
  static const usersLocalSurface = Color(0xFFFFF8E8);
  static const usersLocalBorder = Color(0xFFEAD49A);
  static const usersError = Color(0xFFA9463F);
  static const usersErrorSurface = Color(0xFFFFF1EF);
  static const usersErrorIconSurface = Color(0xFFFFE2DE);
  static const usersErrorBorder = Color(0xFFF0C8C2);
  static const usersErrorText = Color(0xFF754B48);
  static const usersSkeleton = Color(0xFFEEEAE3);

  static const usersDarkSurfaceAlt = Color(0xFF32322D);
  static const usersDarkMuted = Color(0xFFB5B3AA);
  static const usersDarkMutedStrong = Color(0xFFD0CEC5);
  static const usersDarkMutedLight = Color(0xFF8E8D86);
  static const usersDarkDivider = Color(0xFF57564E);
  static const usersDarkGoldBorder = Color(0xFFB77C0F);
  static const usersDarkGoldSoft = Color(0xFF5F4E21);
  static const usersDarkGoldText = Color(0xFFF0D27D);
  static const usersDarkSuccess = Color(0xFF61B59D);
  static const usersDarkSuccessDark = Color(0xFF9BDCC8);
  static const usersDarkStatusSurface = Color(0xFF203B36);
  static const usersDarkStatusBorder = Color(0xFF477C6F);
  static const usersDarkLocalSurface = Color(0xFF44351B);
  static const usersDarkLocalBorder = Color(0xFF80621E);
  static const usersDarkError = Color(0xFFFF9B90);
  static const usersDarkErrorSurface = Color(0xFF422623);
  static const usersDarkErrorIconSurface = Color(0xFF5E302C);
  static const usersDarkErrorBorder = Color(0xFF7D433C);
  static const usersDarkErrorText = Color(0xFFFFC0B8);
  static const usersDarkSkeleton = Color(0xFF3A3934);

  static ThemeData get light => _buildTheme(Brightness.light);

  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background = isDark ? homeDarkBackground : homeLightBackground;
    final onSurface = isDark ? homeDarkText : homeLightText;
    final surface = isDark ? homeDarkSurface : homeWarmSurface;
    final border = isDark ? homeDarkBorder : homeLightBorder;

    final colorScheme =
        ColorScheme.fromSeed(
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
    ).apply(bodyColor: onSurface, displayColor: onSurface);

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
          return isDark
              ? Colors.white.withValues(alpha: 0.2)
              : const Color(0xFFB5A78F);
        }),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return homeGold;
          return Colors.white;
        }),
      ),
    );
  }
}
