import 'package:flutter/material.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/comic_card.dart';
import '../../domain/plan_limits.dart';
import '../../domain/practice_builder_draft.dart';
import '../../domain/practice_catalog.dart';
import '../../domain/practice_enums.dart';

/// The Practice Builder fields from spec §1. Each locked control stays visible
/// with an upgrade hint — never silently greyed out or hidden.
class PracticeBuilderForm extends StatelessWidget {
  const PracticeBuilderForm({
    super.key,
    required this.draft,
    required this.catalog,
    required this.planContext,
    required this.onChanged,
    required this.onUpgrade,
  });

  final PracticeBuilderDraft draft;
  final PracticeCatalog catalog;
  final PracticePlanContext planContext;
  final ValueChanged<PracticeBuilderDraft> onChanged;
  final VoidCallback onUpgrade;

  PlanLimits get _limits => planContext.limits;

  @override
  Widget build(BuildContext context) {
    final topics = catalog.topicsForSubjects(draft.selectedSubjectIds);

    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: [
        _SourceFilterSection(
          selected: draft.sourceFilter,
          onSelected: (value) => onChanged(draft.copyWith(sourceFilter: value)),
        ),
        const SizedBox(height: Spacing.lg),
        _ChipSection(
          title: 'Subjects',
          helper: draft.selectedSubjectIds.isEmpty
              ? 'None chosen — all subjects'
              : null,
          children: [
            for (final subject in catalog.subjects)
              FilterChip(
                label: Text(subject.name),
                selected: draft.selectedSubjectIds.contains(subject.id),
                onSelected: (_) =>
                    onChanged(draft.toggleSubject(subject.id, catalog)),
              ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        _ChipSection(
          title: 'Topics',
          helper: draft.selectedTopicIds.isEmpty
              ? 'None chosen — all topics in the selected subjects'
              : null,
          children: [
            if (topics.isEmpty)
              Text(
                'No topics for the selected subjects yet.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else
              for (final topic in topics)
                FilterChip(
                  label: Text(topic.name),
                  selected: draft.selectedTopicIds.contains(topic.id),
                  onSelected: (_) => onChanged(draft.toggleTopic(topic.id)),
                ),
          ],
        ),
        const SizedBox(height: Spacing.lg),
        _ChipSection(
          title: 'Tags',
          locked: !_limits.allowTagFilter,
          upgradeHint: 'Upgrade to filter by tags',
          onUpgrade: onUpgrade,
          children: [
            for (final tag in catalog.tags)
              FilterChip(
                label: Text(tag.chipLabel),
                selected: draft.selectedTagIds.contains(tag.id),
                onSelected: _limits.allowTagFilter
                    ? (_) => onChanged(draft.toggleTag(tag.id))
                    : null,
              ),
          ],
        ),
        const SizedBox(height: Spacing.lg),
        _ChipSection(
          title: 'Difficulty',
          helper: draft.selectedDifficulties.isEmpty
              ? 'None chosen — all difficulties'
              : null,
          locked: !_limits.allowDifficultyFilter,
          upgradeHint: 'Upgrade to filter by difficulty',
          onUpgrade: onUpgrade,
          children: [
            for (final difficulty in QuestionDifficulty.values)
              FilterChip(
                label: Text(difficulty.label),
                selected: draft.selectedDifficulties.contains(difficulty),
                onSelected: _limits.allowDifficultyFilter
                    ? (_) => onChanged(draft.toggleDifficulty(difficulty))
                    : null,
              ),
          ],
        ),
        const SizedBox(height: Spacing.lg),
        _QuestionCountSection(
          count: draft.questionCount,
          planContext: planContext,
          onChanged: (count) => onChanged(draft.withQuestionCount(count)),
        ),
        const SizedBox(height: Spacing.lg),
        _FeedbackTimingSection(
          selected: draft.feedbackTiming,
          onSelected: (value) =>
              onChanged(draft.copyWith(feedbackTiming: value)),
        ),
        const SizedBox(height: Spacing.lg),
        _ExplanationLevelSection(
          selected: draft.explanationLevel,
          allowFull: _limits.allowFullExplanation,
          onSelected: (value) =>
              onChanged(draft.copyWith(explanationLevel: value)),
          onUpgrade: onUpgrade,
        ),
        const SizedBox(height: Spacing.lg),
        _TimerSection(
          enabled: draft.timerEnabled,
          minutes: draft.timerMinutes,
          canToggle: _limits.allowTimerToggle,
          onEnabledChanged: (value) =>
              onChanged(draft.copyWith(timerEnabled: value)),
          onMinutesChanged: (value) =>
              onChanged(draft.copyWith(timerMinutes: value)),
          onUpgrade: onUpgrade,
        ),
        const SizedBox(height: Spacing.lg),
        _NegativeMarkingSection(
          enabled: draft.negativeMarking,
          canToggle: _limits.allowNegativeMarkingToggle,
          onChanged: (value) =>
              onChanged(draft.copyWith(negativeMarking: value)),
          onUpgrade: onUpgrade,
        ),
        const SizedBox(height: Spacing.xl),
      ],
    );
  }
}

class _SourceFilterSection extends StatelessWidget {
  const _SourceFilterSection({
    required this.selected,
    required this.onSelected,
  });

  final QuestionSourceFilter selected;
  final ValueChanged<QuestionSourceFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final filters = QuestionSourceFilter.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Question source', style: textTheme.titleMedium),
        const SizedBox(height: Spacing.xs),
        Text(
          'The filter you will use most — start here.',
          style: textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        for (var i = 0; i < filters.length; i += 2) ...[
          if (i > 0) const SizedBox(height: Spacing.sm),
          Row(
            children: [
              Expanded(
                child: _SourceCard(
                  filter: filters[i],
                  selected: selected == filters[i],
                  onTap: () => onSelected(filters[i]),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: _SourceCard(
                  filter: filters[i + 1],
                  selected: selected == filters[i + 1],
                  onTap: () => onSelected(filters[i + 1]),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.filter,
    required this.selected,
    required this.onTap,
  });

  final QuestionSourceFilter filter;
  final bool selected;
  final VoidCallback onTap;

  IconData get _icon => switch (filter) {
    QuestionSourceFilter.unattempted => Icons.quiz_outlined,
    QuestionSourceFilter.incorrect => Icons.replay,
    QuestionSourceFilter.bookmarked => Icons.bookmark_outline,
    QuestionSourceFilter.all => Icons.library_books_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ComicCard(
      color: selected ? colorScheme.primaryContainer : null,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _icon,
            color: selected
                ? colorScheme.onPrimaryContainer
                : colorScheme.primary,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            filter.label,
            style: textTheme.titleSmall?.copyWith(
              color: selected ? colorScheme.onPrimaryContainer : null,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            filter.subtitle,
            style: textTheme.bodySmall?.copyWith(
              color: selected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipSection extends StatelessWidget {
  const _ChipSection({
    required this.title,
    required this.children,
    this.helper,
    this.locked = false,
    this.upgradeHint,
    this.onUpgrade,
  });

  final String title;
  final List<Widget> children;
  final String? helper;
  final bool locked;
  final String? upgradeHint;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ComicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: textTheme.titleMedium)),
              if (locked)
                Icon(
                  Icons.lock_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
          if (helper != null && !locked) ...[
            const SizedBox(height: Spacing.xs),
            Text(
              helper!,
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: Spacing.sm),
          Opacity(
            opacity: locked ? 0.55 : 1,
            child: Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: children,
            ),
          ),
          if (locked && upgradeHint != null)
            _UpgradeHint(message: upgradeHint!, onUpgrade: onUpgrade),
        ],
      ),
    );
  }
}

class _QuestionCountSection extends StatelessWidget {
  const _QuestionCountSection({
    required this.count,
    required this.planContext,
    required this.onChanged,
  });

  final int count;
  final PracticePlanContext planContext;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final maxQ = planContext.maxSelectableQuestions;
    final remaining = planContext.remainingToday;
    final quota = planContext.limits.dailyPracticeQuestionQuota;
    final sliderMax = maxQ < 1 ? 1 : maxQ;
    final value = count.clamp(1, sliderMax).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Question count', style: textTheme.titleMedium),
        const SizedBox(height: Spacing.xs),
        Text(
          'Your ${planContext.limits.plan.label} plan allows up to '
          '${planContext.limits.maxPracticeSessionQuestions} per session.',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        if (quota != null) ...[
          const SizedBox(height: Spacing.xs),
          Text(
            remaining == 0
                ? "You've used today's $quota practice questions."
                : '$quota per day · $remaining left today.',
            style: textTheme.bodySmall?.copyWith(
              color: remaining == 0 ? colorScheme.error : colorScheme.primary,
            ),
          ),
        ],
        const SizedBox(height: Spacing.sm),
        if (planContext.dailyQuotaExhausted)
          const SizedBox.shrink()
        else
          Slider(
            min: 1,
            max: sliderMax.toDouble(),
            divisions: sliderMax > 1 ? sliderMax - 1 : null,
            value: value,
            label: '${value.round()}',
            onChanged: (v) => onChanged(v.round()),
          ),
        Text(
          '$count ${count == 1 ? 'question' : 'questions'}',
          style: textTheme.titleSmall,
        ),
      ],
    );
  }
}

class _FeedbackTimingSection extends StatelessWidget {
  const _FeedbackTimingSection({
    required this.selected,
    required this.onSelected,
  });

  final FeedbackTiming selected;
  final ValueChanged<FeedbackTiming> onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Feedback timing', style: textTheme.titleMedium),
        const SizedBox(height: Spacing.sm),
        SegmentedButton<FeedbackTiming>(
          segments: [
            for (final timing in FeedbackTiming.values)
              ButtonSegment(value: timing, label: Text(timing.label)),
          ],
          selected: {selected},
          onSelectionChanged: (value) => onSelected(value.first),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          selected.subtitle,
          style: textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ExplanationLevelSection extends StatelessWidget {
  const _ExplanationLevelSection({
    required this.selected,
    required this.allowFull,
    required this.onSelected,
    required this.onUpgrade,
  });

  final ExplanationLevel selected;
  final bool allowFull;
  final ValueChanged<ExplanationLevel> onSelected;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Explanation level', style: textTheme.titleMedium),
            ),
            if (!allowFull)
              Icon(
                Icons.lock_outline,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          children: [
            for (final level in ExplanationLevel.values)
              ChoiceChip(
                label: Text(
                  level == ExplanationLevel.full && !allowFull
                      ? '${level.label} 🔒'
                      : level.label,
                ),
                selected: selected == level,
                onSelected: (!allowFull && level == ExplanationLevel.full)
                    ? null
                    : (_) => onSelected(level),
              ),
          ],
        ),
        if (!allowFull)
          _UpgradeHint(
            message: 'Upgrade to Pro for full explanations',
            onUpgrade: onUpgrade,
          ),
      ],
    );
  }
}

class _TimerSection extends StatelessWidget {
  const _TimerSection({
    required this.enabled,
    required this.minutes,
    required this.canToggle,
    required this.onEnabledChanged,
    required this.onMinutesChanged,
    required this.onUpgrade,
  });

  final bool enabled;
  final int minutes;
  final bool canToggle;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<int> onMinutesChanged;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Timer', style: textTheme.titleMedium)),
            if (!canToggle)
              Icon(
                Icons.lock_outline,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Timed session'),
          subtitle: Text(
            canToggle
                ? 'Turn off to practice without a countdown'
                : 'Timer stays on for your plan',
          ),
          value: enabled,
          onChanged: canToggle ? onEnabledChanged : null,
        ),
        if (!canToggle)
          _UpgradeHint(
            message: 'Upgrade to turn the timer off',
            onUpgrade: onUpgrade,
          ),
        if (enabled) ...[
          const SizedBox(height: Spacing.sm),
          Row(
            children: [
              Text('Duration', style: textTheme.bodyLarge),
              const Spacer(),
              IconButton(
                tooltip: 'Fewer minutes',
                onPressed: minutes > 1
                    ? () => onMinutesChanged(minutes - 1)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$minutes min', style: textTheme.titleSmall),
              IconButton(
                tooltip: 'More minutes',
                onPressed: minutes < 180
                    ? () => onMinutesChanged(minutes + 1)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _NegativeMarkingSection extends StatelessWidget {
  const _NegativeMarkingSection({
    required this.enabled,
    required this.canToggle,
    required this.onChanged,
    required this.onUpgrade,
  });

  final bool enabled;
  final bool canToggle;
  final ValueChanged<bool> onChanged;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Negative marking',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (!canToggle)
              Icon(
                Icons.lock_outline,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Use +4 / −1 marking'),
          subtitle: const Text('Off by default — practice is for learning'),
          value: enabled,
          onChanged: canToggle ? onChanged : null,
        ),
        if (!canToggle)
          _UpgradeHint(
            message: 'Upgrade to practice with exam-style negative marking',
            onUpgrade: onUpgrade,
          ),
      ],
    );
  }
}

class _UpgradeHint extends StatelessWidget {
  const _UpgradeHint({required this.message, this.onUpgrade});

  final String message;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: Spacing.xs),
      child: TextButton.icon(
        onPressed: onUpgrade,
        icon: Icon(Icons.lock_outline, size: 16, color: colorScheme.primary),
        label: Text(message),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}
