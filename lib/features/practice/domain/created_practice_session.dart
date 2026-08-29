import '../../../core/supabase/tables.dart';
import 'practice_enums.dart';

/// The `tests` row created by `create_practice_session()` — used to detect
/// server-side clamping (fewer questions, explanation downgraded).
class CreatedPracticeSession {
  const CreatedPracticeSession({
    required this.testId,
    required this.totalQuestions,
    required this.explanationLevel,
    required this.timerEnabled,
    required this.totalDurationMinutes,
  });

  final String testId;
  final int totalQuestions;
  final ExplanationLevel explanationLevel;
  final bool timerEnabled;
  final int totalDurationMinutes;

  factory CreatedPracticeSession.fromJson(Map<String, dynamic> json) {
    return CreatedPracticeSession(
      testId: json[TestColumns.id] as String,
      totalQuestions: _asInt(json[TestColumns.totalQuestions]),
      explanationLevel: ExplanationLevel.fromString(
        json[TestColumns.showExplanationLevel] as String? ?? 'answer_only',
      ),
      timerEnabled: json[TestColumns.timerEnabled] as bool? ?? true,
      totalDurationMinutes: _asInt(json[TestColumns.totalDurationMinutes]),
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.parse(value.toString());
  }
}
