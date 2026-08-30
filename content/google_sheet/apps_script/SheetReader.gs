/**
 * Sheet → array of row objects keyed by header names.
 * Row numbers are 1-based spreadsheet rows (header is row 1).
 */

/** Fill UG globals if Code.gs in the bound project is an older copy. */
function ensureUgGlobals_() {
  if (typeof PHASE_CODES === 'undefined') {
    PHASE_CODES = { phase1: true, phase2: true, phase3_part1: true, phase3_part2: true };
  }
  if (typeof EXAM_TYPES === 'undefined') {
    EXAM_TYPES = { university: true, internal: true };
  }
  if (typeof QUESTION_KINDS === 'undefined') {
    QUESTION_KINDS = { pyq_theory: true, mcq: true };
  }
  if (typeof TAB === 'undefined') {
    TAB = {};
  }
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

function sheetExists_(sheetName) {
  return SpreadsheetApp.getActiveSpreadsheet().getSheetByName(sheetName) != null;
}

function readTabObjects_(sheetName) {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sheet = ss.getSheetByName(sheetName);
  if (!sheet) {
    throw new Error('Missing tab "' + sheetName + '". Rename sheets to match content/google_sheet/tabs/.');
  }

  var values = sheet.getDataRange().getValues();
  if (!values.length) {
    return { headers: [], rows: [] };
  }

  var headers = values[0].map(function (h) {
    // Headers are matched case-insensitively so "Kind" still maps to row.kind.
    return trimStr_(h).toLowerCase();
  });

  var rows = [];
  for (var r = 1; r < values.length; r++) {
    var line = values[r];
    if (isBlankRow_(line)) continue;

    var obj = {};
    for (var c = 0; c < headers.length; c++) {
      if (!headers[c]) continue;
      obj[headers[c]] = line[c];
    }
    obj.__row = r + 1; // spreadsheet row number for error messages
    rows.push(obj);
  }

  return { headers: headers, rows: rows };
}

function isBlankRow_(line) {
  for (var i = 0; i < line.length; i++) {
    if (trimStr_(line[i]) !== '') return false;
  }
  return true;
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
