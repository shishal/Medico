/**
 * Sheet → array of row objects keyed by header names.
 * Row numbers are 1-based spreadsheet rows (header is row 1).
 */

/** Fill UG globals if Code.gs in the bound project is an older copy. */
function ensureUgGlobals_() {
  if (typeof PHASE_CODES === 'undefined') {
    PHASE_CODES = { year1: true, year2: true, year3: true, year4: true };
  }
  PHASE_CODES.year1 = true;
  PHASE_CODES.year2 = true;
  PHASE_CODES.year3 = true;
  PHASE_CODES.year4 = true;
  if (typeof EXAM_TYPES === 'undefined') {
    EXAM_TYPES = { university: true, internal: true };
  }
  if (typeof QUESTION_KINDS === 'undefined') {
    QUESTION_KINDS = { pyq_theory: true, mcq: true };
  }
  if (typeof QUESTION_FIELD_DEFAULTS === 'undefined') {
    QUESTION_FIELD_DEFAULTS = {
      difficulty: 'medium',
      required_plan: 'free',
      exam_type: 'university',
    };
  }
  if (typeof TAB === 'undefined') {
    TAB = {};
  }
  TAB.SUBJECTS = TAB.SUBJECTS || 'Subjects';
  TAB.TOPICS = TAB.TOPICS || 'Topics';
  TAB.QUESTIONS = TAB.QUESTIONS || 'Questions';
  TAB.TESTS = TAB.TESTS || 'Tests';
  TAB.TEST_QUESTIONS = TAB.TEST_QUESTIONS || 'TestQuestions';
  TAB.UNIVERSITIES = TAB.UNIVERSITIES || 'Universities';
  TAB.COLLEGES = TAB.COLLEGES || 'Colleges';
  TAB.PHASES = TAB.PHASES || 'Phases';
  TAB.LESSONS = TAB.LESSONS || 'Lessons';
  TAB.LESSON_RESOURCES = TAB.LESSON_RESOURCES || 'LessonResources';
  TAB.TEXTBOOKS = TAB.TEXTBOOKS || 'Textbooks';
  TAB.EXAM_PAPERS = TAB.EXAM_PAPERS || 'ExamPapers';
  TAB.APPEARANCES = TAB.APPEARANCES || 'Appearances';
  TAB.TEXTBOOK_REFS = TAB.TEXTBOOK_REFS || 'TextbookRefs';
  TAB.QUESTION_RESOURCES = TAB.QUESTION_RESOURCES || 'QuestionResources';
}

function headerKey_(h) {
  // CSV BOM, Title Case, "University Code", or kind(Default-MCQ) still
  // match university_code / kind.
  return trimStr_(h)
    .replace(/^\uFEFF/, '')
    .replace(/\s*\([^)]*default[^)]*\)/i, '')
    .toLowerCase()
    .replace(/[\s-]+/g, '_');
}

/** First non-empty cell among header aliases (already headerKey_'d). */
function rowField_(row, names) {
  if (typeof names === 'string') names = [names];
  for (var i = 0; i < names.length; i++) {
    var s = trimStr_(row[names[i]]);
    if (s) return s;
  }
  return '';
}

function sheetExists_(sheetName) {
  return SpreadsheetApp.getActiveSpreadsheet().getSheetByName(sheetName) != null;
}

var RETIRED_TABS = {
  Subjects: true,
  Topics: true,
  Lessons: true,
  ExamPapers: true,
  Appearances: true,
  TextbookRefs: true,
  QuestionResources: true,
  Tests: true,
  TestQuestions: true,
};

function readTabObjects_(sheetName) {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sheet = ss.getSheetByName(sheetName);
  if (!sheet) {
    if (RETIRED_TABS[sheetName]) {
      throw new Error(
        'Missing tab "' +
          sheetName +
          '". That tab is retired — subjects/topics/lessons come from the Questions tab. ' +
          'Update Apps Script from content/google_sheet/apps_script/ (especially Validate.gs) and Sync again.'
      );
    }
    throw new Error(
      'Missing tab "' +
        sheetName +
        '". Rename sheets to match content/google_sheet/tabs/ ' +
        '(Universities, Colleges, Phases, Textbooks, Questions, optional LessonResources).'
    );
  }

  var values = sheet.getDataRange().getValues();
  if (!values.length) {
    return { headers: [], rows: [], defaults: {} };
  }

  var displays = sheet.getDataRange().getDisplayValues();
  var rawHeaders = values[0];
  var headers = rawHeaders.map(headerKey_);
  var defaults = {};
  for (var c = 0; c < rawHeaders.length; c++) {
    if (!headers[c]) continue;
    var headerDefault = headerDefaultValue_(rawHeaders[c]);
    if (headerDefault) defaults[headers[c]] = headerDefault;
  }

  var rows = [];
  for (var r = 1; r < values.length; r++) {
    var line = values[r];
    if (isBlankRow_(line)) continue;

    var obj = {};
    var shown = displays[r] || [];
    for (var c = 0; c < headers.length; c++) {
      if (!headers[c]) continue;
      // A dropdown can keep the first item (easy) after the cell looks blank.
      obj[headers[c]] = trimStr_(shown[c]) === '' ? '' : line[c];
    }
    obj.__row = r + 1; // spreadsheet row number for error messages
    rows.push(obj);
  }

  return { headers: headers, rows: rows, defaults: defaults };
}

/** `difficulty(Default-medium)` → `medium`. */
function headerDefaultValue_(rawHeader) {
  var m = String(rawHeader || '').match(/\(\s*default\s*[-:]\s*([^)]+?)\)/i);
  return m ? trimStr_(m[1]) : '';
}

/**
 * Blank → fallback. Non-blank must be in `allowed` (lowercased).
 * Returns null when the cell has a value that is not allowed.
 */
function enumOrDefault_(raw, allowed, fallback) {
  var s = trimStr_(raw).toLowerCase();
  if (!s) return fallback;
  if (allowed[s]) return s;
  return null;
}

function tabDefault_(tabRaw, key, hardcoded) {
  var fromHeader = tabRaw && tabRaw.defaults && tabRaw.defaults[key];
  if (!fromHeader) return hardcoded;
  return trimStr_(fromHeader).toLowerCase() || hardcoded;
}

function cellIsEmpty_(v) {
  if (v == null || v === '') return true;
  // Extra formatted rows often have leftover checkboxes / numeric 0s.
  if (v === false) return true;
  if (typeof v === 'number' && v === 0) return true;
  return trimStr_(v) === '';
}

function isBlankRow_(line) {
  for (var i = 0; i < line.length; i++) {
    if (!cellIsEmpty_(line[i])) return false;
  }
  return true;
}

/** KUHS, MUHS — not a college name pasted into university_code. */
function looksLikeUniversityCode_(raw) {
  return /^[A-Za-z0-9]{2,16}$/.test(trimStr_(raw));
}

function looksLikeQuestionExternalId_(raw) {
  var s = trimStr_(raw);
  return /^[A-Za-z0-9][A-Za-z0-9._-]{1,78}$/.test(s);
}

function looksLikeLessonExternalId_(raw) {
  return /^L-[A-Za-z0-9][A-Za-z0-9_-]{2,}$/.test(trimStr_(raw));
}

function looksLikeUrl_(raw) {
  return /^(https?:\/\/|www\.)/i.test(trimStr_(raw));
}

function coerceHttpsUrl_(raw) {
  var url = trimStr_(raw);
  if (!url) return '';
  if (url.indexOf('https://') === 0) return url;
  if (url.indexOf('http://') === 0) return 'https://' + url.substring(7);
  if (/^www\./i.test(url)) return 'https://' + url;
  return '';
}

/**
 * Match Universities.code, or the university name if someone pasted that instead.
 */
function resolveUniversityCode_(raw, uniByCode, universities) {
  var s = trimStr_(raw);
  if (!s) return '';
  if (uniByCode[normKey_(s)]) return uniByCode[normKey_(s)];
  if (uniByCode[normKey_(s.toUpperCase())]) return uniByCode[normKey_(s.toUpperCase())];
  for (var i = 0; i < universities.length; i++) {
    if (normKey_(universities[i].name) === normKey_(s)) return universities[i].code;
  }
  return '';
}

/** TB-DHINGRA-8 can share title/authors with TB-DHINGRA-7 when the 8th row is missing. */
function siblingTextbookPrefix_(key) {
  return normKey_(key).replace(/-\d+$/, '');
}

function ensureTextbookKey_(tbKey, tbByKey, textbooks) {
  var k = normKey_(tbKey);
  if (!k) return '';
  if (tbByKey[k]) return tbByKey[k];
  var prefix = siblingTextbookPrefix_(tbKey);
  if (!prefix || prefix === k) return '';
  for (var i = 0; i < textbooks.length; i++) {
    var existing = textbooks[i];
    if (siblingTextbookPrefix_(existing.sheet_key) !== prefix) continue;
    var editionNum = String(tbKey).match(/-(\d+)$/);
    textbooks.push({
      sheet_key: tbKey,
      title: existing.title,
      authors: existing.authors,
      edition: editionNum ? editionNum[1] + 'th' : existing.edition,
    });
    tbByKey[k] = tbKey;
    return tbKey;
  }
  return '';
}

/**
 * New headers: subject/topic/lesson/title/url.
 * Leftover old rows: lesson_external_id/title/url sitting in those first columns.
 */
function normalizeLessonResourceRow_(row) {
  var subjectName = trimStr_(row.subject_name);
  var topicName = trimStr_(row.topic_name);
  var lessonName = trimStr_(row.lesson_name);
  var title = trimStr_(row.title);
  var url = coerceHttpsUrl_(row.url);
  if (looksLikeLessonExternalId_(subjectName) && looksLikeUrl_(lessonName) && !url) {
    return {
      lessonExt: subjectName,
      title: topicName || title,
      url: coerceHttpsUrl_(lessonName),
      source_label: optionalTrimmed_(title),
      display_order: row.url,
      is_free: row.source_label,
      shifted: true,
    };
  }
  var lessonExt = '';
  if (subjectName && topicName && lessonName) {
    lessonExt = inventLessonExternalId_(subjectName, topicName, lessonName);
  } else if (trimStr_(row.lesson_external_id)) {
    lessonExt = trimStr_(row.lesson_external_id);
  } else if (looksLikeLessonExternalId_(subjectName)) {
    lessonExt = subjectName;
  }
  return {
    lessonExt: lessonExt,
    title: title,
    url: url,
    source_label: optionalTrimmed_(row.source_label),
    display_order: row.display_order,
    is_free: row.is_free,
    shifted: false,
  };
}

function requireHeaders_(tabName, headers, required) {
  var missing = [];
  var set = {};
  headers.forEach(function (h) {
    set[h] = true;
  });
  required.forEach(function (h) {
    if (!set[h]) missing.push(h);
  });
  if (missing.length) {
    return tabName + ': missing column(s) ' + missing.join(', ');
  }
  return null;
}

function parseBool_(raw, tab, row, field, errors) {
  if (typeof raw === 'boolean') return raw;
  var s = trimStr_(raw).toUpperCase();
  if (s === 'TRUE' || s === 'YES' || s === '1') return true;
  if (s === 'FALSE' || s === 'NO' || s === '0') return false;
  errors.push(tab + ' row ' + row + ': ' + field + ' must be TRUE or FALSE');
  return null;
}

/** Blank cell → defaultValue. Checkboxes and TRUE/FALSE still validate. */
function parseOptionalBool_(raw, tab, row, field, errors, defaultValue) {
  if (typeof raw === 'boolean') return raw;
  if (raw === '' || raw == null) return defaultValue;
  return parseBool_(raw, tab, row, field, errors);
}

/** URL slug for universities — lowercased `code`. Not a sheet column. */
function universitySlugFromCode_(code) {
  return String(code || '').toLowerCase();
}

/** year1–year4. Old sheet values phase1 / phase3_part1 still map. */
function canonicalPhaseCode_(raw) {
  var s = trimStr_(raw).toLowerCase();
  if (s === 'phase1') return 'year1';
  if (s === 'phase2') return 'year2';
  if (s === 'phase3_part1') return 'year3';
  if (s === 'phase3_part2') return 'year4';
  return s;
}

/**
 * Universities tab: code, name, state required. slug is lowercased code.
 */
function universityFromSheetRow_(row, errors) {
  var code = trimStr_(row.code).toUpperCase();
  var name = trimStr_(row.name);
  var state = trimStr_(row.state);
  if (!code || !name || !state) {
    errors.push(
      TAB.UNIVERSITIES +
        ' row ' +
        row.__row +
        ': code, name, and state are required'
    );
    return null;
  }
  return {
    code: code,
    name: name,
    state: state,
    slug: universitySlugFromCode_(code),
  };
}

/** Stable lesson upsert key from names — keep in sync with generate_ug_seed_csvs.py. */
function inventLessonExternalId_(subjectName, topicName, lessonName) {
  function token(s) {
    return normKey_(s)
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-|-$/g, '')
      .toUpperCase();
  }
  return ('L-' + token(subjectName) + '-' + token(topicName) + '-' + token(lessonName)).substring(0, 80);
}

/**
 * LessonResources: derive L-SUBJECT-TOPIC-LESSON from names.
 * An old lesson_external_id column still works if names are blank.
 */
function lessonResourceExternalId_(row, errors) {
  var subjectName = trimStr_(row.subject_name);
  var topicName = trimStr_(row.topic_name);
  var lessonName = trimStr_(row.lesson_name);
  if (subjectName && topicName && lessonName) {
    return inventLessonExternalId_(subjectName, topicName, lessonName);
  }
  var ext = trimStr_(row.lesson_external_id);
  if (ext) return ext;
  errors.push(
    TAB.LESSON_RESOURCES +
      ' row ' +
      row.__row +
      ': subject_name, topic_name, and lesson_name are required'
  );
  return '';
}

function parseOptionalInt_(raw, defaultValue) {
  if (raw === '' || raw == null) return defaultValue;
  var n = typeof raw === 'number' ? raw : Number(trimStr_(raw));
  if (!isFinite(n) || Math.floor(n) !== n) return defaultValue;
  return n;
}

function parseIntRequired_(raw, tab, row, field, errors) {
  if (raw === '' || raw == null) {
    errors.push(tab + ' row ' + row + ': ' + field + ' is required');
    return null;
  }
  var n = typeof raw === 'number' ? raw : Number(trimStr_(raw));
  if (!isFinite(n) || Math.floor(n) !== n) {
    errors.push(tab + ' row ' + row + ': ' + field + ' must be an integer');
    return null;
  }
  return n;
}

function parseNumberRequired_(raw, tab, row, field, errors) {
  if (raw === '' || raw == null) {
    errors.push(tab + ' row ' + row + ': ' + field + ' is required');
    return null;
  }
  var n = typeof raw === 'number' ? raw : Number(trimStr_(raw));
  if (!isFinite(n)) {
    errors.push(tab + ' row ' + row + ': ' + field + ' must be a number');
    return null;
  }
  return n;
}

function optionalTrimmed_(raw) {
  var s = trimStr_(raw);
  return s === '' ? null : s;
}

function emptyToNull_(value) {
  if (value === '' || value == null) return null;
  return value;
}
