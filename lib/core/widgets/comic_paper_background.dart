import 'package:flutter/material.dart';

import '../theme/comic_colors.dart';

/// Full-page warm paper. Doodles/dot-grid were dropped so chrome stays
/// Figma-soft; the canvas color is still the comic paper, not a cool grey.
class ComicPaperBackground extends StatelessWidget {
  const ComicPaperBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: ComicColors.of(context).paper, child: child);
  }
}
