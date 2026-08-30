import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_surfaces.dart';
import '../theme/app_theme.dart';
import '../theme/spacing.dart';

/// Soft floating card: Material so ListTiles/ink still paint, large radius,
/// light squash on press.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.padding = const EdgeInsets.all(Spacing.md),
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final EdgeInsets padding;
  final String? semanticLabel;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  var _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = AppSurfaces.of(context);
    final fill = widget.color ?? surfaces.card;
    final radius = BorderRadius.circular(AppTheme.cardRadius);

    // Material (not DecoratedBox) so SwitchListTile / ListTile ink lands here.
    final card = Material(
      color: fill,
      elevation: _pressed ? 0 : 3,
      shadowColor: surfaces.shadow,
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
