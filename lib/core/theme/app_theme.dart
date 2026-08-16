import 'package:flutter/material.dart';

/// Material 3 themes from a single seed (deep teal — medical/trustworthy, not
/// the default Material purple).
abstract final class AppTheme {
  static const Color _seedColor = Color(0xFF0D7377);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
    );
  }
}
