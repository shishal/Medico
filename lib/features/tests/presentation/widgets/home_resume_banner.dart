import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/comic_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/user_facing_error.dart';
import '../../../../core/widgets/async_status_views.dart';
import '../../../../core/widgets/comic_card.dart';
import '../providers/in_progress_attempts_provider.dart';

class HomeResumeBanner extends ConsumerWidget {
  const HomeResumeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(inProgressAttemptsProvider);
    if (async.hasError) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        child: ComicCard(
          child: AsyncErrorView(
            compact: true,
            message: UserFacingError.display(async.error!),
            onAction: () => ref.invalidate(inProgressAttemptsProvider),
          ),
        ),
      );
    }

    final items = async.value;
    if (items == null || items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.md, Spacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in items.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: ComicCard(
                color: Theme.of(context).brightness == Brightness.dark
                    ? StickerFills.subjectDark[5]
                    : StickerFills.sky,
                onTap: () => context.go(AppRoutes.testPlayerPath(item.testId)),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.play_circle_outline),
                  title: Text(item.title),
                  subtitle: const Text(
                    'In-progress MCQ session — tap to resume',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
