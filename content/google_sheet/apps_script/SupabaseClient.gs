/** Minimal Supabase REST client for the transactional content RPC. */
function getSupabaseConfig_() {
  var props = PropertiesService.getScriptProperties();
  var url = trimStr_(props.getProperty(PROP.URL));
  var key = trimStr_(props.getProperty(PROP.KEY));
  if (!url || !key) {
    throw new Error(
      'Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in Apps Script properties.'
    );
  }
  if (url.slice(-1) === '/') url = url.slice(0, -1);
  return { url: url, key: key };
}

function supabaseRpc_(functionName, payload) {
  var cfg = getSupabaseConfig_();
  var response = UrlFetchApp.fetch(
    cfg.url + '/rest/v1/rpc/' + encodeURIComponent(functionName),
    {
      method: 'post',
      contentType: 'application/json',
      headers: {
        apikey: cfg.key,
        Authorization: 'Bearer ' + cfg.key,
      },
      payload: JSON.stringify(payload),
      muteHttpExceptions: true,
    }
  );
  var code = response.getResponseCode();
  var body = response.getContentText();
  if (code < 200 || code >= 300) {
    throw new Error(
      'Supabase RPC ' + functionName + ' failed (' + code + '): ' + body
    );
  }
  return body ? JSON.parse(body) : {};
}
