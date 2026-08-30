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
  static const universities = 'universities';
  static const mbbsPhases = 'mbbs_phases';
  static const colleges = 'colleges';
  static const lessons = 'lessons';
  static const textbooks = 'textbooks';
  static const examPapers = 'exam_papers';
  static const lessonResources = 'lesson_resources';
  static const questionResources = 'question_resources';
  static const questionSampleAnswers = 'question_sample_answers';
  static const questionAppearances = 'question_appearances';
  static const questionTextbookRefs = 'question_textbook_refs';
  static const pyqTeasers = 'pyq_teasers';
  static const lessonProgress = 'lesson_progress';
  static const questionProgress = 'question_progress';
  static const lessonBookmarks = 'lesson_bookmarks';
  static const studyEvents = 'study_events';
  static const trackers = 'trackers';
  static const trackerItems = 'tracker_items';
  static const userTrackerItemDone = 'user_tracker_item_done';

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
  static const universityId = 'university_id';
  static const collegeId = 'college_id';
  static const batchYear = 'batch_year';
  static const mbbsPhaseId = 'mbbs_phase_id';
  static const onboardingCompletedAt = 'onboarding_completed_at';
}

abstract final class TestColumns {
  static const id = 'id';
  static const title = 'title';
  /// Catalog sheet upsert key. NULL on practice sessions.
  static const sheetKey = 'sheet_key';
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
  static const kind = 'kind';
  static const lessonId = 'lesson_id';
  static const marks = 'marks';

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
  static const mbbsPhaseId = 'mbbs_phase_id';
  static const requiredPlan = 'required_plan';
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
  static const markLessonLearnt = 'mark_lesson_learnt';
  static const markQuestionLearnt = 'mark_question_learnt';
  static const recordStudyEvent = 'record_study_event';
  static const getStudyProgress = 'get_study_progress';
  static const trackerCompletion = 'tracker_completion';
  static const searchCatalog = 'search_catalog';
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
  static const lessonIds = 'p_lesson_ids';
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
  static const lessonIds = 'lesson_ids';
}

abstract final class UniversityColumns {
  static const id = 'id';
  static const code = 'code';
  static const name = 'name';
  static const state = 'state';
  static const slug = 'slug';
}

abstract final class MbbsPhaseColumns {
  static const id = 'id';
  static const code = 'code';
  static const name = 'name';
  static const displayOrder = 'display_order';
}

abstract final class CollegeColumns {
  static const id = 'id';
  static const universityId = 'university_id';
  static const name = 'name';
}

abstract final class LessonColumns {
  static const id = 'id';
  static const topicId = 'topic_id';
  static const externalId = 'external_id';
  static const name = 'name';
  static const displayOrder = 'display_order';
  static const requiredPlan = 'required_plan';
  static const isActive = 'is_active';

  /// PostgREST embed alias: `topic:topics(...)`.
  static const topicEmbed = 'topic';
}

abstract final class PyqTeaserColumns {
  static const id = 'id';
  static const lessonId = 'lesson_id';
  static const topicId = 'topic_id';
  static const questionText = 'question_text';
  static const marks = 'marks';
  static const requiredPlan = 'required_plan';
  static const isActive = 'is_active';
  static const appearanceCount = 'appearance_count';
}

abstract final class ResourceColumns {
  static const id = 'id';
  static const lessonId = 'lesson_id';
  static const questionId = 'question_id';
  static const title = 'title';
  static const url = 'url';
  static const sourceLabel = 'source_label';
  static const displayOrder = 'display_order';
  static const isFree = 'is_free';
}

abstract final class SampleAnswerColumns {
  static const questionId = 'question_id';
  static const body = 'body';
}

abstract final class TextbookColumns {
  static const id = 'id';
  static const sheetKey = 'sheet_key';
  static const title = 'title';
  static const authors = 'authors';
  static const edition = 'edition';
}

abstract final class TextbookRefColumns {
  static const questionId = 'question_id';
  static const textbookId = 'textbook_id';
  static const page = 'page';
  static const sectionHeading = 'section_heading';
  static const textbookEmbed = 'textbook';
}

abstract final class AppearanceColumns {
  static const questionId = 'question_id';
  static const examPaperId = 'exam_paper_id';
  static const examPaperEmbed = 'exam_paper';
}

abstract final class ExamPaperColumns {
  static const id = 'id';
  static const examYear = 'exam_year';
  static const paperName = 'paper_name';
}

abstract final class TrackerColumns {
  static const id = 'id';
  static const ownerUserId = 'owner_user_id';
  static const universityId = 'university_id';
  static const kind = 'kind';
  static const title = 'title';
  static const startsOn = 'starts_on';
  static const endsOn = 'ends_on';
  static const isActive = 'is_active';
  static const createdAt = 'created_at';
}

abstract final class TrackerItemColumns {
  static const id = 'id';
  static const trackerId = 'tracker_id';
  static const lessonId = 'lesson_id';
  static const questionId = 'question_id';
  static const displayOrder = 'display_order';
}

abstract final class LessonBookmarkColumns {
  static const userId = 'user_id';
  static const lessonId = 'lesson_id';
  static const createdAt = 'created_at';

  /// PostgREST embed alias: `lesson:lessons(...)`.
  static const lessonEmbed = 'lesson';
}

abstract final class StudyEventParams {
  static const kind = 'p_kind';
  static const lessonId = 'p_lesson_id';
  static const questionId = 'p_question_id';
}

abstract final class MarkLearntParams {
  static const lessonId = 'p_lesson_id';
  static const questionId = 'p_question_id';
}

abstract final class TrackerCompletionParams {
  static const trackerId = 'p_tracker_id';
}

abstract final class SearchCatalogParams {
  static const query = 'p_query';
}


