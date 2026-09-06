import 'package:flutter/material.dart';

/// Canvas + card colors. Dark is charcoal (Gecko-like); light is clean gray.
///
/// Ink is for glyphs only — not card/button outlines.
@immutable
class ComicColors extends ThemeExtension<ComicColors> {
  const ComicColors({
    required this.ink,
    required this.paper,
    required this.sticker,
    required this.stickerLift,
    required this.shadow,
    required this.accentPurple,
    required this.proGold,
  });

  final Color ink;
  final Color paper;
  final Color sticker;

  /// One step above [sticker] — hero tiles, selected chrome.
  final Color stickerLift;

  final Color shadow;

  /// Section chrome / progress — indigo-purple, not primary orange.
  final Color accentPurple;

  /// Pro chips only.
  final Color proGold;

  static const light = ComicColors(
    ink: Color(0xFF1A1A1E),
    paper: Color(0xFFF4F4F5),
    sticker: Color(0xFFFFFFFF),
    stickerLift: Color(0xFFF8F8FA),
    shadow: Color(0x331A1A1E),
    accentPurple: Color(0xFF6C5CE7),
    proGold: Color(0xFFC9A227),
  );

  static const dark = ComicColors(
    ink: Color(0xFFF2F2F3),
    paper: Color(0xFF121212),
    sticker: Color(0xFF252528),
    stickerLift: Color(0xFF2E2E33),
    shadow: Color(0xCC000000),
    accentPurple: Color(0xFF8B7CFF),
    proGold: Color(0xFFF5C542),
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
    Color? stickerLift,
    Color? shadow,
    Color? accentPurple,
    Color? proGold,
  }) {
    return ComicColors(
      ink: ink ?? this.ink,
      paper: paper ?? this.paper,
      sticker: sticker ?? this.sticker,
      stickerLift: stickerLift ?? this.stickerLift,
      shadow: shadow ?? this.shadow,
      accentPurple: accentPurple ?? this.accentPurple,
      proGold: proGold ?? this.proGold,
    );
  }

  @override
  ThemeExtension<ComicColors> lerp(ThemeExtension<ComicColors>? other, double t) {
    if (other is! ComicColors) return this;
    return ComicColors(
      ink: Color.lerp(ink, other.ink, t) ?? ink,
      paper: Color.lerp(paper, other.paper, t) ?? paper,
      sticker: Color.lerp(sticker, other.sticker, t) ?? sticker,
      stickerLift: Color.lerp(stickerLift, other.stickerLift, t) ?? stickerLift,
      shadow: Color.lerp(shadow, other.shadow, t) ?? shadow,
      accentPurple: Color.lerp(accentPurple, other.accentPurple, t) ?? accentPurple,
      proGold: Color.lerp(proGold, other.proGold, t) ?? proGold,
    );
  }
}

/// Saturated accents for icon wells — not muddy full-card fills.
abstract final class StickerFills {
  static const mint = Color(0xFFB8E8E0);
  static const peach = Color(0xFFFFD6A8);
  static const lavender = Color(0xFFD5C7FF);
  static const blush = Color(0xFFFFC4C4);
  static const butter = Color(0xFFFFE08A);
  static const sky = Color(0xFFB7D8FF);

  static const subjectLight = [peach, lavender, mint, blush, butter, sky];
  static const subjectDark = [
    Color(0xFF6B3A22),
    Color(0xFF3D356B),
    Color(0xFF2A4A48),
    Color(0xFF6B3A3A),
    Color(0xFF5A4A1C),
    Color(0xFF2A3A5C),
  ];

  static const _accents = [
    Color(0xFFF25C2D),
    Color(0xFF8B7CFF),
    Color(0xFF2EC4B6),
    Color(0xFFFF7A59),
    Color(0xFF5B8DEF),
    Color(0xFFE8B931),
  ];

  /// Bright accent for glyphs / rails on raised charcoal cards.
  static Color subjectAccent(String name) =>
      _accents[_hash(name) % _accents.length];

  static Color tintAt(int index, Brightness brightness) {
    final palette = brightness == Brightness.dark ? subjectDark : subjectLight;
    return palette[index % palette.length];
  }

  static Color accentAt(int index) => _accents[index % _accents.length];

  static int _hash(String name) {
    var h = 0;
    for (final c in name.toLowerCase().codeUnits) {
      h = 0x1fffffff & (h + c);
    }
    return h;
  }
}
