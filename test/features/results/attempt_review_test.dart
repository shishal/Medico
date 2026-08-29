import 'package:flutter_test/flutter_test.dart';

import 'package:medico/core/supabase/tables.dart';
import 'package:medico/features/practice/domain/practice_enums.dart';
import 'package:medico/features/results/domain/attempt_review.dart';
import 'package:medico/features/tests/domain/player_question.dart';
import 'package:medico/features/tests/domain/player_session_state.dart';
import 'package:medico/features/tests/domain/question_option.dart';

const _explanation = 'Because mitochondria produce ATP.';

PlayerQuestion _question({
  String id = 'q1',
  QuestionOption correct = QuestionOption.a,
  String explanation = _explanation,
}) {
  return PlayerQuestion(
    id: id,
    orderIndex: 0,
    sectionNumber: 1,
    questionText: 'Which organelle produces ATP?',
    optionA: 'Mitochondria',
    optionB: 'Ribosome',
    optionC: 'Golgi',
    optionD: 'Nucleus',
    correctOption: correct,
    explanationText: explanation,
    explanationVideoUrl: 'https://example.com/video',
  );
}

ReviewItem _item({
  ExplanationLevel level = ExplanationLevel.full,
  QuestionOption? selected = QuestionOption.b,
  PlayerQuestion? question,
  bool locked = false,
}) {
  return ReviewItem(
    questionId: 'q1',
    questionNumber: 1,
    explanationLevel: level,
    selectedOption: selected,
    question: locked ? null : (question ?? _question()),
  );
}

void main() {
  group('reviewSlotFromJoinJson', () {
    test('parses a visible question embed', () {
      final slot = reviewSlotFromJoinJson({
        TestQuestionColumns.questionId: 'qid',
        TestQuestionColumns.orderIndex: 2,
        TestQuestionColumns.sectionNumber: 1,
        TestQuestionColumns.questionEmbed: {
          QuestionColumns.id: 'qid',
          QuestionColumns.questionText: 'Stem',
          QuestionColumns.optionA: 'A',
          QuestionColumns.optionB: 'B',
          QuestionColumns.optionC: 'C',
          QuestionColumns.optionD: 'D',
          QuestionColumns.correctOption: 'B',
          QuestionColumns.explanationText: 'Why B',
        },
      });

      expect(slot, isNotNull);
      expect(slot!.questionId, 'qid');
      expect(slot.orderIndex, 2);
      expect(slot.question!.correctOption, QuestionOption.b);
      expect(slot.question!.explanationText, 'Why B');
    });

    test('null embed is a plan-locked slot, not a crash', () {
      final slot = reviewSlotFromJoinJson({
        TestQuestionColumns.questionId: 'q-pro',
        TestQuestionColumns.orderIndex: 0,
        TestQuestionColumns.questionEmbed: null,
      });

      expect(slot, isNotNull);
      expect(slot!.questionId, 'q-pro');
      expect(slot.question, isNull);
    });
  });

  group('ReviewItem explanation levels', () {
    test('full shows explanation and highlights the correct option', () {
      final item = _item(level: ExplanationLevel.full);

      expect(item.visibleExplanation, _explanation);
      expect(item.visibleVideoUrl, 'https://example.com/video');
      expect(item.highlightCorrectOption, isTrue);
      expect(item.correctAnswerLabel, 'Correct answer: A');
      expect(item.visualFor(QuestionOption.b), OptionVisual.chosenIncorrect);
      expect(item.visualFor(QuestionOption.a), OptionVisual.revealedCorrect);
    });

    test('answer_only never exposes explanation text', () {
      final item = _item(level: ExplanationLevel.answerOnly);

      expect(item.visibleExplanation, isNull);
      expect(item.visibleVideoUrl, isNull);
      expect(item.highlightCorrectOption, isTrue);
      expect(item.correctAnswerLabel, 'Correct answer: A');
      expect(item.question!.explanationText, _explanation);
    });

    test('none marks correct/incorrect without revealing the key', () {
      final item = _item(level: ExplanationLevel.none);

      expect(item.statusLabel, 'Incorrect');
      expect(item.highlightCorrectOption, isFalse);
      expect(item.visibleExplanation, isNull);
      expect(item.correctAnswerLabel, isNull);
      expect(item.visualFor(QuestionOption.a), OptionVisual.idle);
      expect(item.visualFor(QuestionOption.b), OptionVisual.chosenIncorrect);
    });

    test('plan-locked item has no question content', () {
      final item = _item(locked: true);

      expect(item.isPlanLocked, isTrue);
      expect(item.statusLabel, 'Unavailable');
      expect(item.visibleExplanation, isNull);
      expect(item.correctAnswerLabel, isNull);
      expect(item.visualFor(QuestionOption.a), OptionVisual.idle);
    });
  });

  group('AttemptReview.merge', () {
    test('orders slots and maps answers, including locked rows', () {
      final review = AttemptReview.merge(
        attemptId: 'a1',
        testId: 't1',
        title: 'Mini Test',
        explanationLevel: ExplanationLevel.answerOnly,
        slots: [
          ReviewSlot(
            questionId: 'q2',
            orderIndex: 2,
            question: _question(id: 'q2'),
          ),
          const ReviewSlot(questionId: 'q-pro', orderIndex: 1),
        ],
        answers: {'q2': QuestionOption.a, 'q-pro': QuestionOption.c},
      );

      expect(review.items, hasLength(2));
      expect(review.items.first.questionId, 'q-pro');
      expect(review.items.first.isPlanLocked, isTrue);
      expect(review.items.first.selectedOption, QuestionOption.c);
      expect(review.items.last.questionId, 'q2');
      expect(review.items.last.visibleExplanation, isNull);
    });
  });
}
