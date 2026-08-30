import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/comic_colors.dart';
import '../theme/spacing.dart';

/// Sticker-style card: thick ink outline, offset shadow, squash on press.
class ComicCard extends StatefulWidget {
  const ComicCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.padding = const EdgeInsets.all(Spacing.md),
    this.borderRadius = 22,
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
    final ink = comic.ink;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, _pressed ? 3 : 0, 0),
      padding: widget.padding,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: radius,
        border: Border.all(color: ink, width: 2.4),
        boxShadow: _pressed
            ? const []
            : [
                BoxShadow(
                  color: ink.withValues(alpha: 0.88),
                  offset: const Offset(3, 3),
                  blurRadius: 0,
                ),
              ],
      ),
      child: widget.child,
    );

    final scaled = AnimatedScale(
      scale: _pressed ? 0.97 : 1,
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
