(function () {
	GameEvents.Subscribe("overthrow_item_choice", ShowPerkChoice);
})();

function ShowPerkChoice(keys) {
	for (var i = 1; i <= 4; i++) {
		let current_choice = $("#perk_choice_" + i);
		let current_string = `#${keys[i]}_tooltip`;
		current_choice.SetImage(`file://{resources}/layout/custom_game/common/game_perks/icons/${keys[i]}.png`);
		$("#perk_text_" + i).text = $.Localize("#" + keys[i]);

		if (i == 4) current_string = `#${keys[i]}_chest_tooltip`;

		current_choice.SetPanelEvent("onmouseover", function () {
			$.DispatchEvent("DOTAShowTextTooltip", current_choice, $.Localize(current_string));
		});

		current_choice.SetPanelEvent("onmouseout", function () {
			$.DispatchEvent("DOTAHideTextTooltip", current_choice);
		});
	}

	$("#perk_choice_container").style.visibility = "visible";

	// $.Schedule(0.03, TickItemTime);
}

function TickItemTime() {
	if ($("#perk_choice_container").style.visibility == "visible") {
		$("#remaining_time").value = $("#remaining_time").value - 1;

		if ($("#remaining_time").value <= 0) {
			MakeChoice(4);
		} else {
			$("#remaining_time").style.width = $("#remaining_time").value / 4.2 + "%";
			$.Schedule(0.03, TickItemTime);
		}
	}
}

function MakeChoice(slot) {
	var owner_index = Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer());

	GameEvents.SendCustomGameEventToServer("overthrow_item_choice_made", { owner_entindex: owner_index, slot: slot });

	$("#remaining_time").value = 420;
	$("#remaining_time").style.width = "100%";
	$("#perk_choice_container").style.visibility = "collapse";
}

// Utility functions
function FindDotaHudElement(id) {
	return GetDotaHud().FindChildTraverse(id);
}

function GetDotaHud() {
	var p = $.GetContextPanel();
	while (p !== null && p.id !== "Hud") {
		p = p.GetParent();
	}
	if (p === null) {
		throw new HudNotFoundException("Could not find Hud root as parent of panel with id: " + $.GetContextPanel().id);
	} else {
		return p;
	}
}
