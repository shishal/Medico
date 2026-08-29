import 'package:flutter_test/flutter_test.dart';

import 'package:medico/core/supabase/tables.dart';
import 'package:medico/features/practice/domain/practice_enums.dart';
import 'package:medico/features/tests/domain/attempt_score.dart';
import 'package:medico/features/tests/domain/attempt_submit_request.dart';
import 'package:medico/features/tests/domain/player_question.dart';
import 'package:medico/features/tests/domain/player_session_state.dart';
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
  );
}

void main() {
  test('payload includes every question and never a score', () {
    var session = PlayerSessionState.fromBundle(
      TestPlayerBundle(
        testId: 't1',
        title: 'Mini',
        feedbackTiming: FeedbackTiming.onSubmit,
        explanationLevel: ExplanationLevel.full,
        isEphemeralPractice: false,
        questions: [_q('q1'), _q('q2'), _q('q3')],
      ),
      attemptId: 'att-1',
    );
    session = session.selectOption(QuestionOption.a);

    final request = AttemptSubmitRequest.fromSession(session);
    expect(request.attemptId, 'att-1');
    expect(request.answers, hasLength(3));

    final answered = request.answers.singleWhere((a) => a.questionId == 'q1');
    expect(answered.selectedOption, 'A');

    final skipped = request.answers.where((a) => a.questionId != 'q1');
    expect(skipped.every((a) => a.selectedOption == null), isTrue);

    final params = request.toRpcParams();
    expect(params.keys, {
      SubmitAttemptParams.attemptId,
      SubmitAttemptParams.answers,
    });
    expect(params.containsKey(AttemptColumns.totalScore), isFalse);
    expect(params.containsKey(AttemptColumns.correctCount), isFalse);

    final encoded = params.toString();
    expect(encoded.contains('total_score'), isFalse);
    expect(encoded.contains('percentile'), isFalse);
  });

  test('AttemptScore reads numeric values the API may send as ints', () {
    final score = AttemptScore.fromJson({
      AttemptColumns.id: 'att-1',
      AttemptColumns.testId: 't1',
      AttemptColumns.totalScore: 7,
      AttemptColumns.correctCount: 2,
      AttemptColumns.incorrectCount: 1,
      AttemptColumns.unattemptedCount: 1,
      AttemptColumns.percentile: 100,
      AttemptColumns.submittedAt: '2026-08-29T12:00:00.000Z',
    });

    expect(score.totalScore, 7);
    expect(score.correctCount, 2);
    expect(score.incorrectCount, 1);
    expect(score.unattemptedCount, 1);
    expect(score.percentile, 100);
  });

  test('terminal submit errors are not retried', () {
    expect(isTerminalSubmitFailure('Not signed in.'), isTrue);
    expect(
      isTerminalSubmitFailure('This attempt can no longer be submitted.'),
      isTrue,
    );
    expect(
      isTerminalSubmitFailure(
        'Could not submit. Check your connection and try again.',
      ),
      isFalse,
    );
  });
}
