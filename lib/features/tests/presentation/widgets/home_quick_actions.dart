import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/comic_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/comic_card.dart';
import '../../../../core/widgets/staggered_fade.dart';

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final actions = [
      (
        'MCQ practice',
        Icons.quiz_outlined,
        AppRoutes.practice,
        StickerFills.mint,
      ),
      ('Trackers', Icons.flag_outlined, AppRoutes.trackers, StickerFills.peach),
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
      child: Column(
        children: [
          for (var i = 0; i < actions.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: StaggeredFade(
                index: i,
                child: ComicCard(
                  color: brightness == Brightness.dark
                      ? StickerFills.subjectDark[i %
                            StickerFills.subjectDark.length]
                      : actions[i].$4,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: Spacing.sm,
                  ),
                  onTap: () {
                    if (actions[i].$3 == AppRoutes.bookmarks) {
                      context.go(actions[i].$3);
                    } else {
                      context.push(actions[i].$3);
                    }
                  },
                  child: Row(
                    children: [
                      Icon(actions[i].$2),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: Text(
                          actions[i].$1,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
