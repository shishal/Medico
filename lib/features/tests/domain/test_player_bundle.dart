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
  });

  final String testId;
  final String title;
  final FeedbackTiming feedbackTiming;
  final ExplanationLevel explanationLevel;
  final bool isEphemeralPractice;
  final List<PlayerQuestion> questions;

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
    );
  }
}
