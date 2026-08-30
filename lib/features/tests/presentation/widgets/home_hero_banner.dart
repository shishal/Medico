import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/brand_assets.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/comic_card.dart';
import '../../../../core/widgets/comic_mascot.dart';
import '../../../profile/presentation/providers/current_plan_provider.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';
import '../../../progress/presentation/providers/ug_home_providers.dart';

class HomeHeroBanner extends ConsumerWidget {
  const HomeHeroBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    final plan = ref.watch(currentPlanProvider).value;
    final streak = ref.watch(studyProgressProvider).value?.streak ?? 0;
    final name = profile?.fullName?.trim();
    final hello = (name == null || name.isEmpty) ? 'Hey intern' : 'Hey $name';

    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.sm, Spacing.lg, 0),
      child: ComicCard(
        padding: const EdgeInsets.all(Spacing.md),
        child: Row(
          children: [
            ComicMascot(
              asset: BrandAssets.mascotWave,
              size: 92,
              heroTag: BrandAssets.mascotHeroTag,
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hello,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    'Pick a year, then a subject. ${BrandAssets.mascotName} packed the kit.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: Spacing.sm),
                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.xs,
                    children: [
                      _Pill(text: 'Streak $streak'),
                      if (plan != null) _Pill(text: plan.label),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(width: 2),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}
