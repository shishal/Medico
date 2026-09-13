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
          TextButton(
            onPressed: () => async.whenOrNull(
              data: (feed) => showSubjectPyqFilterSheet(
                context: context,
                subjectId: subjectId,
                paperNames: feed.paperNames,
                chapters: feed.chapters,
              ),
            ),
            child: Text(filter.isActive ? 'Filters · on' : 'Filters'),
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
          final years = yearsWithMatchingPyqs(
            teasers: feed.teasers,
            paperName: filter.paperName,
            topicId: filter.topicId,
            priorities: filter.priorities,
          );
          return ListView(
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
              if (filter.isActive) ...[
                const SizedBox(height: Spacing.sm),
                Text(
                  [
                    if (filter.paperName != null) filter.paperName!,
                    if (filter.topicId != null)
                      feed.chapters
                          .where((c) => c.id == filter.topicId)
                          .map((c) => c.name)
                          .firstOrNull,
                    if (filter.priorities.isNotEmpty)
                      QuestionDifficulty.filterOrder
                          .where(filter.priorities.contains)
                          .map((p) => p.label)
                          .join(', '),
                  ].whereType<String>().join(' · '),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
              const SizedBox(height: Spacing.md),
              if (years.isEmpty)
                Text(
                  filter.isActive
                      ? 'No years match these filters.'
                      : 'No previous year papers yet.',
                )
              else
                for (final year in years)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.sm),
                    child: ComicCard(
                      onTap: () => context.push(
                        AppRoutes.subjectYearPath(subjectId, year, title),
                      ),
                      child: Text(
                        '$year',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}
