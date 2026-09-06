import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/brand_assets.dart';
import '../../../../core/theme/comic_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/comic_card.dart';
import '../../../../core/widgets/comic_mascot.dart';
import '../../../catalog/domain/catalog_models.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import '../../../profile/presentation/providers/current_plan_provider.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';
import '../../../progress/presentation/providers/ug_home_providers.dart';

/// Greeting: Docci + name + year/university. Plan pill is display-only.
class HomeHeroBanner extends ConsumerWidget {
  const HomeHeroBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    final plan = ref.watch(currentPlanProvider).value;
    final streak = ref.watch(studyProgressProvider).value?.streak ?? 0;
    final unis = ref.watch(universitiesProvider).value ?? const [];
    final phases = ref.watch(mbbsPhasesProvider).value ?? const [];
    final name = profile?.fullName?.trim();
    final hello = (name == null || name.isEmpty)
        ? 'Hi intern'
        : 'Hi, ${_firstName(name)}';

    University? uni;
    for (final u in unis) {
      if (u.id == profile?.universityId) uni = u;
    }
    String? yearName;
    for (final p in phases) {
      if (p.id == profile?.mbbsPhaseId) yearName = p.name;
    }

    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final subtitleParts = [
      ?yearName,
      ?uni?.code,
      if (streak > 0) '$streak-day streak',
    ];

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
                  subtitleParts.isEmpty
                      ? 'Pick a subject to start.'
                      : subtitleParts.join(' · '),
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
                  color: ComicColors.of(context).proGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  plan.label,
                  style: textTheme.labelLarge?.copyWith(
                    color: ComicColors.of(context).proGold,
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

class HomeCoverageBanner extends ConsumerWidget {
  const HomeCoverageBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(universityCoverageProvider);
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (c) {
        final scheme = Theme.of(context).colorScheme;
        final comic = ComicColors.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.md,
            Spacing.lg,
            0,
          ),
          child: ComicCard(
            color: Color.alphaBlend(
              scheme.primary.withValues(alpha: 0.22),
              comic.stickerLift,
            ),
            highlighted: true,
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.45),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${c.pyqCount} PYQs · ${c.paperCount} papers indexed',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        c.usingFallback
                            ? 'Showing default PYQs until ${c.selectedUniversityName ?? 'your university'} papers are added.'
                            : 'Counts are from tagged university papers — not a marketing score.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
