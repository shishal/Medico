/// Supabase table and column name constants — no magic strings in queries.
abstract final class Tables {
  static const profiles = 'profiles';
}

abstract final class ProfileColumns {
  static const id = 'id';
  static const fullName = 'full_name';
  static const phone = 'phone';
  static const plan = 'plan';
  static const planStartedAt = 'plan_started_at';
  static const planExpiresAt = 'plan_expires_at';
  static const createdAt = 'created_at';
}

/// Postgres RPC function names (see `docs/02_DATABASE_SCHEMA.md`).
abstract final class RpcFunctions {
  static const currentPlan = 'current_plan';
}

/// Named parameters for [RpcFunctions.currentPlan].
abstract final class CurrentPlanParams {
  static const userId = 'p_user_id';
}
