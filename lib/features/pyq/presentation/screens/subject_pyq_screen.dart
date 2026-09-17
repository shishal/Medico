import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/user_facing_error.dart';
import '../../../../core/widgets/async_status_views.dart';
import '../../../../core/widgets/comic_card.dart';
import '../../domain/subject_pyq_filters.dart';
import '../../../practice/domain/practice_enums.dart';
import '../providers/pyq_providers.dart';
import '../widgets/subject_pyq_filter_sheet.dart';

/// Subject → exam years. Filters (chapter / paper) carry into the year outline.
class SubjectPyqScreen extends ConsumerWidget {
  const SubjectPyqScreen({
    super.key,
    required this.subjectId,
    required this.title,
  });

  final String subjectId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(subjectPyqsProvider(subjectId));
    final filter = ref.watch(subjectPyqFiltersProvider(subjectId));
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton.icon(
            onPressed: () => async.whenOrNull(
              data: (feed) => showSubjectPyqFilterSheet(
                context: context,
                subjectId: subjectId,
                paperNames: feed.paperNames,
                chapters: feed.chapters,
              ),
            ),
            icon: Icon(
              filter.isActive
                  ? Icons.filter_alt_rounded
                  : Icons.filter_alt_outlined,
            ),
            label: const Text('Filters'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const AsyncLoadingView(),
        error: (e, _) => AsyncErrorView(
          message: UserFacingError.display(e),
          onAction: () => ref.invalidate(subjectPyqsProvider(subjectId)),
        ),
        data: (feed) {
          final years = yearSummariesWithMatchingPyqs(
            teasers: feed.teasers,
            paperName: filter.paperName,
            topicId: filter.topicId,
            priorities: filter.priorities,
          );
          final activeSummary = filter.isActive
              ? [
                  if (filter.paperName != null) filter.paperName!,
                  if (filter.topicId != null)
                    feed.chapters
                        .where((c) => c.id == filter.topicId)
                        .map((c) => c.name)
                        .firstOrNull,
                  if (filter.priorities.isNotEmpty)
                    QuestionPriority.values
                        .where(filter.priorities.contains)
                        .map((p) => p.label)
                        .join(', '),
                ].whereType<String>().join(' · ')
              : null;

          if (years.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(subjectPyqsProvider(subjectId)),
              child: ListView(
                // A scrollable is required for pull-to-refresh to have
                // somewhere to hang, even when the list itself is empty.
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.6,
                    child: filter.isActive
                        ? AsyncEmptyView(
                            icon: Icons.filter_alt_off_outlined,
                            message: 'No years match these filters.',
                            actionLabel: 'Clear filters',
                            onAction: ref
                                .read(
                                  subjectPyqFiltersProvider(subjectId).notifier,
                                )
                                .clear,
                          )
                        : AsyncEmptyView(
                            icon: Icons.history_edu_outlined,
                            message:
                                'No previous year papers for $title yet.\n'
                                'They arrive as your university is tagged.',
                          ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(subjectPyqsProvider(subjectId)),
            child: ListView(
              padding: const EdgeInsets.all(Spacing.md),
              children: [
                Text(
                  'Previous year questions',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  'Pick a year to see that sitting. A university paper mixes chapters.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (activeSummary != null && activeSummary.isNotEmpty) ...[
                  const SizedBox(height: Spacing.sm),
                  Text(
                    activeSummary,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
                const SizedBox(height: Spacing.md),
                for (final year in years)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.sm),
                    child: _YearCard(
                      summary: year,
                      onTap: () => context.push(
                        AppRoutes.subjectYearPath(subjectId, year.year, title),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A year row that says what opening it leads to, rather than just the number.
class _YearCard extends StatelessWidget {
  const _YearCard({required this.summary, required this.onTap});

  final SubjectYearSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final count = summary.questionCount;
    final caption = [
      count == 1 ? '1 question' : '$count questions',
      if (summary.paperNames.isNotEmpty) summary.paperNames.join(' · '),
    ].join(' · ');

    return ComicCard(
      onTap: onTap,
      semanticLabel: '${summary.year}, $caption',
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${summary.year}',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: muted),
        ],
      ),
    );
  }
}
