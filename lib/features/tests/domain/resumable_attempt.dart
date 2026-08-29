import 'attempt.dart';
import 'local_attempt_snapshot.dart';

/// Enough metadata to offer a "resume" path without opening the player.
class ResumableAttempt {
  const ResumableAttempt({
    required this.attemptId,
    required this.testId,
    required this.title,
    required this.startedAt,
    required this.isEphemeralPractice,
  });

  final String attemptId;
  final String testId;
  final String title;
  final DateTime startedAt;
  final bool isEphemeralPractice;

  factory ResumableAttempt.fromSnapshot(LocalAttemptSnapshot snapshot) {
    return ResumableAttempt(
      attemptId: snapshot.attemptId,
      testId: snapshot.testId,
      title: snapshot.title,
      startedAt: snapshot.startedAt,
      isEphemeralPractice: snapshot.isEphemeralPractice,
    );
  }

  factory ResumableAttempt.fromAttempt(Attempt attempt) {
    return ResumableAttempt(
      attemptId: attempt.id,
      testId: attempt.testId,
      title: attempt.title,
      startedAt: attempt.startedAt,
      isEphemeralPractice: attempt.isEphemeralPractice,
    );
  }
}
