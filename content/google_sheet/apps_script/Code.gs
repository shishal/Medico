/**
 * Phase 2.2 — Medico Google Sheet → Supabase sync
 *
 * Install: see README.md in this folder.
 * Secrets: Script Properties SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY only.
 */

var TAB = {
  SUBJECTS: 'Subjects',
  TOPICS: 'Topics',
  QUESTIONS: 'Questions',
  TESTS: 'Tests',
  TEST_QUESTIONS: 'TestQuestions',
  UNIVERSITIES: 'Universities',
  COLLEGES: 'Colleges',
  PHASES: 'Phases',
  LESSONS: 'Lessons',
  LESSON_RESOURCES: 'LessonResources',
  TEXTBOOKS: 'Textbooks',
  EXAM_PAPERS: 'ExamPapers',
  APPEARANCES: 'Appearances',
  TEXTBOOK_REFS: 'TextbookRefs',
  QUESTION_RESOURCES: 'QuestionResources',
};

var QUESTION_KINDS = { pyq_theory: true, mcq: true };
var PHASE_CODES = { phase1: true, phase2: true, phase3_part1: true, phase3_part2: true };
var EXAM_TYPES = { university: true, internal: true };

var PROP = {
  URL: 'SUPABASE_URL',
  KEY: 'SUPABASE_SERVICE_ROLE_KEY',
};

var PLANS = { free: true, pro: true, elite: true };
var DIFFICULTIES = { easy: true, medium: true, hard: true };
var TEST_TYPES = { mini: true, subject: true, mock: true, grand: true };
var CORRECT_OPTIONS = { A: true, B: true, C: true, D: true };

/**
 * Normalize for lookups: trim + lowercase.
 * Content teams often change capitalization; matching must not silently miss.
 */
function normKey_(value) {
  return String(value == null ? '' : value).trim().toLowerCase();
}

function trimStr_(value) {
  if (value == null) return '';
  return String(value).trim();
}

function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu('Medico')
    .addItem('Sync to App', 'syncToApp')
    .addItem('Check configuration', 'checkConfiguration')
    .addToUi();
}
