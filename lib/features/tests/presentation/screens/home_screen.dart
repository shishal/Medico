import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/user_facing_error.dart';
import '../../../../core/widgets/async_status_views.dart';
import '../../../../core/widgets/comic_section_title.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import '../../../catalog/presentation/widgets/subject_tile.dart';
import '../../../catalog/presentation/widgets/year_picker.dart';
import '../../../progress/presentation/providers/ug_home_providers.dart';
import '../providers/pending_submit_sync_provider.dart';
import '../widgets/home_hero_banner.dart';
import '../widgets/home_quick_actions.dart';
import '../widgets/home_resume_banner.dart';
import '../widgets/home_week_strip.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phases = ref.watch(mbbsPhasesProvider);
    final subjects = ref.watch(phaseSubjectsProvider);
    final selectedYearId = ref.watch(activePhaseIdProvider);
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
            const HomeWeekStrip(),
            const HomeResumeBanner(),
            const ComicSectionTitle(
              title: 'Your year',
              subtitle: 'Subjects below follow this year',
            ),
            phases.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: Spacing.lg),
                    child: Text('No MBBS years in the catalog yet.'),
                  );
                }
                return YearPickerRow(
                  phases: items,
                  selectedId: selectedYearId,
                  onSelect: (id) =>
                      ref.read(catalogBrowsePhaseProvider.notifier).select(id),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(Spacing.lg),
                child: LinearProgressIndicator(),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                child: InlineErrorMessage(
                  message: UserFacingError.display(e),
                  onRetry: () => ref.invalidate(mbbsPhasesProvider),
                ),
              ),
            ),
            const ComicSectionTitle(
              title: 'Subjects',
              subtitle: 'Rings are lessons marked learnt',
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
            const ComicSectionTitle(title: 'Saved'),
            const HomeQuickActions(),
          ],
        ),
      ),
    );
  }
}
