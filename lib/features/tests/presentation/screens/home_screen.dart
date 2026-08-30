import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/brand_assets.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/user_facing_error.dart';
import '../../../../core/widgets/async_status_views.dart';
import '../../../../core/widgets/comic_mascot.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import '../../../catalog/presentation/widgets/subject_tile.dart';
import '../../../catalog/presentation/widgets/year_picker.dart';
import '../providers/pending_submit_sync_provider.dart';
import '../widgets/home_hero_banner.dart';
import '../widgets/home_quick_actions.dart';
import '../widgets/home_resume_banner.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phases = ref.watch(mbbsPhasesProvider);
    final subjects = ref.watch(phaseSubjectsProvider);
    final selectedYearId = ref.watch(activePhaseIdProvider);
    ref.watch(pendingSubmitSyncProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            MascotAvatar(size: 32),
            SizedBox(width: Spacing.sm),
            Text('Medico'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Search',
            onPressed: () => context.push(AppRoutes.search),
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            tooltip: 'Profile',
            onPressed: () => context.go(AppRoutes.profile),
            icon: const Icon(Icons.person_outline_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            right: -36,
            top: 12,
            child: IgnorePointer(
              child: Opacity(
                opacity: Theme.of(context).brightness == Brightness.dark
                    ? 0.08
                    : 0.16,
                child: Image.asset(
                  BrandAssets.doodleEquipment,
                  width: 240,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.only(bottom: Spacing.xl),
            children: [
              const HomeHeroBanner(),
              const SizedBox(height: Spacing.md),
              const HomeResumeBanner(),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  Spacing.md,
                  Spacing.lg,
                  Spacing.sm,
                ),
                child: Text(
                  'Your year',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
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
                    onSelect: (id) => ref
                        .read(catalogBrowsePhaseProvider.notifier)
                        .select(id),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  Spacing.lg,
                  Spacing.lg,
                  Spacing.sm,
                ),
                child: Text(
                  'Subjects',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.04, 0.06),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: subjects.when(
                  data: (items) => SubjectStickerGrid(
                    key: ValueKey(items.map((s) => s.id).join(',')),
                    subjects: items,
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
              const SizedBox(height: Spacing.lg),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  0,
                  Spacing.lg,
                  Spacing.sm,
                ),
                child: Text(
                  'Shortcuts',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const HomeQuickActions(),
            ],
          ),
        ],
      ),
    );
  }
}
