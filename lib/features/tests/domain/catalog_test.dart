import '../../../core/supabase/tables.dart';
import '../../profile/domain/plan_tier.dart';
import 'test_type.dart';

/// A shared catalog row from `tests` (not an ephemeral practice session).
///
/// RLS already hides rows the user's plan cannot access — this model is what
/// comes back after that filter, for list UI only.
class CatalogTest {
  const CatalogTest({
    required this.id,
    required this.title,
    this.description,
    required this.testType,
    required this.requiredPlan,
    required this.totalDurationMinutes,
    required this.totalQuestions,
    required this.isSectional,
  });

  final String id;
  final String title;
  final String? description;
  final TestType testType;
  final PlanTier requiredPlan;
  final int totalDurationMinutes;
  final int totalQuestions;
  final bool isSectional;

  /// e.g. "45 min" or "1h 30m" for the list subtitle.
  String get durationLabel {
    final hours = totalDurationMinutes ~/ 60;
    final minutes = totalDurationMinutes % 60;
    if (hours == 0) return '$minutes min';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  factory CatalogTest.fromJson(Map<String, dynamic> json) {
    return CatalogTest(
      id: json[TestColumns.id] as String,
      title: json[TestColumns.title] as String,
      description: json[TestColumns.description] as String?,
      testType: TestType.fromString(json[TestColumns.testType] as String),
      requiredPlan: PlanTier.fromString(
        json[TestColumns.requiredPlan] as String? ?? 'free',
      ),
      totalDurationMinutes: _asInt(json[TestColumns.totalDurationMinutes]),
      totalQuestions: _asInt(json[TestColumns.totalQuestions]),
      isSectional: json[TestColumns.isSectional] as bool? ?? false,
    );
  }

  /// Postgrest may return ints as int or (rarely) as num — normalize.
  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.parse(value.toString());
  }
}
