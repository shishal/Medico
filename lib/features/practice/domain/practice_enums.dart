/// Postgres `question_difficulty` enum — Easy / Medium / Hard.
enum QuestionDifficulty {
  easy,
  medium,
  hard;

  static QuestionDifficulty fromString(String value) {
    return switch (value.toLowerCase()) {
      'easy' => QuestionDifficulty.easy,
      'hard' => QuestionDifficulty.hard,
      _ => QuestionDifficulty.medium,
    };
  }

  String get dbValue => name;

  String get label => switch (this) {
        QuestionDifficulty.easy => 'Easy',
        QuestionDifficulty.medium => 'Medium',
        QuestionDifficulty.hard => 'Hard',
      };
}

/// `create_practice_session` `p_source_filter` values.
enum QuestionSourceFilter {
  unattempted,
  incorrect,
  bookmarked,
  all;

  static QuestionSourceFilter fromString(String value) {
    return switch (value.toLowerCase()) {
      'incorrect' => QuestionSourceFilter.incorrect,
      'bookmarked' => QuestionSourceFilter.bookmarked,
      'all' => QuestionSourceFilter.all,
      _ => QuestionSourceFilter.unattempted,
    };
  }

  String get dbValue => name;

  String get label => switch (this) {
        QuestionSourceFilter.unattempted => 'Unattempted',
        QuestionSourceFilter.incorrect => 'Previously Incorrect',
        QuestionSourceFilter.bookmarked => 'Bookmarked',
        QuestionSourceFilter.all => 'All',
      };

  String get subtitle => switch (this) {
        QuestionSourceFilter.unattempted =>
          'Questions you have not answered yet',
        QuestionSourceFilter.incorrect => 'Ones you got wrong last time',
        QuestionSourceFilter.bookmarked => 'From your bookmarks',
        QuestionSourceFilter.all => 'Entire question bank you can access',
      };
}

/// `tests.feedback_timing`: Tutor Mode vs Exam Mode.
enum FeedbackTiming {
  immediate,
  onSubmit;

  static FeedbackTiming fromString(String value) {
    return switch (value.toLowerCase()) {
      'immediate' => FeedbackTiming.immediate,
      _ => FeedbackTiming.onSubmit,
    };
  }

  String get dbValue => switch (this) {
        FeedbackTiming.immediate => 'immediate',
        FeedbackTiming.onSubmit => 'on_submit',
      };

  /// Labels students already know from other QBanks.
  String get label => switch (this) {
        FeedbackTiming.immediate => 'Tutor Mode',
        FeedbackTiming.onSubmit => 'Exam Mode',
      };

  String get subtitle => switch (this) {
        FeedbackTiming.immediate =>
          'See the answer and explanation after each question',
        FeedbackTiming.onSubmit => 'See everything at the end, like a real test',
      };
}

/// `tests.show_explanation_level`.
enum ExplanationLevel {
  none,
  answerOnly,
  full;

  static ExplanationLevel fromString(String value) {
    return switch (value.toLowerCase()) {
      'none' => ExplanationLevel.none,
      'full' => ExplanationLevel.full,
      _ => ExplanationLevel.answerOnly,
    };
  }

  String get dbValue => switch (this) {
        ExplanationLevel.none => 'none',
        ExplanationLevel.answerOnly => 'answer_only',
        ExplanationLevel.full => 'full',
      };

  String get label => switch (this) {
        ExplanationLevel.none => 'None',
        ExplanationLevel.answerOnly => 'Answer only',
        ExplanationLevel.full => 'Full explanation',
      };
}
