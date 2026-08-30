/**
 * Sheet → array of row objects keyed by header names.
 * Row numbers are 1-based spreadsheet rows (header is row 1).
 */

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
    return trimStr_(h);
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
