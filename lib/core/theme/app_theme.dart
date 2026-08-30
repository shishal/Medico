import 'package:flutter/material.dart';

import 'comic_colors.dart';
import 'spacing.dart';

/// Material 3 + comic sticker chrome. Seed stays deep teal (medical, not
/// default purple). Urgent orange is reserved for timer/submit only.
abstract final class AppTheme {
  static const Color seedColor = Color(0xFF0D7377);

  /// Reserved for urgent actions only: timer running low, submit test, etc.
  static const Color accentUrgent = Color(0xFFE65100);

  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final comic = brightness == Brightness.dark
        ? ComicColors.dark
        : ComicColors.light;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    ).copyWith(surface: comic.paper);

    final ink = comic.ink;
    final radius = BorderRadius.circular(18);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: comic.paper,
      extensions: [comic],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: comic.paper,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: colorScheme.onSurface,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: comic.sticker,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: ink, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: ink, width: 2),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: ink, width: 2),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: ink, width: 2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: comic.sticker,
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: ink, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: ink, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: ink, width: 2.4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
      ),
    );
  }
}

/// Access the urgent accent without sprinkling the raw color through widgets.
extension AppThemeExtension on ThemeData {
  Color get urgentAccent => AppTheme.accentUrgent;
}
