import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
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
                Text('Chapter', style: Theme.of(context).textTheme.titleSmall),
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
    );
  }
}
