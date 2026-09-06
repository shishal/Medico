import 'package:flutter/material.dart';

import '../../../../core/theme/comic_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/comic_card.dart';
import '../../../bookmarks/presentation/widgets/bookmark_icon_button.dart';
import '../../domain/pyq_models.dart';
import '../../domain/question_format.dart';

class PyqFormatChips extends StatelessWidget {
  const PyqFormatChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final QuestionFormat? selected;
  final ValueChanged<QuestionFormat?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      children: [
        _chip(context, null, 'All'),
        for (final format in QuestionFormat.values)
          _chip(context, format, format.label),
      ],
    );
  }

  Widget _chip(BuildContext context, QuestionFormat? value, String label) {
    final on = selected == value;
    return FilterChip(
      label: Text(label),
      selected: on,
      onSelected: (_) => onSelected(value),
    );
  }
}

class PyqTeaserCard extends StatelessWidget {
  const PyqTeaserCard({
    super.key,
    required this.teaser,
    required this.index,
    this.onTap,
  });

  final PyqTeaser teaser;
  final int index;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final comic = ComicColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final years = teaser.appearanceYears.map((y) => '$y').join(' · ');

    return ComicCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: Spacing.sm,
                  runSpacing: Spacing.xs,
                  children: [
                    Chip(
                      label: Text(teaser.format.label),
                      visualDensity: VisualDensity.compact,
                    ),
                    if (teaser.marks != null)
                      Chip(
                        label: Text('${teaser.marks} marks'),
                        visualDensity: VisualDensity.compact,
                      ),
                    if (teaser.isHighYield)
                      Chip(
                        label: const Text('High yield'),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: scheme.primary.withValues(alpha: 0.18),
                        labelStyle: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
              BookmarkIconButton(questionId: teaser.id),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            teaser.questionText,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (years.isNotEmpty || teaser.appearanceCount > 0) ...[
            const SizedBox(height: Spacing.sm),
            Text(
              [
                if (years.isNotEmpty) years,
                if (teaser.appearanceCount > 0)
                  '${teaser.appearanceCount}× in papers',
              ].join(' · '),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: comic.ink.withValues(alpha: 0.7),
              ),
            ),
          ],
          if (teaser.textbookLine != null) ...[
            const SizedBox(height: Spacing.sm),
            Text(
              teaser.textbookLine!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
