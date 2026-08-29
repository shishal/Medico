import '../../../core/supabase/tables.dart';
import 'local_attempt_snapshot.dart';
import 'player_session_state.dart';
import 'question_answer.dart';

/// One answer row sent to `submit_attempt`. No score fields — scoring is SQL.
class AttemptAnswerWrite {
  const AttemptAnswerWrite({
    required this.questionId,
    this.selectedOption,
    this.isMarkedForReview = false,
    this.timeSpentSeconds = 0,
  });

  final String questionId;
  final String? selectedOption;
  final bool isMarkedForReview;
  final int timeSpentSeconds;

  factory AttemptAnswerWrite.fromAnswer({
    required String questionId,
    required QuestionAnswer answer,
  }) {
    return AttemptAnswerWrite(
      questionId: questionId,
      selectedOption: answer.selectedOption?.dbValue,
      isMarkedForReview: answer.markedForReview,
      timeSpentSeconds: answer.timeSpentSeconds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AttemptAnswerColumns.questionId: questionId,
      AttemptAnswerColumns.selectedOption: selectedOption,
      AttemptAnswerColumns.isMarkedForReview: isMarkedForReview,
      AttemptAnswerColumns.timeSpentSeconds: timeSpentSeconds,
    };
  }
}

/// RPC payload for [RpcFunctions.submitAttempt].
///
/// Built from local answers only. Must never include total_score or counts.
class AttemptSubmitRequest {
  const AttemptSubmitRequest({required this.attemptId, required this.answers});

  final String attemptId;
  final List<AttemptAnswerWrite> answers;

  factory AttemptSubmitRequest.fromSession(PlayerSessionState session) {
    return AttemptSubmitRequest(
      attemptId: session.attemptId,
      answers: [
        for (final question in session.questions)
          AttemptAnswerWrite.fromAnswer(
            questionId: question.id,
            answer: session.answerFor(question),
          ),
      ],
    );
  }

  factory AttemptSubmitRequest.fromSnapshot(LocalAttemptSnapshot snapshot) {
    return AttemptSubmitRequest.fromSession(
      PlayerSessionState.fromSnapshot(snapshot),
    );
  }

  /// Named params for `supabase.rpc`. Keys must match [SubmitAttemptParams].
  Map<String, dynamic> toRpcParams() {
    return {
      SubmitAttemptParams.attemptId: attemptId,
      SubmitAttemptParams.answers: [
        for (final answer in answers) answer.toJson(),
      ],
    };
  }
}

/// Failures the client should not keep retrying (file can be dropped).
bool isTerminalSubmitFailure(String message) {
  return message == 'Not signed in.' ||
      message == 'This attempt can no longer be submitted.';
}
