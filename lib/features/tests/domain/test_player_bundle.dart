import '../../../core/supabase/tables.dart';
import '../../practice/domain/practice_enums.dart';
import 'player_question.dart';

/// Test row + downloaded questions for the player.
///
/// Catalog tests default to Exam Mode (`on_submit`). Practice sessions set
/// `feedback_timing` / `show_explanation_level` in `create_practice_session()`.
class TestPlayerBundle {
  const TestPlayerBundle({
    required this.testId,
    required this.title,
    required this.feedbackTiming,
    required this.explanationLevel,
    required this.isEphemeralPractice,
    required this.questions,
    this.isSectional = false,
    this.sectionCount = 1,
    this.questionsPerSection,
    this.sectionDurationMinutes,
    this.totalDurationMinutes = 0,
    this.timerEnabled = true,
  });

  final String testId;
  final String title;
  final FeedbackTiming feedbackTiming;
  final ExplanationLevel explanationLevel;
  final bool isEphemeralPractice;
  final List<PlayerQuestion> questions;
  final bool isSectional;
  final int sectionCount;
  final int? questionsPerSection;
  final int? sectionDurationMinutes;
  final int totalDurationMinutes;
  final bool timerEnabled;

  factory TestPlayerBundle.fromParts({
    required Map<String, dynamic> testRow,
    required List<PlayerQuestion> questions,
  }) {
    return TestPlayerBundle(
      testId: testRow[TestColumns.id] as String,
      title: testRow[TestColumns.title] as String? ?? 'Test',
      feedbackTiming: FeedbackTiming.fromString(
        testRow[TestColumns.feedbackTiming] as String? ?? 'on_submit',
      ),
      explanationLevel: ExplanationLevel.fromString(
        testRow[TestColumns.showExplanationLevel] as String? ?? 'full',
      ),
      isEphemeralPractice:
          testRow[TestColumns.isEphemeralPractice] as bool? ?? false,
      questions: questions,
      isSectional: testRow[TestColumns.isSectional] as bool? ?? false,
      sectionCount: _asInt(testRow[TestColumns.sectionCount] ?? 1),
      questionsPerSection: _asNullableInt(
        testRow[TestColumns.questionsPerSection],
      ),
      sectionDurationMinutes: _asNullableInt(
        testRow[TestColumns.sectionDurationMinutes],
      ),
      totalDurationMinutes: _asInt(
        testRow[TestColumns.totalDurationMinutes] ?? 0,
      ),
      timerEnabled: testRow[TestColumns.timerEnabled] as bool? ?? true,
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.parse(value.toString());
  }

  static int? _asNullableInt(Object? value) {
    if (value == null) return null;
    return _asInt(value);
  }
}
