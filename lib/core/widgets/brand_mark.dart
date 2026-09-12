import 'package:flutter/material.dart';

import '../theme/brand_assets.dart';

/// White ECG-M mark (transparent PNG). Sits on charcoal splash or tints via [color].
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 96, this.color, this.semanticLabel});

  final double size;
  final Color? color;

  /// Null when a nearby wordmark already names the app.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      BrandAssets.splashLogo,
      width: size,
      height: size,
      filterQuality: FilterQuality.high,
      semanticLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
    if (color != null) {
      image = ColorFiltered(
        colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
        child: image,
      );
    }
    return image;
  }
}
