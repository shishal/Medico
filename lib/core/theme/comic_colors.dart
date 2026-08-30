import 'package:flutter/material.dart';

/// Comic palette on a soft dashboard: warm paper, sticker fills, pastel tints.
///
/// Canvas stays the comic paper (`#FBF4E6`), not a cool grey. Ink is for
/// glyphs only — not card/button outlines.
@immutable
class ComicColors extends ThemeExtension<ComicColors> {
  const ComicColors({
    required this.ink,
    required this.paper,
    required this.sticker,
    required this.shadow,
  });

  final Color ink;
  final Color paper;
  final Color sticker;
  final Color shadow;

  static const light = ComicColors(
    ink: Color(0xFF1B2B2B),
    paper: Color(0xFFFBF4E6),
    sticker: Color(0xFFFFFDF8),
    shadow: Color(0x1A1B2B2B),
  );

  static const dark = ComicColors(
    ink: Color(0xFFE7F2F0),
    paper: Color(0xFF121A1B),
    sticker: Color(0xFF1C2A2C),
    shadow: Color(0x66000000),
  );

  static ComicColors of(BuildContext context) {
    return Theme.of(context).extension<ComicColors>() ??
        (Theme.of(context).brightness == Brightness.dark ? dark : light);
  }

  @override
  ComicColors copyWith({
    Color? ink,
    Color? paper,
    Color? sticker,
    Color? shadow,
  }) {
    return ComicColors(
      ink: ink ?? this.ink,
      paper: paper ?? this.paper,
      sticker: sticker ?? this.sticker,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  ComicColors lerp(ThemeExtension<ComicColors>? other, double t) {
    if (other is! ComicColors) return this;
    return ComicColors(
      ink: Color.lerp(ink, other.ink, t) ?? ink,
      paper: Color.lerp(paper, other.paper, t) ?? paper,
      sticker: Color.lerp(sticker, other.sticker, t) ?? sticker,
      shadow: Color.lerp(shadow, other.shadow, t) ?? shadow,
    );
  }
}

/// Decorative fills for year / subject cards (not the urgent accent).
abstract final class StickerFills {
  static const mint = Color(0xFFB8E8E0);
  static const peach = Color(0xFFFFD6A8);
  static const lavender = Color(0xFFD5C7FF);
  static const blush = Color(0xFFFFC4C4);
  static const butter = Color(0xFFFFE08A);
  static const sky = Color(0xFFB7D8FF);

  static const yearLight = [mint, peach, lavender, blush];
  static const yearDark = [
    Color(0xFF2A5A55),
    Color(0xFF6B4A28),
    Color(0xFF4A3D6B),
    Color(0xFF6B3A3A),
  ];

  static const subjectLight = [mint, peach, lavender, blush, butter, sky];
  static const subjectDark = [
    Color(0xFF2A5A55),
    Color(0xFF6B4A28),
    Color(0xFF4A3D6B),
    Color(0xFF6B3A3A),
    Color(0xFF5A4A1C),
    Color(0xFF2A4A6B),
  ];

  static Color yearFill(int displayOrder, Brightness brightness) {
    final palette = brightness == Brightness.dark ? yearDark : yearLight;
    final i = (displayOrder - 1).clamp(0, palette.length - 1);
    return palette[i];
  }

  /// Stable fill so Anatomy is always the same sticker color.
  static Color subjectFill(String name, Brightness brightness) {
    final palette = brightness == Brightness.dark ? subjectDark : subjectLight;
    var h = 0;
    for (final c in name.toLowerCase().codeUnits) {
      h = 0x1fffffff & (h + c);
    }
    return palette[h % palette.length];
  }

  static Color tintAt(int index, Brightness brightness) {
    final palette = brightness == Brightness.dark ? subjectDark : subjectLight;
    return palette[index % palette.length];
  }
}
