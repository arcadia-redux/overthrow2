function CloseWarning(panelName) {
	$("#" + panelName).SetHasClass("hide", true);
}
function ScheludeCloseWarning(time, panelName) {
	$.Schedule(time, () => {
		CloseWarning(panelName);
	});
}
function HidePatreonNotification(data) {
	$("#WarningIngame_patreonSteamIDS").SetHasClass("hide", data.boosterStatus < 1);
}
(function () {
	ScheludeCloseWarning(60, "WarningIngame_server");
	ScheludeCloseWarning(60, "WarningIngame_patreonSteamIDS");
	GameEvents.Subscribe("battlepass_inventory:update_player_info", HidePatreonNotification);
})();
