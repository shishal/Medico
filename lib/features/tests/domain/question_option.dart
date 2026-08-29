/// A/B/C/D letters stored on `questions.correct_option` and `attempt_answers`.
enum QuestionOption {
  a,
  b,
  c,
  d;

  static QuestionOption fromString(String value) {
    return switch (value.trim().toUpperCase()) {
      'B' => QuestionOption.b,
      'C' => QuestionOption.c,
      'D' => QuestionOption.d,
      _ => QuestionOption.a,
    };
  }

  String get dbValue => switch (this) {
    QuestionOption.a => 'A',
    QuestionOption.b => 'B',
    QuestionOption.c => 'C',
    QuestionOption.d => 'D',
  };

  String get label => dbValue;
}
