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

  /// Same ordering as Postgres `plan_rank()` — free < pro < elite.
  /// Enum declaration order matches, so [index] is the rank.
  int get rank => index;

  /// Whether this plan can open content that requires [required].
  bool covers(PlanTier required) => rank >= required.rank;

  /// Short label for UI (lock badges, profile header, etc.).
  String get label => switch (this) {
        PlanTier.free => 'Free',
        PlanTier.pro => 'Pro',
        PlanTier.elite => 'Elite',
      };
}
