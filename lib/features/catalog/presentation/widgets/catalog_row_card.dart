import 'package:flutter/material.dart';

import '../../../../core/theme/comic_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/comic_card.dart';
import '../../../../core/widgets/staggered_fade.dart';

/// Shared topic / lesson / PYQ row used in the catalog drill-down.
class CatalogRowCard extends StatelessWidget {
  const CatalogRowCard({
    super.key,
    required this.title,
    required this.index,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final String title;
  final int index;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final comic = ComicColors.of(context);
    final tint = StickerFills.tintAt(index, Theme.of(context).brightness);

    return StaggeredFade(
      index: index,
      child: ComicCard(
        color: Color.alphaBlend(tint.withValues(alpha: 0.38), comic.sticker),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: Spacing.xs),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
