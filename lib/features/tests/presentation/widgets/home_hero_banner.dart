import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/brand_assets.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/comic_mascot.dart';
import '../../../profile/presentation/providers/current_plan_provider.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';
import '../../../progress/presentation/providers/ug_home_providers.dart';

/// Figma-style greeting: Docci + first name + search. Plan pill is display-only.
class HomeHeroBanner extends ConsumerWidget {
  const HomeHeroBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    final plan = ref.watch(currentPlanProvider).value;
    final streak = ref.watch(studyProgressProvider).value?.streak ?? 0;
    final name = profile?.fullName?.trim();
    final hello = (name == null || name.isEmpty)
        ? 'Hi intern'
        : 'Hi, ${_firstName(name)}';

    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.md, Spacing.lg, 0),
      child: Row(
        children: [
          const ComicMascot(
            asset: BrandAssets.mascotWave,
            size: 56,
            heroTag: BrandAssets.mascotHeroTag,
            bounce: false,
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hello,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  streak == 0
                      ? 'Pick a year, then a subject.'
                      : '$streak-day streak · pick a subject',
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (plan != null)
            Padding(
              padding: const EdgeInsets.only(right: Spacing.sm),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.sm,
                  vertical: Spacing.xs,
                ),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  plan.label,
                  style: textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          IconButton.filledTonal(
            tooltip: 'Search',
            onPressed: () => context.push(AppRoutes.search),
            icon: const Icon(Icons.search_rounded),
          ),
        ],
      ),
    );
  }

  static String _firstName(String full) {
    final space = full.indexOf(' ');
    return space <= 0 ? full : full.substring(0, space);
  }
}
