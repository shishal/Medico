import '../../../core/supabase/tables.dart';

/// Server-computed score returned by `submit_attempt`. Never calculated in Dart.
class AttemptScore {
  const AttemptScore({
    required this.attemptId,
    required this.testId,
    required this.totalScore,
    required this.correctCount,
    required this.incorrectCount,
    required this.unattemptedCount,
    this.percentile,
    this.submittedAt,
  });

  final String attemptId;
  final String testId;
  final double totalScore;
  final int correctCount;
  final int incorrectCount;
  final int unattemptedCount;
  final double? percentile;
  final DateTime? submittedAt;

  factory AttemptScore.fromJson(Map<String, dynamic> json) {
    return AttemptScore(
      attemptId: json[AttemptColumns.id] as String,
      testId: json[AttemptColumns.testId] as String,
      totalScore: _asDouble(json[AttemptColumns.totalScore]),
      correctCount: _asInt(json[AttemptColumns.correctCount]),
      incorrectCount: _asInt(json[AttemptColumns.incorrectCount]),
      unattemptedCount: _asInt(json[AttemptColumns.unattemptedCount]),
      percentile: _asNullableDouble(json[AttemptColumns.percentile]),
      submittedAt: _parseDate(json[AttemptColumns.submittedAt]),
    );
  }

  static double _asDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value == null) return 0;
    return double.tryParse(value.toString()) ?? 0;
  }

  static double? _asNullableDouble(Object? value) {
    if (value == null) return null;
    return _asDouble(value);
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value == null) return 0;
    return int.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
