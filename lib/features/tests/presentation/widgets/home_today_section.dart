import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/user_facing_error.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_section_title.dart';
import '../../../../core/widgets/async_status_views.dart';
import '../providers/in_progress_attempts_provider.dart';

class HomeTodaySection extends ConsumerWidget {
  const HomeTodaySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(inProgressAttemptsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSectionTitle(
          title: 'Today',
          subtitle: 'Resume a session or start practice',
        ),
        if (async.hasError)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: AppCard(
              child: AsyncErrorView(
                compact: true,
                message: UserFacingError.display(async.error!),
                onAction: () => ref.invalidate(inProgressAttemptsProvider),
              ),
            ),
          )
        else if (async.value == null || async.value!.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: AppCard(
              color: CategoryTints.at(0, Theme.of(context).brightness),
              onTap: () => context.go(AppRoutes.practice),
              child: Row(
                children: [
                  Icon(
                    Icons.play_circle_outline_rounded,
                    size: 36,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start practice',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Build a custom MCQ session',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: Column(
              children: [
                for (final item in async.value!.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.sm),
                    child: AppCard(
                      onTap: () =>
                          context.go(AppRoutes.testPlayerPath(item.testId)),
                      child: Row(
                        children: [
                          Icon(
                            Icons.play_circle_outline_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: Spacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const Text('In progress — tap to resume'),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
