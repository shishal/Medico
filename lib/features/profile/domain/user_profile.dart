import '../../../core/supabase/tables.dart';
import 'plan_tier.dart';

/// Row from the `profiles` table for the logged-in user.
class UserProfile {
  const UserProfile({
    required this.id,
    this.fullName,
    this.phone,
    required this.plan,
    this.planStartedAt,
    this.planExpiresAt,
    required this.createdAt,
  });

  final String id;
  final String? fullName;
  final String? phone;

  /// Plan stored on the row — may still say `pro`/`elite` after expiry.
  final PlanTier plan;
  final DateTime? planStartedAt;
  final DateTime? planExpiresAt;
  final DateTime createdAt;

  /// Effective plan for UI (lock icons, upgrade prompts).
  ///
  /// Mirrors Postgres `current_plan()`: if [planExpiresAt] is in the past,
  /// treat the user as free. RLS still enforces access server-side; this is
  /// only for display decisions so screens don't re-implement expiry logic.
  PlanTier get effectivePlan {
    final expiresAt = planExpiresAt;
    if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
      return PlanTier.free;
    }
    return plan;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json[ProfileColumns.id] as String,
      fullName: json[ProfileColumns.fullName] as String?,
      phone: json[ProfileColumns.phone] as String?,
      plan: PlanTier.fromString(json[ProfileColumns.plan] as String),
      planStartedAt: _parseDate(json[ProfileColumns.planStartedAt]),
      planExpiresAt: _parseDate(json[ProfileColumns.planExpiresAt]),
      createdAt: _parseDate(json[ProfileColumns.createdAt]) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value as String);
  }
}
