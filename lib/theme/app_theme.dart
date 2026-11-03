import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme => _build(Brightness.dark);
  static ThemeData get lightTheme => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1D6FE9),
      brightness: brightness,
      primary: dark ? const Color(0xFF9DC4FF) : const Color(0xFF1D6FE9),
      secondary: dark ? const Color(0xFF9DC4FF) : const Color(0xFF1D6FE9),
      tertiary: dark ? const Color(0xFFFFBE8F) : const Color(0xFFFF6B00),
      primaryContainer: dark ? const Color(0xFF213D61) : AppColors.primaryLight,
      onPrimaryContainer: dark ? const Color(0xFFD9E8FF) : AppColors.primary,
      secondaryContainer: dark
          ? const Color(0xFF213D61)
          : AppColors.primaryLight,
      tertiaryContainer: dark ? const Color(0xFF4B3424) : AppColors.accentLight,
      error: dark ? const Color(0xFFFFB4AB) : AppColors.error,
      onSurface: dark ? const Color(0xFFF0F4FA) : AppColors.onSurface,
      onSurfaceVariant: dark
          ? const Color(0xFFAFBDCD)
          : AppColors.onSurfaceVariant,
      outline: dark ? const Color(0xFF697B90) : AppColors.outlineVariant,
      outlineVariant: dark ? const Color(0xFF35465B) : AppColors.divider,
      surfaceContainerLowest: dark ? const Color(0xFF101B29) : Colors.white,
      surfaceContainerLow: dark ? const Color(0xFF172638) : AppColors.bgInput,
      surfaceContainer: dark ? const Color(0xFF1B2C40) : AppColors.bgInput,
      surfaceContainerHigh: dark ? const Color(0xFF213248) : AppColors.bgInput,
      surfaceContainerHighest: dark
          ? const Color(0xFF2B3D53)
          : AppColors.bgInput,
      surface: dark ? const Color(0xFF192636) : const Color(0xFFFFFFFF),
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
    ).textTheme;
    final typography = base.apply(
      bodyColor: dark ? const Color(0xFFF0F4FA) : AppColors.textPrimary,
      displayColor: dark ? const Color(0xFFF0F4FA) : AppColors.textPrimary,
    );
    final border = dark ? const Color(0xFF35465B) : const Color(0xFFF0F2F5);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: typography.copyWith(
        titleLarge: typography.titleLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: typography.titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: typography.titleSmall?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: typography.bodyLarge?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: typography.bodyMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: typography.bodySmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: scheme.onSurfaceVariant,
        ),
      ),
      scaffoldBackgroundColor: dark
          ? const Color(0xFF101B29)
          : const Color(0xFFF3F4F6),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: dark
            ? const Color(0xFF142339)
            : const Color(0xFFFFFFFF),
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: dark ? Colors.transparent : const Color(0x122E3F35),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        color: dark ? const Color(0xFF1B2C40) : const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide.none,
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 0.5, space: 1),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        iconColor: scheme.primary,
        minVerticalPadding: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF122133) : const Color(0xFFF7F8FA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        hintStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: dark ? scheme.onSurfaceVariant : AppColors.textHint,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          minimumSize: const Size(48, 46),
          shape: shape,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(48, 46),
          shape: shape,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.secondary,
          backgroundColor: dark
              ? const Color(0xFF213D61)
              : const Color(0xFFE8F3FF),
          minimumSize: const Size(48, 46),
          shape: shape,
          side: BorderSide(color: dark ? border : const Color(0xFFBBD5FB)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: dark
            ? const Color(0xFF1D3249)
            : const Color(0xFFF7F8FA),
        selectedColor: scheme.primaryContainer,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: TextStyle(color: scheme.onSurface),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: dark
            ? scheme.onSurfaceVariant
            : AppColors.navInactive,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        dividerColor: Colors.transparent,
      ),
    );
  }
}
