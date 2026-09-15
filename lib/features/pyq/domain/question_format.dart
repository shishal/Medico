/// Exam-paper format inferred from `questions.kind` + `marks`.
///
/// Typical theory papers: essays ~10 marks, short notes ~5, VSAs ~2.
enum QuestionFormat {
  essay,
  shortNote,
  vsa,
  mcq,
  unclassified;

  String get label => switch (this) {
    QuestionFormat.essay => 'Essay',
    QuestionFormat.shortNote => 'Short note',
    QuestionFormat.vsa => 'VSA',
    QuestionFormat.mcq => 'MCQ',
    QuestionFormat.unclassified => 'Unclassified',
  };

  static QuestionFormat fromKindAndMarks({required String kind, num? marks}) {
    if (kind == 'mcq') return QuestionFormat.mcq;
    if (marks == null) return QuestionFormat.unclassified;
    if (marks >= 10) return QuestionFormat.essay;
    if (marks >= 4) return QuestionFormat.shortNote;
    return QuestionFormat.vsa;
  }
}
