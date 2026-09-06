import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/user_facing_error.dart';
import '../../../../core/widgets/async_status_views.dart';
import '../../domain/question_format.dart';
import '../../domain/subject_pyq_filters.dart';
import '../providers/pyq_providers.dart';
import '../widgets/pyq_teaser_card.dart';

/// Subject → PYQs. Paper / year / chapter chips group a mixed exam paper.
class SubjectPyqScreen extends ConsumerStatefulWidget {
  const SubjectPyqScreen({
    super.key,
    required this.subjectId,
    required this.title,
  });

  final String subjectId;
  final String title;

  @override
  ConsumerState<SubjectPyqScreen> createState() => _SubjectPyqScreenState();
}

class _SubjectPyqScreenState extends ConsumerState<SubjectPyqScreen> {
  QuestionFormat? _format;
  String? _paperName;
  int? _year;
  String? _topicId;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(subjectPyqsProvider(widget.subjectId));
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          TextButton(
            onPressed: () => context.push(
              AppRoutes.subjectTopicsPath(widget.subjectId, widget.title),
            ),
            child: const Text('Chapters'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const AsyncLoadingView(),
        error: (e, _) => AsyncErrorView(
          message: UserFacingError.display(e),
          onAction: () =>
              ref.invalidate(subjectPyqsProvider(widget.subjectId)),
        ),
        data: (feed) {
          final items = filterSubjectPyqs(
            teasers: feed.teasers,
            format: _format,
            paperName: _paperName,
            year: _year,
            topicId: _topicId,
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
                'A university paper mixes chapters. Filter by paper, year, or chapter — chapters are also used on Trackers.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (feed.usingFallback) ...[
                const SizedBox(height: Spacing.sm),
                Text(
                  'Showing default PYQs until your university papers are added.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: Spacing.md),
              PyqFormatChips(
                selected: _format,
                onSelected: (value) => setState(() => _format = value),
              ),
              if (feed.paperNames.isNotEmpty) ...[
                const SizedBox(height: Spacing.sm),
                _StringChips(
                  allLabel: 'All papers',
                  values: feed.paperNames,
                  selected: _paperName,
                  onSelected: (value) => setState(() => _paperName = value),
                ),
              ],
              if (feed.years.isNotEmpty) ...[
                const SizedBox(height: Spacing.sm),
                _StringChips(
                  allLabel: 'All years',
                  values: [for (final y in feed.years) '$y'],
                  selected: _year?.toString(),
                  onSelected: (value) => setState(
                    () => _year = value == null ? null : int.tryParse(value),
                  ),
                ),
              ],
              if (feed.chapters.isNotEmpty) ...[
                const SizedBox(height: Spacing.sm),
                Wrap(
                  spacing: Spacing.sm,
                  runSpacing: Spacing.sm,
                  children: [
                    FilterChip(
                      label: const Text('All chapters'),
                      selected: _topicId == null,
                      onSelected: (_) => setState(() => _topicId = null),
                    ),
                    for (final chapter in feed.chapters)
                      FilterChip(
                        label: Text(chapter.name),
                        selected: _topicId == chapter.id,
                        onSelected: (_) =>
                            setState(() => _topicId = chapter.id),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: Spacing.md),
              if (items.isEmpty)
                const Text('No PYQs match these filters.')
              else
                for (var i = 0; i < items.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.sm),
                    child: PyqTeaserCard(
                      teaser: items[i],
                      index: i,
                      onTap: () =>
                          context.push(AppRoutes.pyqPath(items[i].id)),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _StringChips extends StatelessWidget {
  const _StringChips({
    required this.allLabel,
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  final String allLabel;
  final List<String> values;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      children: [
        FilterChip(
          label: Text(allLabel),
          selected: selected == null,
          onSelected: (_) => onSelected(null),
        ),
        for (final value in values)
          FilterChip(
            label: Text(value),
            selected: selected == value,
            onSelected: (_) => onSelected(value),
          ),
      ],
    );
  }
}
