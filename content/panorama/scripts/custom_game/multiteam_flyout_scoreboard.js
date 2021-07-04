"use strict";
const MUTE_ALL_BUTTON = $("#MuteAll");
var g_ScoreboardHandle = null;

function SetFlyoutScoreboardVisible(bVisible) {
	$.GetContextPanel().SetHasClass("flyout_scoreboard_visible", bVisible);
	if (bVisible) {
		ScoreboardUpdater_SetScoreboardActive(g_ScoreboardHandle, true);
	} else {
		ScoreboardUpdater_SetScoreboardActive(g_ScoreboardHandle, false);
	}
}

const team_root = $("#TeamsContainer");
function MuteAll() {
	for (const player_id of Game.GetAllPlayerIDs()) {
		const player_panel = team_root.FindChildTraverse(`_dynamic_player_${player_id}`);
		if (MUTE_ALL_BUTTON.checked) {
			player_panel.SetHasClass("player_muted", true);
			Game.SetPlayerMuted(player_id, true);
		} else if (!player_panel.custom_mute) {
			player_panel.SetHasClass("player_muted", false);
			Game.SetPlayerMuted(player_id, false);
		}
	}
}

(function () {
	if (ScoreboardUpdater_InitializeScoreboard === null) {
		$.Msg("WARNING: This file requires shared_scoreboard_updater.js to be included.");
	}

	var scoreboardConfig = {
		teamXmlName: "file://{resources}/layout/custom_game/multiteam_flyout_scoreboard_team.xml",
		playerXmlName: "file://{resources}/layout/custom_game/multiteam_flyout_scoreboard_player.xml",
	};
	g_ScoreboardHandle = ScoreboardUpdater_InitializeScoreboard(scoreboardConfig, $("#TeamsContainer"));

	SetFlyoutScoreboardVisible(false);

	$.RegisterEventHandler("DOTACustomUI_SetFlyoutScoreboardVisible", $.GetContextPanel(), SetFlyoutScoreboardVisible);
})();
