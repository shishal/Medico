import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/user_facing_error.dart';
import '../../../../core/widgets/async_status_views.dart';
import '../../../../core/widgets/comic_section_title.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import '../../../catalog/presentation/widgets/subject_tile.dart';
import '../../../progress/presentation/providers/ug_home_providers.dart';
import '../providers/pending_submit_sync_provider.dart';
import '../widgets/home_hero_banner.dart';
import '../widgets/home_quick_actions.dart';
import '../widgets/home_resume_banner.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(phaseSubjectsProvider);
    final coverage =
        ref.watch(studyProgressProvider).value?.subjects ?? const [];
    ref.watch(pendingSubmitSyncProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: Spacing.xl),
          children: [
            const HomeHeroBanner(),
            const HomeCoverageBanner(),
            const ComicSectionTitle(
              title: 'Subjects',
              subtitle:
                  'Subject → topic → lesson → PYQs. The ring is lessons marked learnt — not a PYQ count.',
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: subjects.when(
                data: (items) => SubjectStickerGrid(
                  key: ValueKey(items.map((s) => s.id).join(',')),
                  subjects: items,
                  coverage: coverage,
                ),
                loading: () => const Padding(
                  key: ValueKey('subjects-loading'),
                  padding: EdgeInsets.all(Spacing.lg),
                  child: LinearProgressIndicator(),
                ),
                error: (e, _) => Padding(
                  key: const ValueKey('subjects-error'),
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                  child: InlineErrorMessage(
                    message: UserFacingError.display(e),
                    onRetry: () => ref.invalidate(phaseSubjectsProvider),
                  ),
                ),
              ),
            ),
            const HomeResumeBanner(),
            const ComicSectionTitle(title: 'Saved'),
            const HomeQuickActions(),
          ],
        ),
      ),
    );
  }
}
