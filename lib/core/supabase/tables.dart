/// Supabase table and column name constants — no magic strings in queries.
abstract final class Tables {
  static const profiles = 'profiles';
  static const subjects = 'subjects';
  static const topics = 'topics';
  static const tests = 'tests';
  static const questions = 'questions';
  static const testQuestions = 'test_questions';
  static const tags = 'tags';
  static const questionTags = 'question_tags';
  static const planLimits = 'plan_limits';
  static const dailyPracticeUsage = 'daily_practice_usage';
  static const attempts = 'attempts';
  static const attemptAnswers = 'attempt_answers';
  static const bookmarks = 'bookmarks';
  static const screenshotEvents = 'screenshot_events';

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

abstract final class QuestionColumns {
  static const id = 'id';
  static const topicId = 'topic_id';
  static const questionText = 'question_text';
  static const optionA = 'option_a';
  static const optionB = 'option_b';
  static const optionC = 'option_c';
  static const optionD = 'option_d';
  static const correctOption = 'correct_option';
  static const explanationText = 'explanation_text';
  static const explanationVideoUrl = 'explanation_video_url';
  static const imageUrl = 'image_url';
  static const difficulty = 'difficulty';
  static const requiredPlan = 'required_plan';
  static const isActive = 'is_active';

  /// PostgREST embed alias: `topic:topics(...)`.
  static const topicEmbed = 'topic';
}

abstract final class TestQuestionColumns {
  static const testId = 'test_id';
  static const questionId = 'question_id';
  static const sectionNumber = 'section_number';
  static const orderIndex = 'order_index';

  /// PostgREST embed alias: `question:questions(...)`.
  static const questionEmbed = 'question';
}

abstract final class SubjectColumns {
  static const id = 'id';
  static const name = 'name';
  static const displayOrder = 'display_order';
}

abstract final class TopicColumns {
  static const id = 'id';
  static const subjectId = 'subject_id';
  static const name = 'name';
  static const displayOrder = 'display_order';

  /// PostgREST embed alias: `subject:subjects(...)`.
  static const subjectEmbed = 'subject';
}

abstract final class TagColumns {
  static const id = 'id';
  static const name = 'name';
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

abstract final class DailyPracticeUsageColumns {
  static const userId = 'user_id';
  static const usageDate = 'usage_date';
  static const questionsUsed = 'questions_used';
}

abstract final class AttemptColumns {
  static const id = 'id';
  static const userId = 'user_id';
  static const testId = 'test_id';
  static const status = 'status';
  static const startedAt = 'started_at';
  static const sectionStartedAt = 'section_started_at';
  static const submittedAt = 'submitted_at';
  static const totalScore = 'total_score';
  static const correctCount = 'correct_count';
  static const incorrectCount = 'incorrect_count';
  static const unattemptedCount = 'unattempted_count';
  static const percentile = 'percentile';
  static const createdAt = 'created_at';

  /// PostgREST embed alias: `test:tests(...)`.
  static const testEmbed = 'test';
}

abstract final class BookmarkColumns {
  static const userId = 'user_id';
  static const questionId = 'question_id';
  static const createdAt = 'created_at';

  /// PostgREST embed alias: `question:questions(...)`.
  static const questionEmbed = 'question';
}

abstract final class ScreenshotEventColumns {
  static const id = 'id';
  static const userId = 'user_id';
  static const screen = 'screen';
  static const eventType = 'event_type';
  static const createdAt = 'created_at';
}

abstract final class ScreenshotEventTypes {
  static const screenshot = 'screenshot';
  static const screenRecording = 'screen_recording';
}

abstract final class AttemptAnswerColumns {
  static const id = 'id';
  static const attemptId = 'attempt_id';
  static const questionId = 'question_id';
  static const selectedOption = 'selected_option';
  static const isMarkedForReview = 'is_marked_for_review';
  static const timeSpentSeconds = 'time_spent_seconds';
  static const answeredAt = 'answered_at';
}

/// Postgres RPC function names (see `docs/02_DATABASE_SCHEMA.md`).
abstract final class RpcFunctions {
  static const currentPlan = 'current_plan';
  static const createPracticeSession = 'create_practice_session';
  static const serverNow = 'server_now';
  static const submitAttempt = 'submit_attempt';
  static const getAttemptResults = 'get_attempt_results';
}

/// Named parameters for [RpcFunctions.currentPlan].
abstract final class CurrentPlanParams {
  static const userId = 'p_user_id';
}

/// Named parameters for [RpcFunctions.submitAttempt].
abstract final class SubmitAttemptParams {
  static const attemptId = 'p_attempt_id';
  static const answers = 'p_answers';
}

/// Named parameters for [RpcFunctions.getAttemptResults].
abstract final class GetAttemptResultsParams {
  static const attemptId = 'p_attempt_id';
}

/// Extra keys on the `get_attempt_results` JSON (not `attempts` columns).
abstract final class AttemptResultsJson {
  static const testTitle = 'test_title';
  static const durationSeconds = 'duration_seconds';
  static const questionTimeSeconds = 'question_time_seconds';
  static const subjects = 'subjects';
  static const subjectId = 'subject_id';
  static const subjectName = 'subject_name';
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

/// Keys inside `tests.practice_filter_criteria` (written by `create_practice_session`).
abstract final class PracticeFilterCriteriaKeys {
  static const topicIds = 'topic_ids';
  static const tagIds = 'tag_ids';
  static const difficulties = 'difficulties';
  static const sourceFilter = 'source_filter';
  static const requestedQuestionCount = 'requested_question_count';
  static const requestedExplanationLevel = 'requested_explanation_level';
  static const negativeMarking = 'negative_marking';
  static const timerMinutes = 'timer_minutes';
}
