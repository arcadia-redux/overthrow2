"use strict";

function onClose() {
	$("#Leaderboard").visible = false;
}

function getTableRecord(record, parent, id) {
	let panel = $.CreatePanel("Panel", parent, id);
	panel.BLoadLayoutSnippet("TableRecord");

	panel.FindChildTraverse("Rank").text = record.rank;
	panel.FindChildTraverse("PlayerAvatar").steamid = record.steamId;
	panel.FindChildTraverse("PlayerUserName").steamid = record.steamId;
	panel.FindChildTraverse("Rating").text = record.rating;

	return panel;
}

function updateTable(players, mapname) {
	let body = $("#TableBody" + "_" + mapname);
	body.RemoveAndDeleteChildren();

	let localSteamId = Game.GetLocalPlayerInfo().player_steamid;
	players.forEach((player) => {
		let panel = getTableRecord(player, body);
		if (player.steamId == localSteamId) panel.AddClass("local");
	});
}

function attachMenuButton(panel) {
	let menu = GetDotaHud().FindChildTraverse("MenuButtons").FindChildTraverse("ButtonBar");
	let existingPanel = menu.FindChildTraverse(panel.id);

	if (existingPanel) existingPanel.DeleteAsync(0.1);

	panel.SetParent(menu);
}

function addMenuButton() {
	let button = $.CreatePanel("Button", $.GetContextPanel(), "OpenLeaderboard");
	button.SetPanelEvent("onactivate", () => {
		let panel = $("#Leaderboard");
		panel.visible = !panel.visible;
	});

	button.SetPanelEvent("onmouseover", () => {
		$.DispatchEvent("DOTAShowTextTooltip", button, "#leaderboard");
	});

	button.SetPanelEvent("onmouseout", () => {
		$.DispatchEvent("DOTAHideTextTooltip");
	});

	attachMenuButton(button);
}

function updateMapSelection(mapName) {
	$("#RatingsTable")
		.Children()
		.forEach((panel) => {
			panel.visible = false;
		});
	$("#TableBody_" + mapName).visible = true;
	$("#LeaderboardMapChoose").SetSelected(mapName + "_dropdown_option");
}

(function () {
	$("#Leaderboard").visible = false;
	addMenuButton();

	SubscribeToNetTableKey("game_state", "leaderboard", (leaderboardObj) => {
		let leaderboard = Object.values(leaderboardObj);
		if (leaderboard.length == 0) return;

		leaderboard.forEach((r, i) => (r.rank = i + 1));

		updateTable(leaderboard);
	});
})();
