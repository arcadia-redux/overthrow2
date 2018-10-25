function GetSteamID32() {
    var playerInfo = Game.GetPlayerInfo(Game.GetLocalPlayerID());

    var steamID64 = playerInfo.player_steamid,
        steamIDPart = Number(steamID64.substring(3)),
        steamID32 = String(steamIDPart - 61197960265728);

    return steamID32;
}

GameEvents.Subscribe("statcollection_client", function OnClientCheckIn(args) {
    var playerInfo = Game.GetLocalPlayerInfo();
    var hostInfo = 0
    if (playerInfo) hostInfo = playerInfo.player_has_host_privileges

    var payload = {
        modIdentifier: args.modID,
        steamID32: GetSteamID32(),
        isHost: hostInfo,
        matchID: args.matchID,
        schemaVersion: args.schemaVersion
    };

    $.AsyncWebRequest('https://api.getdotastats.com/s2_check_in.php',
        {
            type: 'POST',
            data: { payload: JSON.stringify(payload) },
            success: function (data) {
                $.Msg('GDS Reply: ', data)
            }
        });
});
