/**
 * Supabase REST (PostgREST) helpers. Uses service_role from Script Properties.
 * Never log or dialog the key.
 */

function getSupabaseConfig_() {
  var props = PropertiesService.getScriptProperties();
  var url = trimStr_(props.getProperty(PROP.URL));
  var key = trimStr_(props.getProperty(PROP.KEY));
  if (!url || !key) {
    throw new Error(
      'Missing Script Properties. Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY (File → Project properties → Script properties).'
    );
  }
  // Strip trailing slash so path joins are predictable.
  if (url.slice(-1) === '/') url = url.slice(0, -1);
  return { url: url, key: key };
}

function supabaseHeaders_(key, prefer) {
  var headers = {
    apikey: key,
    Authorization: 'Bearer ' + key,
    'Content-Type': 'application/json',
  };
  if (prefer) headers.Prefer = prefer;
  return headers;
}

/**
 * Columns the Flutter app / DB can live without. If PostgREST 400s with
 * PGRST204 (schema cache missing that column), drop it and retry the upsert
 * so a live project that has not applied a later migration still syncs.
 */
var OPTIONAL_UPSERT_COLUMNS = {
  is_fallback: true,
};

function missingColumnFromPgrst_(body) {
  var m = String(body || '').match(/Could not find the '([^']+)' column/);
  return m ? m[1] : '';
}

function stripColumn_(rows, column) {
  return rows.map(function (row) {
    var copy = {};
    Object.keys(row).forEach(function (k) {
      if (k !== column) copy[k] = row[k];
    });
    return copy;
  });
}

/**
 * Upsert rows. onConflict is the PostgREST on_conflict query value
 * (comma-separated column names matching a UNIQUE constraint / index).
 */
function supabaseUpsert_(table, rows, onConflict) {
  if (!rows || !rows.length) return [];

  var cfg = getSupabaseConfig_();
  var endpoint =
    cfg.url +
    '/rest/v1/' +
    encodeURIComponent(table) +
    '?on_conflict=' +
    encodeURIComponent(onConflict);

  var payload = rows;
  var lastCode = 0;
  var lastBody = '';
  var attempt;
  for (attempt = 0; attempt < 6; attempt++) {
    var response = UrlFetchApp.fetch(endpoint, {
      method: 'post',
      contentType: 'application/json',
      headers: supabaseHeaders_(
        cfg.key,
        'resolution=merge-duplicates,return=representation'
      ),
      payload: JSON.stringify(payload),
      muteHttpExceptions: true,
    });
    lastCode = response.getResponseCode();
    lastBody = response.getContentText();
    if (lastCode >= 200 && lastCode < 300) {
      return lastBody ? JSON.parse(lastBody) : [];
    }
    var missing = lastCode === 400 ? missingColumnFromPgrst_(lastBody) : '';
    if (!missing || !OPTIONAL_UPSERT_COLUMNS[missing]) break;
    payload = stripColumn_(payload, missing);
  }

  throw new Error(
    'Supabase upsert ' + table + ' failed (' + lastCode + '): ' + lastBody
  );
}

function supabaseDeleteEq_(table, column, value) {
  var cfg = getSupabaseConfig_();
  var endpoint =
    cfg.url +
    '/rest/v1/' +
    encodeURIComponent(table) +
    '?' +
    encodeURIComponent(column) +
    '=eq.' +
    encodeURIComponent(value);

  var response = UrlFetchApp.fetch(endpoint, {
    method: 'delete',
    headers: supabaseHeaders_(cfg.key, 'return=minimal'),
    muteHttpExceptions: true,
  });

  var code = response.getResponseCode();
  if (code < 200 || code >= 300) {
    throw new Error(
      'Supabase delete ' + table + ' failed (' + code + '): ' + response.getContentText()
    );
  }
}

function supabaseInsert_(table, rows) {
  if (!rows || !rows.length) return [];

  var cfg = getSupabaseConfig_();
  var endpoint = cfg.url + '/rest/v1/' + encodeURIComponent(table);

  var response = UrlFetchApp.fetch(endpoint, {
    method: 'post',
    contentType: 'application/json',
    headers: supabaseHeaders_(cfg.key, 'return=representation'),
    payload: JSON.stringify(rows),
    muteHttpExceptions: true,
  });

  var code = response.getResponseCode();
  var body = response.getContentText();
  if (code < 200 || code >= 300) {
    throw new Error('Supabase insert ' + table + ' failed (' + code + '): ' + body);
  }
  return body ? JSON.parse(body) : [];
}

/**
 * Select rows (service_role). Used only if needed for debugging / future.
 */
function supabaseSelect_(table, query) {
  var cfg = getSupabaseConfig_();
  var endpoint = cfg.url + '/rest/v1/' + encodeURIComponent(table) + (query || '');
  var response = UrlFetchApp.fetch(endpoint, {
    method: 'get',
    headers: supabaseHeaders_(cfg.key),
    muteHttpExceptions: true,
  });
  var code = response.getResponseCode();
  var body = response.getContentText();
  if (code < 200 || code >= 300) {
    throw new Error('Supabase select ' + table + ' failed (' + code + '): ' + body);
  }
  return body ? JSON.parse(body) : [];
}
