/// Supabase table and column name constants — no magic strings in queries.
abstract final class Tables {
  static const profiles = 'profiles';
  static const tests = 'tests';
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

abstract final class TestColumns {
  static const id = 'id';
  static const title = 'title';
  static const description = 'description';
  static const testType = 'test_type';
  static const subjectId = 'subject_id';
  static const requiredPlan = 'required_plan';
  static const isSectional = 'is_sectional';
  static const totalDurationMinutes = 'total_duration_minutes';
  static const totalQuestions = 'total_questions';
  static const isActive = 'is_active';
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
