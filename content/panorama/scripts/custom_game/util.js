var WEB_API_TESTING = Game.IsInToolsMode() && false;
var serverHost = WEB_API_TESTING ? 'http://127.0.0.1:5000' : 'http://163.172.174.77:8000';

function SendWebApiRequest(path, data, onSuccess, onError) {
  var settings = { type: 'POST', data: data };
  if (onSuccess != null) settings.success = onSuccess;
  if (onError != null) settings.error = onError;
  $.AsyncWebRequest(serverHost + '/api/vscripts/' + path, settings);
}

function SubscribeToNetTableKey(tableName, key, callback) {
  var immediateValue = CustomNetTables.GetTableValue(tableName, key) || {};
  callback(immediateValue || {});
	CustomNetTables.SubscribeNetTableListener(tableName, function(_tableName, currentKey, value) {
		if (currentKey === key) callback(value || {});
  });
}
