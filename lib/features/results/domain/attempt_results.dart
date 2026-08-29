import '../../../core/supabase/tables.dart';

/// Correct / incorrect / unattempted for one subject on a submitted attempt.
class SubjectBreakdown {
  const SubjectBreakdown({
    required this.subjectId,
    required this.subjectName,
    required this.correctCount,
    required this.incorrectCount,
    required this.unattemptedCount,
  });

  final String subjectId;
  final String subjectName;
  final int correctCount;
  final int incorrectCount;
  final int unattemptedCount;

  int get questionCount => correctCount + incorrectCount + unattemptedCount;

  factory SubjectBreakdown.fromJson(Map<String, dynamic> json) {
    return SubjectBreakdown(
      subjectId: json[AttemptResultsJson.subjectId] as String,
      subjectName: json[AttemptResultsJson.subjectName] as String? ?? 'Subject',
      correctCount: _asInt(json[AttemptColumns.correctCount]),
      incorrectCount: _asInt(json[AttemptColumns.incorrectCount]),
      unattemptedCount: _asInt(json[AttemptColumns.unattemptedCount]),
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value == null) return 0;
  return int.tryParse(value.toString()) ?? 0;
}

double _asDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value == null) return 0;
  return double.tryParse(value.toString()) ?? 0;
}

double? _asNullableDouble(Object? value) {
  if (value == null) return null;
  return _asDouble(value);
}

num _asNum(Object? value) {
  if (value is num) return value;
  if (value == null) return 0;
  return num.tryParse(value.toString()) ?? 0;
}

DateTime? _parseDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

/// Submitted-attempt summary from `get_attempt_results`.
///
/// Score and counts are the values Postgres stored at submit time. Accuracy %
/// and time labels are display math on those numbers — not a second scoring
/// pass (see AGENTS.md: scoring stays in SQL).
class AttemptResults {
  const AttemptResults({
    required this.attemptId,
    required this.testId,
    required this.testTitle,
    required this.totalScore,
    required this.correctCount,
    required this.incorrectCount,
    required this.unattemptedCount,
    required this.durationSeconds,
    required this.correctMarks,
    required this.incorrectMarks,
    required this.unattemptedMarks,
    required this.subjects,
    this.percentile,
    this.submittedAt,
    this.questionTimeSeconds = 0,
    this.isEphemeralPractice = false,
  });

  final String attemptId;
  final String testId;
  final String testTitle;
  final double totalScore;
  final int correctCount;
  final int incorrectCount;
  final int unattemptedCount;
  final double? percentile;
  final DateTime? submittedAt;
  final int durationSeconds;
  final int questionTimeSeconds;
  final bool isEphemeralPractice;
  final num correctMarks;
  final num incorrectMarks;
  final num unattemptedMarks;
  final List<SubjectBreakdown> subjects;

  int get questionCount => correctCount + incorrectCount + unattemptedCount;

  /// Practice with negative marking off uses +1 / 0 / 0 — show accuracy, not
  /// a NEET-style score (practice spec §5).
  bool get usesNeetStyleScore =>
      incorrectMarks != 0 || unattemptedMarks != 0 || correctMarks != 1;

  /// Correct / all questions, including skips. 0 if the test had no questions.
  double get accuracyPercent {
    if (questionCount == 0) return 0;
    return (correctCount / questionCount) * 100;
  }

  /// Max marks if every question were correct (display only).
  double get maxScore => questionCount * correctMarks.toDouble();

  bool get subjectTotalsMatchOverall {
    var correct = 0;
    var incorrect = 0;
    var unattempted = 0;
    for (final row in subjects) {
      correct += row.correctCount;
      incorrect += row.incorrectCount;
      unattempted += row.unattemptedCount;
    }
    return correct == correctCount &&
        incorrect == incorrectCount &&
        unattempted == unattemptedCount;
  }

  String get scoreLabel => _formatNumber(totalScore);

  String get maxScoreLabel => _formatNumber(maxScore);

  String get accuracyLabel => '${_formatNumber(accuracyPercent)}%';

  String? get percentileLabel {
    if (percentile == null) return null;
    return _formatNumber(percentile!);
  }

  /// Wall-clock time from start to submit, e.g. "12m 5s" or "1h 2m".
  String get timeSpentLabel => formatTimeSpent(durationSeconds);

  factory AttemptResults.fromJson(Map<String, dynamic> json) {
    return AttemptResults(
      attemptId: json[AttemptColumns.id] as String,
      testId: json[AttemptColumns.testId] as String,
      testTitle: json[AttemptResultsJson.testTitle] as String? ?? 'Test',
      totalScore: _asDouble(json[AttemptColumns.totalScore]),
      correctCount: _asInt(json[AttemptColumns.correctCount]),
      incorrectCount: _asInt(json[AttemptColumns.incorrectCount]),
      unattemptedCount: _asInt(json[AttemptColumns.unattemptedCount]),
      percentile: _asNullableDouble(json[AttemptColumns.percentile]),
      submittedAt: _parseDate(json[AttemptColumns.submittedAt]),
      durationSeconds: _asInt(json[AttemptResultsJson.durationSeconds]),
      questionTimeSeconds: _asInt(json[AttemptResultsJson.questionTimeSeconds]),
      isEphemeralPractice:
          json[TestColumns.isEphemeralPractice] as bool? ?? false,
      correctMarks: _asNum(json[TestColumns.correctMarks]),
      incorrectMarks: _asNum(json[TestColumns.incorrectMarks]),
      unattemptedMarks: _asNum(json[TestColumns.unattemptedMarks]),
      subjects: _parseSubjects(json[AttemptResultsJson.subjects]),
    );
  }

  static List<SubjectBreakdown> _parseSubjects(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map)
          SubjectBreakdown.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  static String _formatNumber(num value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}

/// e.g. "45s", "12m 5s", "1h 2m".
String formatTimeSpent(int seconds) {
  final total = seconds < 0 ? 0 : seconds;
  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  final secs = total % 60;
  if (hours > 0) {
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }
  if (minutes > 0) {
    if (secs == 0) return '${minutes}m';
    return '${minutes}m ${secs}s';
  }
  return '${secs}s';
}
