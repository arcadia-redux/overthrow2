//"use strict";

var isPatreon = false;
var toggle = false;

function OnPatreonButtonPressed() {
	var panel = $("#PatreonWindow");

	if (toggle == false) {
		toggle = true;
		panel.visible = true;
	}
	else
	{
		panel.visible = false;
		toggle = false;
	}
}

//function ToggleEmblemDatabase() {
//	$.AsyncWebRequest("db_url_endpoint", {
//		type: "POST",
//		data: {payload: JSON.stringify(payload)},
//		success: function (data) {
//			$.Msg("Reply: ", data)
//			// change the stored value in db
//			EnableEmblem();
//		},
//		error: function (data) {
//			// check/uncheck the box again + send error message
//		}
//	});
//}

function ToggleEmblem() {
	if ($('#SupporterEmblemEnableDisable').checked == true)
	{
		if (isPatreon)
		{
			GameEvents.SendCustomGameEventToServer("toggle_emblem", {ID: Game.GetLocalPlayerID(),bEmblem: $("#SupporterEmblemEnableDisable").checked});
		}
		else
		{
			$.DispatchEvent('ExternalBrowserGoToURL', 'https://www.patreon.com/dota2unofficial')
			$('#SupporterEmblemEnableDisable').checked = false;
		}
	}
}

function BootsEnableToggle() {
	if ($('#FreeBootsEnableDisable').checked == true)
	{
		if (isPatreon)
		{
			//GameEvents.SendCustomGameEventToServer("toggle_emblem", {ID: Game.GetLocalPlayerID(),bEmblem: $("#FreeBootsEnableDisable").checked});
		}
		else
		{
			$.DispatchEvent('ExternalBrowserGoToURL', 'https://www.patreon.com/dota2unofficial')
			$('#FreeBootsEnableDisable').checked = false;
		}
	}
}

function OnColourPressed(text) {
	if (isPatreon)
	{
		GameEvents.SendCustomGameEventToServer("update_emblem", {ID: Game.GetLocalPlayerID(),color: text});
	}
	else
	{
		$.DispatchEvent('ExternalBrowserGoToURL', 'https://www.patreon.com/dota2unofficial')
	}
}

(function() {
	GameEvents.Subscribe("MinimizePB", function(){
		$("#PatreonButton").visible = false;
		$("#PatreonButtonSmaller").visible = true;
	})
	$("#PatreonWindow").visible = false;
	$("#PatreonButtonSmaller").visible = false;
	$("#PatreonButton").visible = true;
	var patreonBonuses = CustomNetTables.GetTableValue("game_state", "player_stats");
	var localStats = patreonBonuses[Game.GetLocalPlayerID()];
	isPatreon = Boolean(localStats && localStats.patreonLevel);

	SubscribeToNetTableKey('game_state', 'player_stats', function(value) {
		var localStats = value[Game.GetLocalPlayerID()];
		isPatreon = Boolean(localStats && localStats.patreonLevel);
	});
})();
