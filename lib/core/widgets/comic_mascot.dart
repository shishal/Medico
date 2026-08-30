import 'package:flutter/material.dart';

import '../theme/brand_assets.dart';

/// Idle-bouncing Docci. Wrap with [Hero] on splash → home using [heroTag].
class ComicMascot extends StatefulWidget {
  const ComicMascot({
    super.key,
    required this.asset,
    this.size = 128,
    this.heroTag,
    this.bounce = true,
  });

  final String asset;
  final double size;
  final String? heroTag;
  final bool bounce;

  @override
  State<ComicMascot> createState() => _ComicMascotState();
}

class _ComicMascotState extends State<ComicMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.bounce) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant ComicMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bounce && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.bounce && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      widget.asset,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
    );

    final tag = widget.heroTag;
    if (tag != null) {
      image = Hero(tag: tag, child: image);
    }

    if (!widget.bounce) return image;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Transform.translate(
          offset: Offset(0, -7 * t),
          child: Transform.rotate(angle: 0.04 * (t - 0.5), child: child),
        );
      },
      child: image,
    );
  }
}

/// Tiny circular Docci for app bars.
class MascotAvatar extends StatelessWidget {
  const MascotAvatar({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        BrandAssets.mascotAvatar,
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}
