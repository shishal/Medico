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

  var response = UrlFetchApp.fetch(endpoint, {
    method: 'post',
    contentType: 'application/json',
    headers: supabaseHeaders_(cfg.key, 'resolution=merge-duplicates,return=representation'),
    payload: JSON.stringify(rows),
    muteHttpExceptions: true,
  });

  var code = response.getResponseCode();
  var body = response.getContentText();
  if (code < 200 || code >= 300) {
    throw new Error('Supabase upsert ' + table + ' failed (' + code + '): ' + body);
  }
  return body ? JSON.parse(body) : [];
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
