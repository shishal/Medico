import 'created_practice_session.dart';
import 'practice_builder_draft.dart';
import 'practice_enums.dart';

/// Honest toasts when the server honored less than the student asked for.
abstract final class PracticeClampCopy {
  static String? toast({
    required PracticeBuilderDraft requested,
    required CreatedPracticeSession actual,
    required int maxSessionQuestions,
  }) {
    final parts = <String>[];

    if (actual.totalQuestions < requested.questionCount) {
      if (requested.questionCount > maxSessionQuestions) {
        parts.add(
          "Showing ${actual.totalQuestions} questions — your plan's practice limit",
        );
      } else {
        parts.add(
          'Showing ${actual.totalQuestions} questions matching your filters',
        );
      }
    }

    if (requested.explanationLevel == ExplanationLevel.full &&
        actual.explanationLevel != ExplanationLevel.full) {
      parts.add(
        "Full explanations aren't on your plan — showing the correct answer only",
      );
    }

    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }
}
