"use strict";

var toggle = false
function OnPatreonButtonPressed() {
	var panel = $("#PatreonWindow");

	if (toggle == false) {
		toggle = true;
		panel.style.visibility = "collapse";
		return;
	}

	panel.style.visibility = "visible";
	toggle = false;
}

function ToggleEmblemDatabase() {
	$.AsyncWebRequest("db_url_endpoint", {
		type: "POST",
		data: {payload: JSON.stringify(payload)},
		success: function (data) {
			$.Msg("Reply: ", data)
			// change the stored value in db
			EnableEmblem();
		},
		error: function (data) {
			// check/uncheck the box again + send error message
		}
	});
}

function ToggleEmblem() {
	GameEvents.SendCustomGameEventToServer("toggle_emblem", {
		ID: Game.GetLocalPlayerID(),
		bEmblem: $("#EmblemEnableBox").checked
	});
}

function UpdateEmblem() {
	GameEvents.SendCustomGameEventToServer("update_emblem", {
		ID: Game.GetLocalPlayerID(),
		color: $("#ChooseColourDropDown").GetSelected().text
	});
}

(function() {
	if (Game.IsInToolsMode())
		$.Msg("Hello there")
})();
