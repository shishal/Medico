/// Supabase table and column name constants — no magic strings in queries.
abstract final class Tables {
  static const profiles = 'profiles';
  static const tests = 'tests';
  static const tags = 'tags';
  static const questionTags = 'question_tags';
  static const planLimits = 'plan_limits';
  static const dailyPracticeUsage = 'daily_practice_usage';

  /// Safe metadata only (title/type/counts) — all authenticated users.
  /// See migration `phase4_2_catalog_test_teasers`. Not the full `tests` row.
  static const catalogTestTeasers = 'catalog_test_teasers';
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
  static const sectionCount = 'section_count';
  static const questionsPerSection = 'questions_per_section';
  static const sectionDurationMinutes = 'section_duration_minutes';
  static const totalDurationMinutes = 'total_duration_minutes';
  static const totalQuestions = 'total_questions';
  static const correctMarks = 'correct_marks';
  static const incorrectMarks = 'incorrect_marks';
  static const unattemptedMarks = 'unattempted_marks';
  static const isActive = 'is_active';
  static const createdAt = 'created_at';
  static const ownerUserId = 'owner_user_id';
  static const isEphemeralPractice = 'is_ephemeral_practice';
  static const feedbackTiming = 'feedback_timing';
  static const showExplanationLevel = 'show_explanation_level';
  static const timerEnabled = 'timer_enabled';
  static const practiceFilterCriteria = 'practice_filter_criteria';
}

abstract final class PlanLimitsColumns {
  static const plan = 'plan';
  static const maxPracticeSessionQuestions = 'max_practice_session_questions';
  static const dailyPracticeQuestionQuota = 'daily_practice_question_quota';
  static const allowFullExplanation = 'allow_full_explanation';
  static const allowTimerToggle = 'allow_timer_toggle';
  static const allowTagFilter = 'allow_tag_filter';
  static const allowDifficultyFilter = 'allow_difficulty_filter';
  static const allowNegativeMarkingToggle = 'allow_negative_marking_toggle';
}

/// Postgres RPC function names (see `docs/02_DATABASE_SCHEMA.md`).
abstract final class RpcFunctions {
  static const currentPlan = 'current_plan';
  static const createPracticeSession = 'create_practice_session';
}

/// Named parameters for [RpcFunctions.currentPlan].
abstract final class CurrentPlanParams {
  static const userId = 'p_user_id';
}

/// Named parameters for [RpcFunctions.createPracticeSession].
abstract final class CreatePracticeSessionParams {
  static const topicIds = 'p_topic_ids';
  static const tagIds = 'p_tag_ids';
  static const difficulties = 'p_difficulties';
  static const sourceFilter = 'p_source_filter';
  static const questionCount = 'p_question_count';
  static const feedbackTiming = 'p_feedback_timing';
  static const explanationLevel = 'p_explanation_level';
  static const timerMinutes = 'p_timer_minutes';
  static const negativeMarking = 'p_negative_marking';
}
