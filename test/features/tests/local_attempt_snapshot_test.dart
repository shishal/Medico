import 'package:flutter_test/flutter_test.dart';

import 'package:medico/features/practice/domain/practice_enums.dart';
import 'package:medico/features/tests/domain/attempt_status.dart';
import 'package:medico/features/tests/domain/local_attempt_snapshot.dart';
import 'package:medico/features/tests/domain/player_question.dart';
import 'package:medico/features/tests/domain/player_session_state.dart';
import 'package:medico/features/tests/domain/question_answer.dart';
import 'package:medico/features/tests/domain/question_option.dart';
import 'package:medico/features/tests/domain/test_player_bundle.dart';

PlayerQuestion _q(String id) {
  return PlayerQuestion(
    id: id,
    orderIndex: 0,
    sectionNumber: 1,
    questionText: 'Stem $id',
    optionA: 'A',
    optionB: 'B',
    optionC: 'C',
    optionD: 'D',
    correctOption: QuestionOption.a,
    explanationText: 'Why',
  );
}

void main() {
  final started = DateTime.utc(2026, 8, 29, 12);

  LocalAttemptSnapshot snapshot() {
    return LocalAttemptSnapshot(
      attemptId: 'att-1',
      testId: 't1',
      userId: 'user-1',
      title: 'Mini Test',
      startedAt: started,
      sectionStartedAt: {1: started},
      currentIndex: 1,
      localStatus: LocalAttemptStatus.inProgress,
      feedbackTiming: FeedbackTiming.onSubmit,
      explanationLevel: ExplanationLevel.full,
      isEphemeralPractice: false,
      totalDurationMinutes: 10,
      timerEnabled: true,
      answers: {
        'q1': const QuestionAnswer(
          visited: true,
          selectedOption: QuestionOption.b,
          markedForReview: true,
          timeSpentSeconds: 12,
        ),
      },
      questions: [_q('q1'), _q('q2')],
    );
  }

  test('snapshot JSON round-trips answers and questions', () {
    final restored = LocalAttemptSnapshot.fromJson(snapshot().toJson());

    expect(restored.attemptId, 'att-1');
    expect(restored.testId, 't1');
    expect(restored.currentIndex, 1);
    expect(restored.answers['q1']!.selectedOption, QuestionOption.b);
    expect(restored.answers['q1']!.markedForReview, isTrue);
    expect(restored.answers['q1']!.timeSpentSeconds, 12);
    expect(restored.questions.map((q) => q.id), ['q1', 'q2']);
    expect(restored.questions.first.explanationText, 'Why');
    expect(restored.sectionStartedAt[1], started);
    expect(restored.totalDurationMinutes, 10);
    expect(restored.timerEnabled, isTrue);
    expect(restored.isSectional, isFalse);
  });

  test('fromSnapshot restores the current index and visited flag', () {
    final session = PlayerSessionState.fromSnapshot(snapshot());

    expect(session.attemptId, 'att-1');
    expect(session.currentIndex, 1);
    expect(session.currentQuestion.id, 'q2');
    expect(session.currentAnswer.visited, isTrue);
    expect(
      session.answerFor(session.questions.first).selectedOption,
      QuestionOption.b,
    );
  });

  test('addTimeToCurrent accumulates seconds on the visible question', () {
    var session = PlayerSessionState.fromBundle(
      TestPlayerBundle(
        testId: 't1',
        title: 'Mini',
        feedbackTiming: FeedbackTiming.onSubmit,
        explanationLevel: ExplanationLevel.full,
        isEphemeralPractice: false,
        questions: [_q('q1'), _q('q2')],
      ),
      attemptId: 'att-1',
      startedAt: started,
    );

    session = session.selectOption(QuestionOption.c).addTimeToCurrent(7);
    expect(session.currentAnswer.timeSpentSeconds, 7);

    session = session.goTo(1);
    expect(session.answerFor(session.questions.first).timeSpentSeconds, 7);
    expect(session.currentAnswer.timeSpentSeconds, 0);
  });
}
