import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/comic_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/user_facing_error.dart';
import '../../../../core/widgets/async_status_views.dart';
import '../../../../core/widgets/comic_mascot.dart';
import '../../../../core/widgets/comic_paper_background.dart';
import '../../../../core/widgets/comic_section_title.dart';
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
    final brightness = Theme.of(context).brightness;
    ref.watch(pendingSubmitSyncProvider);

    return ComicPaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          title: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ComicColors.of(context).ink,
                    width: 2,
                  ),
                ),
                child: const MascotAvatar(size: 32),
              ),
              const SizedBox(width: Spacing.sm),
              const Text('Medico'),
            ],
          ),
          actions: [
            _BarChip(
              tooltip: 'Search',
              icon: Icons.search_rounded,
              onPressed: () => context.push(AppRoutes.search),
            ),
            _BarChip(
              tooltip: 'Profile',
              icon: Icons.person_outline_rounded,
              onPressed: () => context.go(AppRoutes.profile),
            ),
            const SizedBox(width: Spacing.sm),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.only(bottom: Spacing.xl),
          children: [
            const HomeHeroBanner(),
            const SizedBox(height: Spacing.md),
            const HomeResumeBanner(),
            ComicSectionTitle(
              text: 'Your year',
              highlight: StickerFills.yearFill(2, brightness),
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
            ComicSectionTitle(
              text: 'Subjects',
              highlight: brightness == Brightness.dark
                  ? StickerFills.subjectDark[4]
                  : StickerFills.butter,
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
            ComicSectionTitle(
              text: 'Shortcuts',
              highlight: StickerFills.yearFill(3, brightness),
            ),
            const HomeQuickActions(),
          ],
        ),
      ),
    );
  }
}

class _BarChip extends StatelessWidget {
  const _BarChip({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final comic = ComicColors.of(context);
    final radius = BorderRadius.circular(14);

    return Padding(
      padding: const EdgeInsets.only(right: Spacing.xs),
      child: Tooltip(
        message: tooltip,
        child: Container(
          decoration: BoxDecoration(
            color: comic.sticker,
            borderRadius: radius,
            border: Border.all(color: comic.ink, width: 2),
            boxShadow: [
              BoxShadow(
                color: comic.ink.withValues(alpha: 0.88),
                offset: const Offset(2, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: radius,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(icon, color: comic.ink),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
