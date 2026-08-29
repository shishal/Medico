/// Matches the Postgres `plan_tier` enum (free / pro / elite).
enum PlanTier {
  free,
  pro,
  elite;

  static PlanTier fromString(String value) {
    return switch (value.toLowerCase()) {
      'pro' => PlanTier.pro,
      'elite' => PlanTier.elite,
      _ => PlanTier.free,
    };
  }

  /// Short label for UI (lock badges, profile header, etc.).
  String get label => switch (this) {
        PlanTier.free => 'Free',
        PlanTier.pro => 'Pro',
        PlanTier.elite => 'Elite',
      };
}
