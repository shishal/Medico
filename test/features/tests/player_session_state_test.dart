import 'package:flutter_test/flutter_test.dart';

import 'package:medico/core/supabase/tables.dart';
import 'package:medico/features/practice/domain/practice_enums.dart';
import 'package:medico/features/tests/domain/palette_cell.dart';
import 'package:medico/features/tests/domain/player_question.dart';
import 'package:medico/features/tests/domain/player_session_state.dart';
import 'package:medico/features/tests/domain/question_option.dart';
import 'package:medico/features/tests/domain/test_player_bundle.dart';

PlayerQuestion _q({
  required String id,
  required QuestionOption correct,
  String text = 'Question text',
  String explanation = 'Because mitochondria produce ATP.',
}) {
  return PlayerQuestion(
    id: id,
    orderIndex: 0,
    sectionNumber: 1,
    questionText: text,
    optionA: 'Option A',
    optionB: 'Option B',
    optionC: 'Option C',
    optionD: 'Option D',
    correctOption: correct,
    explanationText: explanation,
  );
}

PlayerSessionState _session({
  required FeedbackTiming timing,
  ExplanationLevel level = ExplanationLevel.full,
}) {
  return PlayerSessionState.fromBundle(
    TestPlayerBundle(
      testId: 't1',
      title: 'Practice',
      feedbackTiming: timing,
      explanationLevel: level,
      isEphemeralPractice: true,
      questions: [
        _q(id: 'q1', correct: QuestionOption.a, text: 'Q1 stem'),
        _q(id: 'q2', correct: QuestionOption.b, text: 'Q2 stem'),
      ],
    ),
  );
}

void main() {
  group('PlayerQuestion.fromJoinJson', () {
    test('reads the nested questions embed', () {
      final question = PlayerQuestion.fromJoinJson({
        TestQuestionColumns.orderIndex: 2,
        TestQuestionColumns.sectionNumber: 1,
        TestQuestionColumns.questionEmbed: {
          QuestionColumns.id: 'qid',
          QuestionColumns.questionText: 'Stem',
          QuestionColumns.optionA: 'A text',
          QuestionColumns.optionB: 'B text',
          QuestionColumns.optionC: 'C text',
          QuestionColumns.optionD: 'D text',
          QuestionColumns.correctOption: 'B',
          QuestionColumns.explanationText: 'Why B',
        },
      });

      expect(question.id, 'qid');
      expect(question.orderIndex, 2);
      expect(question.correctOption, QuestionOption.b);
      expect(question.textFor(QuestionOption.b), 'B text');
    });
  });

  group('Exam Mode (on_submit)', () {
    test('never reveals feedback after answering', () {
      var session = _session(timing: FeedbackTiming.onSubmit);
      session = session.selectOption(QuestionOption.a);

      expect(session.revealsFeedback, isFalse);
      expect(session.feedbackReveal, isNull);
      expect(session.visualFor(QuestionOption.a), OptionVisual.selected);
      expect(session.visualFor(QuestionOption.b), OptionVisual.idle);
    });

    test('palette uses answered, not correct/incorrect', () {
      var session = _session(timing: FeedbackTiming.onSubmit);
      session = session.selectOption(QuestionOption.a);

      expect(session.paletteAt(0).kind, PaletteKind.answered);
      expect(session.paletteAt(0).fill, PaletteFill.green);
    });

    test('allows changing and clearing the answer', () {
      var session = _session(timing: FeedbackTiming.onSubmit);
      session = session.selectOption(QuestionOption.a);
      session = session.selectOption(QuestionOption.c);
      expect(session.currentAnswer.selectedOption, QuestionOption.c);

      session = session.clearResponse();
      expect(session.currentAnswer.selectedOption, isNull);
      expect(session.paletteAt(0).kind, PaletteKind.notAnswered);
    });
  });

  group('Tutor Mode (immediate)', () {
    test('locks the option and cannot change it afterward', () {
      var session = _session(timing: FeedbackTiming.immediate);
      session = session.selectOption(QuestionOption.a);
      expect(session.isCurrentAnswerLocked, isTrue);

      session = session.selectOption(QuestionOption.b);
      expect(session.currentAnswer.selectedOption, QuestionOption.a);

      session = session.clearResponse();
      expect(session.currentAnswer.selectedOption, QuestionOption.a);
    });

    test('palette shows correct vs incorrect, not generic answered', () {
      var session = _session(timing: FeedbackTiming.immediate);
      session = session.selectOption(QuestionOption.a);
      expect(session.paletteAt(0).kind, PaletteKind.correct);
      expect(session.paletteAt(0).fill, PaletteFill.green);

      session = session.goTo(1).selectOption(QuestionOption.a);
      expect(session.paletteAt(1).kind, PaletteKind.incorrect);
      expect(session.paletteAt(1).fill, PaletteFill.red);
      expect(session.paletteAt(0).kind, PaletteKind.correct);
    });

    test('skipped (visited, never answered) is a red outline', () {
      final session = _session(timing: FeedbackTiming.immediate);
      expect(session.paletteAt(0).kind, PaletteKind.skipped);
      expect(session.paletteAt(0).fill, PaletteFill.none);
      expect(session.paletteAt(0).outline, PaletteOutline.red);
      expect(session.paletteAt(1).kind, PaletteKind.notVisited);
    });

    test('full explanation reveals text and highlights the correct option', () {
      var session = _session(
        timing: FeedbackTiming.immediate,
        level: ExplanationLevel.full,
      );
      session = session.selectOption(QuestionOption.b);

      final reveal = session.feedbackReveal!;
      expect(reveal.isCorrect, isFalse);
      expect(reveal.highlightCorrectOption, isTrue);
      expect(reveal.explanationText, 'Because mitochondria produce ATP.');
      expect(session.visualFor(QuestionOption.b), OptionVisual.chosenIncorrect);
      expect(session.visualFor(QuestionOption.a), OptionVisual.revealedCorrect);
    });

    test('answer_only highlights the key but hides explanation text', () {
      var session = _session(
        timing: FeedbackTiming.immediate,
        level: ExplanationLevel.answerOnly,
      );
      session = session.selectOption(QuestionOption.b);

      expect(session.feedbackReveal!.explanationText, isNull);
      expect(session.feedbackReveal!.highlightCorrectOption, isTrue);
    });

    test('none marks correct/incorrect without revealing the key', () {
      var session = _session(
        timing: FeedbackTiming.immediate,
        level: ExplanationLevel.none,
      );
      session = session.selectOption(QuestionOption.b);

      expect(session.feedbackReveal!.isCorrect, isFalse);
      expect(session.feedbackReveal!.highlightCorrectOption, isFalse);
      expect(session.feedbackReveal!.explanationText, isNull);
      expect(session.visualFor(QuestionOption.a), OptionVisual.idle);
      expect(session.visualFor(QuestionOption.b), OptionVisual.chosenIncorrect);
    });

    test('mark for review remains available after lock', () {
      var session = _session(timing: FeedbackTiming.immediate);
      session = session.selectOption(QuestionOption.a).toggleMark();

      expect(session.currentAnswer.selectedOption, QuestionOption.a);
      expect(session.currentAnswer.markedForReview, isTrue);
      expect(session.paletteAt(0).showReviewDot, isTrue);
      expect(session.paletteAt(0).kind, PaletteKind.correct);
    });
  });
}
