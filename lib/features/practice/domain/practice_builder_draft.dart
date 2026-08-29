import 'dart:math' as math;

import 'plan_limits.dart';
import 'practice_catalog.dart';
import 'practice_enums.dart';

/// Form state for the Practice Builder.
///
/// Immutable so 4B.4 can pass a pre-filled copy via the route later.
/// [clampedTo] re-applies the current plan's limits — never trust stored
/// filters blindly if the user's plan changed.
class PracticeBuilderDraft {
  const PracticeBuilderDraft({
    this.selectedSubjectIds = const {},
    this.selectedTopicIds = const {},
    this.selectedTagIds = const {},
    this.selectedDifficulties = const {},
    this.sourceFilter = QuestionSourceFilter.unattempted,
    this.questionCount = 10,
    this.feedbackTiming = FeedbackTiming.immediate,
    this.explanationLevel = ExplanationLevel.answerOnly,
    this.timerEnabled = true,
    this.timerMinutes = 10,
    this.negativeMarking = false,
  });

  /// Empty set = all subjects. [Set] so toggling a chip is O(1) contains-check.
  final Set<String> selectedSubjectIds;
  final Set<String> selectedTopicIds;
  final Set<String> selectedTagIds;
  final Set<QuestionDifficulty> selectedDifficulties;
  final QuestionSourceFilter sourceFilter;
  final int questionCount;
  final FeedbackTiming feedbackTiming;
  final ExplanationLevel explanationLevel;
  final bool timerEnabled;
  final int timerMinutes;
  final bool negativeMarking;

  /// Topic IDs to send to the RPC. Null means "no topic filter" (all).
  ///
  /// If the student picked subjects but no topics, send every topic under
  /// those subjects so Medicine-only doesn't accidentally become "all".
  List<String>? resolvedTopicIds(PracticeCatalog catalog) {
    if (selectedTopicIds.isNotEmpty) return selectedTopicIds.toList();
    if (selectedSubjectIds.isEmpty) return null;
    final ids = catalog
        .topicsForSubjects(selectedSubjectIds)
        .map((t) => t.id)
        .toList();
    return ids.isEmpty ? null : ids;
  }

  List<String>? get resolvedTagIds =>
      selectedTagIds.isEmpty ? null : selectedTagIds.toList();

  List<QuestionDifficulty>? get resolvedDifficulties =>
      selectedDifficulties.isEmpty ? null : selectedDifficulties.toList();

  /// Minutes to send: null turns the timer off on the server.
  int? get resolvedTimerMinutes => timerEnabled ? math.max(timerMinutes, 1) : null;

  PracticeBuilderDraft toggleSubject(String id, PracticeCatalog catalog) {
    final next = {...selectedSubjectIds};
    if (next.contains(id)) {
      next.remove(id);
      final drop = catalog.topics
          .where((t) => t.subjectId == id)
          .map((t) => t.id)
          .toSet();
      return copyWith(
        selectedSubjectIds: next,
        selectedTopicIds: selectedTopicIds.difference(drop),
      );
    }
    next.add(id);
    return copyWith(selectedSubjectIds: next);
  }

  PracticeBuilderDraft toggleTopic(String id) =>
      copyWith(selectedTopicIds: _toggle(selectedTopicIds, id));

  PracticeBuilderDraft toggleTag(String id) =>
      copyWith(selectedTagIds: _toggle(selectedTagIds, id));

  PracticeBuilderDraft toggleDifficulty(QuestionDifficulty difficulty) =>
      copyWith(
        selectedDifficulties: _toggle(selectedDifficulties, difficulty),
      );

  PracticeBuilderDraft withQuestionCount(int count) {
    var minutes = timerMinutes;
    if (minutes == questionCount) minutes = count;
    return copyWith(questionCount: count, timerMinutes: minutes);
  }

  /// `{...set}` copies then add/remove so the draft stays immutable.
  static Set<T> _toggle<T>(Set<T> current, T value) {
    final next = {...current};
    if (!next.add(value)) next.remove(value);
    return next;
  }

  /// Drop illegal selections and cap the count to what this plan allows.
  PracticeBuilderDraft clampedTo(PracticePlanContext ctx) {
    final maxQ = ctx.maxSelectableQuestions;
    var count = questionCount;
    if (maxQ <= 0) {
      count = 1;
    } else {
      count = count.clamp(1, maxQ);
    }

    var minutes = timerMinutes < 1 ? 1 : timerMinutes;
    // Keep the 1-min-per-question default in sync until the student edits it.
    if (minutes == questionCount) minutes = count;

    final explanation = ctx.limits.allowFullExplanation
        ? explanationLevel
        : (explanationLevel == ExplanationLevel.full
            ? ExplanationLevel.answerOnly
            : explanationLevel);

    return copyWith(
      selectedTagIds: ctx.limits.allowTagFilter ? selectedTagIds : const {},
      selectedDifficulties:
          ctx.limits.allowDifficultyFilter ? selectedDifficulties : const {},
      questionCount: count,
      explanationLevel: explanation,
      timerEnabled: ctx.limits.allowTimerToggle ? timerEnabled : true,
      timerMinutes: minutes,
      negativeMarking:
          ctx.limits.allowNegativeMarkingToggle ? negativeMarking : false,
    );
  }

  PracticeBuilderDraft copyWith({
    Set<String>? selectedSubjectIds,
    Set<String>? selectedTopicIds,
    Set<String>? selectedTagIds,
    Set<QuestionDifficulty>? selectedDifficulties,
    QuestionSourceFilter? sourceFilter,
    int? questionCount,
    FeedbackTiming? feedbackTiming,
    ExplanationLevel? explanationLevel,
    bool? timerEnabled,
    int? timerMinutes,
    bool? negativeMarking,
  }) {
    return PracticeBuilderDraft(
      selectedSubjectIds: selectedSubjectIds ?? this.selectedSubjectIds,
      selectedTopicIds: selectedTopicIds ?? this.selectedTopicIds,
      selectedTagIds: selectedTagIds ?? this.selectedTagIds,
      selectedDifficulties: selectedDifficulties ?? this.selectedDifficulties,
      sourceFilter: sourceFilter ?? this.sourceFilter,
      questionCount: questionCount ?? this.questionCount,
      feedbackTiming: feedbackTiming ?? this.feedbackTiming,
      explanationLevel: explanationLevel ?? this.explanationLevel,
      timerEnabled: timerEnabled ?? this.timerEnabled,
      timerMinutes: timerMinutes ?? this.timerMinutes,
      negativeMarking: negativeMarking ?? this.negativeMarking,
    );
  }
}
