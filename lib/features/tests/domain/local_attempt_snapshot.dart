import '../../practice/domain/practice_enums.dart';
import 'attempt_status.dart';
import 'player_question.dart';
import 'question_answer.dart';

/// JSON keys for `attempt_<id>.json` — the spec's local autosave file.
abstract final class LocalAttemptKeys {
  static const attemptId = 'attempt_id';
  static const testId = 'test_id';
  static const userId = 'user_id';
  static const title = 'title';
  static const startedAt = 'started_at';
  static const sectionStartedAt = 'section_started_at';
  static const currentIndex = 'current_index';
  static const localStatus = 'local_status';
  static const feedbackTiming = 'feedback_timing';
  static const explanationLevel = 'show_explanation_level';
  static const isEphemeralPractice = 'is_ephemeral_practice';
  static const answers = 'answers';
  static const questions = 'questions';
}

/// Full local copy of an in-progress attempt so the test stays usable offline.
class LocalAttemptSnapshot {
  const LocalAttemptSnapshot({
    required this.attemptId,
    required this.testId,
    required this.userId,
    required this.title,
    required this.startedAt,
    required this.sectionStartedAt,
    required this.currentIndex,
    required this.localStatus,
    required this.feedbackTiming,
    required this.explanationLevel,
    required this.isEphemeralPractice,
    required this.answers,
    required this.questions,
  });

  final String attemptId;
  final String testId;
  final String userId;
  final String title;
  final DateTime startedAt;
  final Map<int, DateTime> sectionStartedAt;
  final int currentIndex;
  final LocalAttemptStatus localStatus;
  final FeedbackTiming feedbackTiming;
  final ExplanationLevel explanationLevel;
  final bool isEphemeralPractice;
  final Map<String, QuestionAnswer> answers;
  final List<PlayerQuestion> questions;

  factory LocalAttemptSnapshot.fromJson(Map<String, dynamic> json) {
    final sectionRaw = json[LocalAttemptKeys.sectionStartedAt];
    final sectionMap = <int, DateTime>{};
    if (sectionRaw is Map) {
      for (final entry in sectionRaw.entries) {
        final key = int.tryParse(entry.key.toString());
        final value = DateTime.tryParse(entry.value.toString());
        if (key != null && value != null) {
          sectionMap[key] = value;
        }
      }
    }

    final answersRaw = json[LocalAttemptKeys.answers];
    final answers = <String, QuestionAnswer>{};
    if (answersRaw is Map) {
      for (final entry in answersRaw.entries) {
        final value = entry.value;
        if (value is Map<String, dynamic>) {
          answers[entry.key.toString()] = QuestionAnswer.fromJson(value);
        } else if (value is Map) {
          answers[entry.key.toString()] = QuestionAnswer.fromJson(
            value.cast<String, dynamic>(),
          );
        }
      }
    }

    final questionsRaw = json[LocalAttemptKeys.questions];
    final questions = <PlayerQuestion>[];
    if (questionsRaw is List) {
      for (final item in questionsRaw) {
        if (item is Map<String, dynamic>) {
          questions.add(PlayerQuestion.fromSnapshotJson(item));
        } else if (item is Map) {
          questions.add(
            PlayerQuestion.fromSnapshotJson(item.cast<String, dynamic>()),
          );
        }
      }
    }

    return LocalAttemptSnapshot(
      attemptId: json[LocalAttemptKeys.attemptId] as String,
      testId: json[LocalAttemptKeys.testId] as String,
      userId: json[LocalAttemptKeys.userId] as String,
      title: json[LocalAttemptKeys.title] as String? ?? 'Test',
      startedAt:
          DateTime.tryParse(
            json[LocalAttemptKeys.startedAt] as String? ?? '',
          ) ??
          DateTime.now(),
      sectionStartedAt: sectionMap,
      currentIndex: _asInt(json[LocalAttemptKeys.currentIndex]),
      localStatus: LocalAttemptStatus.fromString(
        json[LocalAttemptKeys.localStatus] as String? ?? 'in_progress',
      ),
      feedbackTiming: FeedbackTiming.fromString(
        json[LocalAttemptKeys.feedbackTiming] as String? ?? 'on_submit',
      ),
      explanationLevel: ExplanationLevel.fromString(
        json[LocalAttemptKeys.explanationLevel] as String? ?? 'full',
      ),
      isEphemeralPractice:
          json[LocalAttemptKeys.isEphemeralPractice] as bool? ?? false,
      answers: answers,
      questions: questions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      LocalAttemptKeys.attemptId: attemptId,
      LocalAttemptKeys.testId: testId,
      LocalAttemptKeys.userId: userId,
      LocalAttemptKeys.title: title,
      LocalAttemptKeys.startedAt: startedAt.toUtc().toIso8601String(),
      LocalAttemptKeys.sectionStartedAt: {
        for (final entry in sectionStartedAt.entries)
          entry.key.toString(): entry.value.toUtc().toIso8601String(),
      },
      LocalAttemptKeys.currentIndex: currentIndex,
      LocalAttemptKeys.localStatus: localStatus.jsonValue,
      LocalAttemptKeys.feedbackTiming: feedbackTiming.dbValue,
      LocalAttemptKeys.explanationLevel: explanationLevel.dbValue,
      LocalAttemptKeys.isEphemeralPractice: isEphemeralPractice,
      LocalAttemptKeys.answers: {
        for (final entry in answers.entries) entry.key: entry.value.toJson(),
      },
      LocalAttemptKeys.questions: [
        for (final question in questions) question.toSnapshotJson(),
      ],
    };
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value == null) return 0;
    return int.tryParse(value.toString()) ?? 0;
  }
}
