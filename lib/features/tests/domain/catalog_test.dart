import '../../../core/supabase/tables.dart';
import '../../profile/domain/plan_tier.dart';
import 'test_type.dart';

/// Catalog list row from `catalog_test_teasers` (safe metadata only).
///
/// Teasers are visible to every signed-in user. Use [isLockedFor] with the
/// user's effective plan to show a lock — do not treat presence in this list
/// as permission to open questions (those stay RLS-gated on `tests`).
class CatalogTest {
  const CatalogTest({
    required this.id,
    required this.title,
    required this.testType,
    required this.requiredPlan,
    required this.totalDurationMinutes,
    required this.totalQuestions,
    required this.isSectional,
  });

  final String id;
  final String title;
  final TestType testType;
  final PlanTier requiredPlan;
  final int totalDurationMinutes;
  final int totalQuestions;
  final bool isSectional;

  /// True when [userPlan] is below [requiredPlan] — show lock + upgrade CTA.
  bool isLockedFor(PlanTier userPlan) => !userPlan.covers(requiredPlan);

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
