import 'package:flutter/material.dart';

import 'app_surfaces.dart';
import 'spacing.dart';

/// Material 3 + soft dashboard chrome. Seed stays deep teal (medical, not
/// default purple). Urgent orange is reserved for timer/submit only.
abstract final class AppTheme {
  static const Color seedColor = Color(0xFF0D7377);

  /// Reserved for urgent actions only: timer running low, submit test, etc.
  static const Color accentUrgent = Color(0xFFE65100);

  static const double cardRadius = 22;
  static const double controlRadius = 18;

  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final surfaces = brightness == Brightness.dark
        ? AppSurfaces.dark
        : AppSurfaces.light;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    ).copyWith(surface: surfaces.canvas);

    final radius = BorderRadius.circular(cardRadius);
    final control = BorderRadius.circular(controlRadius);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surfaces.canvas,
      extensions: [surfaces],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: surfaces.canvas,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaces.card,
        shadowColor: surfaces.shadow,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.md,
          ),
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.md,
          ),
          shape: const StadiumBorder(),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: control),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaces.card,
        elevation: 0,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaces.card,
        border: OutlineInputBorder(
          borderRadius: control,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: control,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: control,
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.md,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      tabBarTheme: const TabBarThemeData(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.label,
      ),
    );
  }
}

/// Access the urgent accent without sprinkling the raw color through widgets.
extension AppThemeExtension on ThemeData {
  Color get urgentAccent => AppTheme.accentUrgent;
}
