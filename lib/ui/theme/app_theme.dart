import 'package:flutter/material.dart';

/// Modern e-commerce theme shared across the whole app, for light or dark
/// mode (see [Brightness]). Everything visual derives from the seeded
/// [ColorScheme], so the two themes stay in lockstep — only the scaffold
/// background and divider need bespoke per-brightness colors.
ThemeData buildShopTheme({Brightness brightness = Brightness.light}) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF4F46E5),
    brightness: brightness,
  );
  final isDark = brightness == Brightness.dark;
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    // Bespoke per-brightness backgrounds: the dark analog (0xFF12121A) is the
    // same softly-tinted off-black family as the light one (0xFFF6F6FA), so
    // cards (colorScheme.surface) still stand out against the scaffold.
    scaffoldBackgroundColor: isDark
        ? const Color(0xFF12121A)
        : const Color(0xFFF6F6FA),
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    // Cards (via SurfaceCard) are flat surface panels with a 16px radius.
    cardTheme: CardThemeData(
      elevation: 0,
      color: colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    // Text fields are filled surface panels with no border (see SearchField).
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: colorScheme.surface,
      contentPadding: EdgeInsets.zero,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: DividerThemeData(
      // Dark counterpart of the light 0xFFE8E8F0 hairline.
      color: isDark ? const Color(0xFF2A2A35) : const Color(0xFFE8E8F0),
      thickness: 1,
    ),
  );
}
