import 'package:flutter_test/flutter_test.dart';

import 'package:medico/features/practice/domain/created_practice_session.dart';
import 'package:medico/features/practice/domain/plan_limits.dart';
import 'package:medico/features/practice/domain/practice_builder_draft.dart';
import 'package:medico/features/practice/domain/practice_catalog.dart';
import 'package:medico/features/practice/domain/practice_clamp_copy.dart';
import 'package:medico/features/practice/domain/practice_enums.dart';
import 'package:medico/features/profile/domain/plan_tier.dart';

void main() {
  const freeLimits = PlanLimits(
    plan: PlanTier.free,
    maxPracticeSessionQuestions: 10,
    dailyPracticeQuestionQuota: 20,
    allowFullExplanation: false,
    allowTimerToggle: false,
    allowTagFilter: false,
    allowDifficultyFilter: true,
    allowNegativeMarkingToggle: false,
  );

  const proLimits = PlanLimits(
    plan: PlanTier.pro,
    maxPracticeSessionQuestions: 50,
    dailyPracticeQuestionQuota: null,
    allowFullExplanation: true,
    allowTimerToggle: true,
    allowTagFilter: true,
    allowDifficultyFilter: true,
    allowNegativeMarkingToggle: true,
  );

  group('PracticeBuilderDraft.clampedTo', () {
    test('caps question count and forces locked fields for free', () {
      const draft = PracticeBuilderDraft(
        selectedTagIds: {'tag-1'},
        questionCount: 80,
        explanationLevel: ExplanationLevel.full,
        timerEnabled: false,
        negativeMarking: true,
      );

      final clamped = draft.clampedTo(
        const PracticePlanContext(limits: freeLimits, questionsUsedToday: 0),
      );

      expect(clamped.questionCount, 10);
      expect(clamped.selectedTagIds, isEmpty);
      expect(clamped.explanationLevel, ExplanationLevel.answerOnly);
      expect(clamped.timerEnabled, isTrue);
      expect(clamped.negativeMarking, isFalse);
    });

    test('caps to remaining daily quota when lower than session max', () {
      const draft = PracticeBuilderDraft(questionCount: 10);

      final clamped = draft.clampedTo(
        const PracticePlanContext(limits: freeLimits, questionsUsedToday: 16),
      );

      expect(clamped.questionCount, 4);
    });

    test('leaves pro selections intact', () {
      const draft = PracticeBuilderDraft(
        selectedTagIds: {'tag-1'},
        questionCount: 40,
        explanationLevel: ExplanationLevel.full,
        timerEnabled: false,
        negativeMarking: true,
      );

      final clamped = draft.clampedTo(
        const PracticePlanContext(limits: proLimits, questionsUsedToday: 0),
      );

      expect(clamped.questionCount, 40);
      expect(clamped.selectedTagIds, {'tag-1'});
      expect(clamped.explanationLevel, ExplanationLevel.full);
      expect(clamped.timerEnabled, isFalse);
      expect(clamped.negativeMarking, isTrue);
    });
  });

  group('PracticeBuilderDraft.resolvedTopicIds', () {
    const catalog = PracticeCatalog(
      subjects: [
        Subject(id: 'med', name: 'Medicine', displayOrder: 0),
        Subject(id: 'surg', name: 'Surgery', displayOrder: 1),
      ],
      topics: [
        Topic(id: 'card', subjectId: 'med', name: 'Cardio', displayOrder: 0),
        Topic(id: 'gi', subjectId: 'med', name: 'GI', displayOrder: 1),
        Topic(id: 'ortho', subjectId: 'surg', name: 'Ortho', displayOrder: 0),
      ],
      tags: [],
    );

    test('null when nothing selected (all topics)', () {
      const draft = PracticeBuilderDraft();
      expect(draft.resolvedTopicIds(catalog), isNull);
    });

    test('explicit topics win', () {
      const draft = PracticeBuilderDraft(selectedTopicIds: {'card'});
      expect(draft.resolvedTopicIds(catalog), ['card']);
    });

    test('subject-only selection expands to that subject\'s topics', () {
      const draft = PracticeBuilderDraft(selectedSubjectIds: {'med'});
      expect(draft.resolvedTopicIds(catalog), ['card', 'gi']);
    });
  });

  group('PracticeClampCopy', () {
    test('explains a plan-limit clamp', () {
      const requested = PracticeBuilderDraft(questionCount: 999);
      const actual = CreatedPracticeSession(
        testId: 't',
        totalQuestions: 10,
        explanationLevel: ExplanationLevel.answerOnly,
        timerEnabled: true,
        totalDurationMinutes: 10,
      );

      expect(
        PracticeClampCopy.toast(
          requested: requested,
          actual: actual,
          maxSessionQuestions: 10,
        ),
        "Showing 10 questions — your plan's practice limit",
      );
    });

    test('explains a full-explanation downgrade', () {
      const requested = PracticeBuilderDraft(
        questionCount: 10,
        explanationLevel: ExplanationLevel.full,
      );
      const actual = CreatedPracticeSession(
        testId: 't',
        totalQuestions: 10,
        explanationLevel: ExplanationLevel.answerOnly,
        timerEnabled: true,
        totalDurationMinutes: 10,
      );

      expect(
        PracticeClampCopy.toast(
          requested: requested,
          actual: actual,
          maxSessionQuestions: 10,
        ),
        "Full explanations aren't on your plan — showing the correct answer only",
      );
    });

    test('silent when the server honored the request', () {
      const requested = PracticeBuilderDraft(questionCount: 10);
      const actual = CreatedPracticeSession(
        testId: 't',
        totalQuestions: 10,
        explanationLevel: ExplanationLevel.answerOnly,
        timerEnabled: true,
        totalDurationMinutes: 10,
      );

      expect(
        PracticeClampCopy.toast(
          requested: requested,
          actual: actual,
          maxSessionQuestions: 10,
        ),
        isNull,
      );
    });
  });

  group('PracticePlanContext', () {
    test('maxSelectableQuestions uses remaining quota', () {
      const ctx = PracticePlanContext(
        limits: freeLimits,
        questionsUsedToday: 15,
      );
      expect(ctx.remainingToday, 5);
      expect(ctx.maxSelectableQuestions, 5);
      expect(ctx.dailyQuotaExhausted, isFalse);
    });

    test('unlimited quota when daily cap is null', () {
      const ctx = PracticePlanContext(
        limits: proLimits,
        questionsUsedToday: 99,
      );
      expect(ctx.remainingToday, isNull);
      expect(ctx.maxSelectableQuestions, 50);
      expect(ctx.dailyQuotaExhausted, isFalse);
    });
  });
}
