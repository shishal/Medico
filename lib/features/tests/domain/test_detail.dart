import '../../../core/supabase/tables.dart';
import '../../profile/domain/plan_tier.dart';
import 'test_type.dart';

/// Full catalog test row for the instructions screen (plan-gated via `tests` RLS).
///
/// Unlike [CatalogTest] teasers, this includes marking scheme and section shape —
/// only returned when the user's plan covers [requiredPlan].
class TestDetail {
  const TestDetail({
    required this.id,
    required this.title,
    this.description,
    required this.testType,
    required this.requiredPlan,
    required this.isSectional,
    required this.sectionCount,
    this.questionsPerSection,
    this.sectionDurationMinutes,
    required this.totalDurationMinutes,
    required this.totalQuestions,
    required this.correctMarks,
    required this.incorrectMarks,
    required this.unattemptedMarks,
  });

  final String id;
  final String title;
  final String? description;
  final TestType testType;
  final PlanTier requiredPlan;
  final bool isSectional;
  final int sectionCount;
  final int? questionsPerSection;
  final int? sectionDurationMinutes;
  final int totalDurationMinutes;
  final int totalQuestions;
  final num correctMarks;
  final num incorrectMarks;
  final num unattemptedMarks;

  /// e.g. "45 min" or "3h 30m".
  String get durationLabel {
    final hours = totalDurationMinutes ~/ 60;
    final minutes = totalDurationMinutes % 60;
    if (hours == 0) return '$minutes min';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  /// Per-section duration label when sectional; otherwise null.
  String? get sectionDurationLabel {
    final minutes = sectionDurationMinutes;
    if (!isSectional || minutes == null) return null;
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    if (rem == 0) return '${hours}h';
    return '${hours}h ${rem}m';
  }

  /// Marking line for the instructions UI, e.g. "+4 correct · −1 incorrect · 0 skipped".
  String get markingSchemeLabel =>
      '${_formatMarks(correctMarks)} correct · '
      '${_formatMarks(incorrectMarks)} incorrect · '
      '${_formatMarks(unattemptedMarks)} skipped';

  /// Human-readable section layout when [isSectional], else null.
  String? get sectionLayoutLabel {
    if (!isSectional) return null;
    final q = questionsPerSection;
    final d = sectionDurationLabel;
    final parts = <String>['$sectionCount sections'];
    if (q != null) parts.add('$q questions each');
    if (d != null) parts.add('$d each');
    return parts.join(' · ');
  }

  factory TestDetail.fromJson(Map<String, dynamic> json) {
    return TestDetail(
      id: json[TestColumns.id] as String,
      title: json[TestColumns.title] as String,
      description: json[TestColumns.description] as String?,
      testType: TestType.fromString(json[TestColumns.testType] as String),
      requiredPlan: PlanTier.fromString(
        json[TestColumns.requiredPlan] as String? ?? 'free',
      ),
      isSectional: json[TestColumns.isSectional] as bool? ?? false,
      sectionCount: _asInt(json[TestColumns.sectionCount] ?? 1),
      questionsPerSection: _asNullableInt(json[TestColumns.questionsPerSection]),
      sectionDurationMinutes:
          _asNullableInt(json[TestColumns.sectionDurationMinutes]),
      totalDurationMinutes: _asInt(json[TestColumns.totalDurationMinutes]),
      totalQuestions: _asInt(json[TestColumns.totalQuestions]),
      correctMarks: _asNum(json[TestColumns.correctMarks] ?? 4),
      incorrectMarks: _asNum(json[TestColumns.incorrectMarks] ?? -1),
      unattemptedMarks: _asNum(json[TestColumns.unattemptedMarks] ?? 0),
    );
  }

  static String _formatMarks(num marks) {
    final isWhole = marks == marks.truncateToDouble();
    final body = isWhole ? marks.toInt().toString() : marks.toString();
    if (marks > 0) return '+$body';
    // Unicode minus so "−1" reads clearly next to "+4".
    if (marks < 0) return '−${body.substring(1)}';
    return body;
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.parse(value.toString());
  }

  static int? _asNullableInt(Object? value) {
    if (value == null) return null;
    return _asInt(value);
  }

  static num _asNum(Object? value) {
    if (value is num) return value;
    return num.parse(value.toString());
  }
}
