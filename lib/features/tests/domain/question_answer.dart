import 'question_option.dart';

/// JSON keys for one entry in the local attempt snapshot's `answers` map.
abstract final class QuestionAnswerKeys {
  static const visited = 'visited';
  static const selectedOption = 'selected_option';
  static const markedForReview = 'marked_for_review';
  static const timeSpentSeconds = 'time_spent_seconds';
}

/// Local per-question state for the current player session.
class QuestionAnswer {
  const QuestionAnswer({
    this.visited = false,
    this.selectedOption,
    this.markedForReview = false,
    this.timeSpentSeconds = 0,
  });

  final bool visited;
  final QuestionOption? selectedOption;
  final bool markedForReview;
  final int timeSpentSeconds;

  QuestionAnswer copyWith({
    bool? visited,
    QuestionOption? selectedOption,
    bool? markedForReview,
    int? timeSpentSeconds,
  }) {
    return QuestionAnswer(
      visited: visited ?? this.visited,
      selectedOption: selectedOption ?? this.selectedOption,
      markedForReview: markedForReview ?? this.markedForReview,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
    );
  }

  /// Clears the chosen option but keeps visited/marked/time flags.
  QuestionAnswer withoutSelection() {
    return QuestionAnswer(
      visited: visited,
      markedForReview: markedForReview,
      timeSpentSeconds: timeSpentSeconds,
    );
  }

  QuestionAnswer addTime(int seconds) {
    if (seconds <= 0) return this;
    return copyWith(timeSpentSeconds: timeSpentSeconds + seconds);
  }

  factory QuestionAnswer.fromJson(Map<String, dynamic> json) {
    final optionRaw = json[QuestionAnswerKeys.selectedOption] as String?;
    return QuestionAnswer(
      visited: json[QuestionAnswerKeys.visited] as bool? ?? false,
      selectedOption: optionRaw == null || optionRaw.isEmpty
          ? null
          : QuestionOption.fromString(optionRaw),
      markedForReview:
          json[QuestionAnswerKeys.markedForReview] as bool? ?? false,
      timeSpentSeconds: _asInt(json[QuestionAnswerKeys.timeSpentSeconds]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      QuestionAnswerKeys.visited: visited,
      QuestionAnswerKeys.selectedOption: selectedOption?.dbValue,
      QuestionAnswerKeys.markedForReview: markedForReview,
      QuestionAnswerKeys.timeSpentSeconds: timeSpentSeconds,
    };
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value == null) return 0;
    return int.tryParse(value.toString()) ?? 0;
  }
}
