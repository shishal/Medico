import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../practice/domain/practice_enums.dart';
import '../../domain/pyq_models.dart';
import '../providers/pyq_providers.dart';

Future<void> showSubjectPyqFilterSheet({
  required BuildContext context,
  required String subjectId,
  required List<String> paperNames,
  required List<PyqChapter> chapters,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return SubjectPyqFilterSheet(
        subjectId: subjectId,
        paperNames: paperNames,
        chapters: chapters,
      );
    },
  );
}

class SubjectPyqFilterSheet extends ConsumerWidget {
  const SubjectPyqFilterSheet({
    super.key,
    required this.subjectId,
    required this.paperNames,
    required this.chapters,
  });

  final String subjectId;
  final List<String> paperNames;
  final List<PyqChapter> chapters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(subjectPyqFiltersProvider(subjectId));
    final notifier = ref.read(subjectPyqFiltersProvider(subjectId).notifier);
    final media = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.sm,
            Spacing.lg,
            Spacing.lg,
          ),
          // Scrollable because a subject like Anatomy has enough chapters to
          // push the chip wraps past the sheet height.
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Filters', style: Theme.of(context).textTheme.titleLarge),
                if (paperNames.isNotEmpty) ...[
                  const SizedBox(height: Spacing.md),
                  Text('Paper', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: Spacing.sm),
                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.sm,
                    children: [
                      FilterChip(
                        label: const Text('All papers'),
                        selected: filter.paperName == null,
                        onSelected: (_) => notifier.setPaperName(null),
                      ),
                      for (final name in paperNames)
                        FilterChip(
                          label: Text(name),
                          selected: filter.paperName == name,
                          onSelected: (_) => notifier.setPaperName(name),
                        ),
                    ],
                  ),
                ],
                if (chapters.isNotEmpty) ...[
                  const SizedBox(height: Spacing.md),
                  Text(
                    'Chapters',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: Spacing.sm),
                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.sm,
                    children: [
                      FilterChip(
                        label: const Text('All chapters'),
                        selected: filter.topicId == null,
                        onSelected: (_) => notifier.setTopicId(null),
                      ),
                      for (final chapter in chapters)
                        FilterChip(
                          label: Text(chapter.name),
                          selected: filter.topicId == chapter.id,
                          onSelected: (_) => notifier.setTopicId(chapter.id),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: Spacing.md),
                Text(
                  'Revision priority',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  filter.priorities.isEmpty
                      ? 'None chosen — all questions. Untagged questions count as Should.'
                      : 'Untagged questions count as Should.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                Wrap(
                  spacing: Spacing.sm,
                  runSpacing: Spacing.sm,
                  children: [
                    for (final priority in QuestionPriority.values)
                      FilterChip(
                        label: Text(priority.label),
                        selected: filter.priorities.contains(priority),
                        onSelected: (_) => notifier.togglePriority(priority),
                      ),
                  ],
                ),
                const SizedBox(height: Spacing.lg),
                Row(
                  children: [
                    TextButton(
                      onPressed: filter.isActive ? notifier.clear : null,
                      child: const Text('Clear all'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
