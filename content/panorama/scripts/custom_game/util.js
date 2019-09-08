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
