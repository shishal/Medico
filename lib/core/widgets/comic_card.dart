import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../theme/comic_colors.dart';
import '../theme/spacing.dart';

/// Soft card: pastel/sticker fill, blur shadow, light squash on press.
/// Material so ListTile ink still paints (no ink outline).
class ComicCard extends StatefulWidget {
  const ComicCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.padding = const EdgeInsets.all(Spacing.md),
    this.borderRadius = AppTheme.cardRadius,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final EdgeInsets padding;
  final double borderRadius;
  final String? semanticLabel;

  @override
  State<ComicCard> createState() => _ComicCardState();
}

class _ComicCardState extends State<ComicCard> {
  var _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final comic = ComicColors.of(context);
    final fill = widget.color ?? comic.sticker;
    final radius = BorderRadius.circular(widget.borderRadius);

    final card = Material(
      color: fill,
      elevation: _pressed ? 0 : 3,
      shadowColor: comic.shadow,
      borderRadius: radius,
      child: Padding(padding: widget.padding, child: widget.child),
    );

    final scaled = AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: card,
    );

    if (widget.onTap == null) return scaled;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap!();
        },
        child: scaled,
      ),
    );
  }
}
