import 'question_option.dart';

/// Local per-question state for the current player session.
///
/// Persistence (autosave / `attempt_answers`) arrives in Phase 5.1 — this
/// object is the in-memory shape that layer will write out.
class QuestionAnswer {
  const QuestionAnswer({
    this.visited = false,
    this.selectedOption,
    this.markedForReview = false,
  });

  final bool visited;
  final QuestionOption? selectedOption;
  final bool markedForReview;

  QuestionAnswer copyWith({
    bool? visited,
    QuestionOption? selectedOption,
    bool? markedForReview,
  }) {
    return QuestionAnswer(
      visited: visited ?? this.visited,
      selectedOption: selectedOption ?? this.selectedOption,
      markedForReview: markedForReview ?? this.markedForReview,
    );
  }

  /// Clears the chosen option but keeps visited/marked flags.
  QuestionAnswer withoutSelection() {
    return QuestionAnswer(visited: visited, markedForReview: markedForReview);
  }
}
