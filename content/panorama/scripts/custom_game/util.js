function setInterval(callback, interval) {
	interval = interval / 1000;
	$.Schedule(interval, function reschedule() {
		$.Schedule(interval, reschedule);
		callback();
	});
}

function createEventRequestCreator(eventName) {
	var idCounter = 0;
	return function(data, callback) {
		var id = ++idCounter;
		data.id = id;
		GameEvents.SendCustomGameEventToServer(eventName, data);
		var listener = GameEvents.Subscribe(eventName, function(data) {
			if (data.id !== id) return;
			GameEvents.Unsubscribe(listener);
			callback(data)
		});

		return listener;
	}
}

function SubscribeToNetTableKey(tableName, key, callback) {
    var immediateValue = CustomNetTables.GetTableValue(tableName, key) || {};
    if (immediateValue != null) callback(immediateValue);
    CustomNetTables.SubscribeNetTableListener(tableName, function (_tableName, currentKey, value) {
        if (currentKey === key && value != null) callback(value);
    });
}

function GetDotaHud() {
    var p = $.GetContextPanel();
    while (p !== null && p.id !== 'Hud') {
        p = p.GetParent();
    }
    if (p === null) {
        throw new HudNotFoundException('Could not find Hud root as parent of panel with id: ' + $.GetContextPanel().id);
    } else {
        return p;
    }
}

function FindDotaHudElement(id) {
    return GetDotaHud().FindChildTraverse(id);
}

function FillTopBarPlayer(TeamContainer) {
    // Fill players top bar in case on partial lobbies
    var playerCount = TeamContainer.GetChildCount();
    for (var i = playerCount + 1; i <= 12; i++) {
        var newPlayer = $.CreatePanel('DOTATopBarPlayer', TeamContainer, 'RadiantPlayer-1');
        if (newPlayer) {
            newPlayer.FindChildTraverse('PlayerColor').style.backgroundColor = '#FFFFFFFF';
        }
        newPlayer.SetHasClass('EnemyTeam', true);
    }
}
