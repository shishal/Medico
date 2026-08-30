import 'package:flutter/material.dart';

/// Soft dashboard extras on top of Material 3 [ColorScheme].
///
/// Canvas is the cool off-white (or deep teal-black) page behind cards.
/// Card is the floating white panel. Shadows stay blurry — no ink outlines.
@immutable
class AppSurfaces extends ThemeExtension<AppSurfaces> {
  const AppSurfaces({
    required this.canvas,
    required this.card,
    required this.shadow,
  });

  final Color canvas;
  final Color card;
  final Color shadow;

  static const light = AppSurfaces(
    canvas: Color(0xFFF7F8FC),
    card: Color(0xFFFFFFFF),
    shadow: Color(0x14000000),
  );

  static const dark = AppSurfaces(
    canvas: Color(0xFF121A1B),
    card: Color(0xFF1C2A2C),
    shadow: Color(0x66000000),
  );

  static AppSurfaces of(BuildContext context) {
    return Theme.of(context).extension<AppSurfaces>() ??
        (Theme.of(context).brightness == Brightness.dark ? dark : light);
  }

  List<BoxShadow> get cardShadow => [
    BoxShadow(color: shadow, blurRadius: 18, offset: const Offset(0, 6)),
  ];

  @override
  AppSurfaces copyWith({Color? canvas, Color? card, Color? shadow}) {
    return AppSurfaces(
      canvas: canvas ?? this.canvas,
      card: card ?? this.card,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppSurfaces lerp(ThemeExtension<AppSurfaces>? other, double t) {
    if (other is! AppSurfaces) return this;
    return AppSurfaces(
      canvas: Color.lerp(canvas, other.canvas, t) ?? canvas,
      card: Color.lerp(card, other.card, t) ?? card,
      shadow: Color.lerp(shadow, other.shadow, t) ?? shadow,
    );
  }
}

/// Pastel fills for category cards (Mini / Subject / Mock / Grand). Not the
/// urgent accent, and not the teal seed.
abstract final class CategoryTints {
  static const mint = Color(0xFFB8E8E0);
  static const peach = Color(0xFFFFD6A8);
  static const lavender = Color(0xFFD5C7FF);
  static const blush = Color(0xFFFFC4C4);
  static const butter = Color(0xFFFFE08A);
  static const sky = Color(0xFFB7D8FF);

  static const _dark = [
    Color(0xFF2A5A55),
    Color(0xFF6B4A28),
    Color(0xFF4A3D6B),
    Color(0xFF6B3A3A),
    Color(0xFF5A4A1C),
    Color(0xFF2A4A6B),
  ];

  static const _light = [mint, peach, lavender, blush, butter, sky];

  static Color at(int index, Brightness brightness) {
    final palette = brightness == Brightness.dark ? _dark : _light;
    return palette[index % palette.length];
  }
}
