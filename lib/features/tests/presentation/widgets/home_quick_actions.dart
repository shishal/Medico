import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/comic_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/comic_card.dart';

/// Secondary shortcuts once the shell owns Practice / Trackers / Profile.
class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final comic = ComicColors.of(context);
    final actions = [
      (
        'Progress',
        Icons.local_fire_department_outlined,
        AppRoutes.progress,
        StickerFills.blush,
      ),
      (
        'Bookmarks',
        Icons.bookmark_outline,
        AppRoutes.bookmarks,
        StickerFills.lavender,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: Row(
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: Spacing.sm),
            Expanded(
              child: ComicCard(
                color: Color.alphaBlend(
                  (brightness == Brightness.dark
                          ? StickerFills.subjectDark[i]
                          : actions[i].$4)
                      .withValues(alpha: 0.55),
                  comic.sticker,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.md,
                ),
                onTap: () => context.push(actions[i].$3),
                child: Row(
                  children: [
                    Icon(actions[i].$2),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: Text(
                        actions[i].$1,
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
