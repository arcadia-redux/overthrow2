const LEADERBOARD = $("#Leaderboard");
const LOCAL_STEAM_ID = Game.GetLocalPlayerInfo().player_steamid;
const LOCAL_RATING_LABEL = $("#LocalPlayerRating");

let CHOOSED_MAP = Game.GetMapInfo().map_display_name;
let LOCAL_RATING_TABLE = {};
let UPDATED_TABLES = {};

function CloseLeaderboard() {
	LEADERBOARD.SetHasClass("Show", false);
}

function CreateLeaderboard(data) {
	UPDATED_TABLES[data.map_name] = true;
	const players_root = $("#TableBody" + "_" + data.map_name);
	players_root.RemoveAndDeleteChildren();

	Object.values(data.players_list).forEach((player, index) => {
		const panel = $.CreatePanel("Panel", players_root, "");
		panel.BLoadLayoutSnippet("LeaderboardPlayer");

		const rank = index + 1;
		if (rank <= 3) panel.AddClass(`top${rank}`);
		panel.SetHasClass("dark", index % 2 == 1);
		panel.FindChildTraverse("RankIndex").text = rank;
		panel.FindChildTraverse("PlayerAvatar").steamid = player.steamId;
		panel.FindChildTraverse("PlayerUserName").steamid = player.steamId;
		panel.FindChildTraverse("Rating").text = player.rating;

		if (player.steamId == LOCAL_STEAM_ID) panel.AddClass("local");
	});
	UpdateMapSelection(CHOOSED_MAP);
}

function UpdateMapSelection(map_name) {
	if (UPDATED_TABLES[map_name] == undefined) {
		GameEvents.SendCustomGameEventToServer("leaderboard:get_leaderboard", {
			map_name: map_name,
		});
	}
	$("#LeaderboardDataWrap")
		.Children()
		.forEach((panel) => {
			panel.visible = false;
		});
	$("#TableBody_" + map_name).visible = true;
	$("#LeaderboardMapChoose").SetSelected(map_name + "_dropdown_option");

	CHOOSED_MAP = map_name;
	LOCAL_RATING_LABEL.text = 1500;

	if (LOCAL_RATING_TABLE[map_name]) LOCAL_RATING_LABEL.text = LOCAL_RATING_TABLE[map_name];
}

(function () {
	const leaderboard_button = _AddMenuButton("OpenLeaderboard");
	CreateButtonInTopMenu(
		leaderboard_button,
		() => {
			LEADERBOARD.ToggleClass("Show");
		},
		() => {
			$.DispatchEvent("DOTAShowTextTooltip", leaderboard_button, "#leaderboard");
		},
		() => {
			$.DispatchEvent("DOTAHideTextTooltip");
		},
	);

	SubscribeToNetTableKey("game_state", "player_ratings", (player_stats) => {
		const local_rating = player_stats[Game.GetLocalPlayerID().toString()];
		if (local_rating) LOCAL_RATING_TABLE = local_rating;
		if (LOCAL_RATING_TABLE[CHOOSED_MAP]) LOCAL_RATING_LABEL.text = LOCAL_RATING_TABLE[CHOOSED_MAP];
	});
	GameEvents.Subscribe("leaderboard:create_table", CreateLeaderboard);
	GameEvents.SendCustomGameEventToServer("leaderboard:get_leaderboard", {
		map_name: CHOOSED_MAP,
	});
})();
