let patreonLevel = 0;
let patreonCurrentPerk;

function SetPlayerPatreonLevel(data) {
	patreonLevel = data.patreonLevel;
	patreonCurrentPerk = data.patreonCurrentPerk;
	CreatePatreonsGamePerks();
}

function HidePatreonsGamePerksHint() {
	let settingsButton = $("#SetPatreonGamePerkButton");
	$.DispatchEvent("DOTAHideTextTooltip", settingsButton);
	settingsButton.SetImage(
		"file://{resources}/layout/custom_game/common/patreon/game_perk/patreon_button_setting_no_glow.png",
	);
}

function ShowPatreonsGamePerksHint() {
	let settingsButton = $("#SetPatreonGamePerkButton");
	$.DispatchEvent("DOTAShowTextTooltip", settingsButton, $.Localize("#patreonperktooltip_hint"));
	settingsButton.SetImage(
		"file://{resources}/layout/custom_game/common/patreon/game_perk/patreon_button_setting_glow.png",
	);
}

function ShowPatreonsGamePerks() {
	let perksPanel = $("#PatreonsGamePerkMenu");
	let perksPanelClose = $("#ClosePatreonsPerks");
	perksPanel.visible = true;
	perksPanelClose.visible = true;
}

function HidePatreonsGamePerks() {
	let perksPanel = $("#PatreonsGamePerkMenu");
	let perksPanelClose = $("#ClosePatreonsPerks");
	if (perksPanel != null) {
		perksPanel.visible = false;
	}
	if (perksPanelClose != null) {
		perksPanelClose.visible = false;
	}
}

function ReloadSetttingButton() {
	let settingPerksButton = $("#SetPatreonGamePerkButton");

	settingPerksButton.SetImage(
		"file://{resources}/layout/custom_game/common/patreon/game_perk/patreon_button_setting_no_glow.png",
	);

	settingPerksButton.SetPanelEvent("onmouseover", function () {
		ShowPatreonsGamePerksHint();
	});
	settingPerksButton.SetPanelEvent("onmouseout", function () {
		HidePatreonsGamePerksHint();
	});
	settingPerksButton.SetPanelEvent("onactivate", function () {
		ShowPatreonsGamePerks();
	});
}

function SetPatreonsPerkButtonAction(panel, perkName) {
	panel.SetPanelEvent("onactivate", function () {
		patreonCurrentPerk = perkName;
		let settingPerksButton = $("#SetPatreonGamePerkButton");

		settingPerksButton.SetImage(
			"file://{resources}/layout/custom_game/common/patreon/game_perk/icons/" + perkName + ".png",
		);
		GameEvents.SendCustomGameEventToServer("set_patreon_game_perk", {
			newPerkName: perkName,
		});
		settingPerksButton.SetPanelEvent("onmouseover", function () {
			$.DispatchEvent("DOTAShowTextTooltip", settingPerksButton, $.Localize(perkName + "_tooltip"));
		});
		settingPerksButton.SetPanelEvent("onmouseout", function () {
			$.DispatchEvent("DOTAHideTextTooltip", settingPerksButton);
		});
		settingPerksButton.SetPanelEvent("onactivate", function () {});

		$("#PatreonsGamePerkMenu").DeleteAsync(0);
		$("#ClosePatreonsPerks").DeleteAsync(0);
	});

	panel.SetPanelEvent("onmouseover", function () {
		$.DispatchEvent("DOTAShowTextTooltip", panel, $.Localize(perkName + "_tooltip"));
	});
	panel.SetPanelEvent("onmouseout", function () {
		$.DispatchEvent("DOTAHideTextTooltip", panel);
	});
}

function UpdateBlockPatreonsPerk(panel, currectPatreonLevel) {
	panel.SetPanelEvent("onmouseover", function () {
		$.DispatchEvent(
			"DOTAShowTextTooltip",
			panel,
			$.Localize("#patreon_perks_list_error_tier_" + currectPatreonLevel),
		);
	});
	panel.SetPanelEvent("onmouseout", function () {
		$.DispatchEvent("DOTAHideTextTooltip", panel);
	});
}
function CreatePatreonsGamePerks() {
	for (let x = 0; x < patreons_levels; x++) {
		let tier = x;
		let patreonGamePerksTier = $.CreatePanel("Panel", $("#PatreonsGamePerksTierList"), "");
		patreonGamePerksTier.AddClass("PatreonGamePerksTier");

		let patreonGamePerksTierHeader = $.CreatePanel("Panel", patreonGamePerksTier, "");
		patreonGamePerksTierHeader.AddClass("PatreonGamePerksTierHeader");

		let patreonGamePerksTierHeaderText = $.CreatePanel("Label", patreonGamePerksTierHeader, "");
		patreonGamePerksTierHeaderText.AddClass("PatreonGamePerksTierHeaderTextMain");
		patreonGamePerksTierHeaderText.AddClass("PatreonGamePerksTierHeaderTextTier" + tier);
		patreonGamePerksTierHeaderText.text = $.Localize("#patreon_game_perk_tolltip_tier_" + tier);

		let perkPanelListForTier = $.CreatePanel("Panel", patreonGamePerksTier, "");
		perkPanelListForTier.AddClass("PerkPanelListForTier");

		for (let key in patreons_game_perks) {
			if (patreons_game_perks[key] == tier) {
				const perkPanel = $.CreatePanel("Panel", perkPanelListForTier, "");
				perkPanel.BLoadLayoutSnippet("GamePerk");
				const perkIconImage = perkPanel.FindChildTraverse("GamePerkImage");
				perkIconImage.SetImage(
					"file://{resources}/layout/custom_game/common/patreon/game_perk/icons/" + key + ".png",
				);
				perkIconImage.icon = key;

				const perkLabelText = perkPanel.FindChildTraverse("GamePerkText");
				perkLabelText.text = $.Localize(key);

				if (patreons_game_perks[key] == patreonLevel) {
					perkIconImage.AddClass("GamePerkImageHover");
					SetPatreonsPerkButtonAction(perkIconImage, key);
				} else {
					perkIconImage.AddClass("GamePerkImageNotAvailable");
					perkLabelText.AddClass("GamePerkTextNotAvailable");
					UpdateBlockPatreonsPerk(perkIconImage, patreons_game_perks[key]);
				}
			}
		}
		if (patreonCurrentPerk != null) {
			let settingPerksButton = $("#SetPatreonGamePerkButton");

			settingPerksButton.SetImage(
				"file://{resources}/layout/custom_game/common/patreon/game_perk/icons/" + patreonCurrentPerk + ".png",
			);
			settingPerksButton.SetPanelEvent("onmouseover", function () {
				$.DispatchEvent("DOTAShowTextTooltip", settingPerksButton, $.Localize(patreonCurrentPerk + "_tooltip"));
			});
			settingPerksButton.SetPanelEvent("onmouseout", function () {
				$.DispatchEvent("DOTAHideTextTooltip", settingPerksButton);
			});
			settingPerksButton.SetPanelEvent("onactivate", function () {});
			$("#PatreonsGamePerkMenu").DeleteAsync(0);
			$("#ClosePatreonsPerks").DeleteAsync(0);
		}
	}
	if (patreonCurrentPerk == null) {
		$.Schedule(3, function () {
			let perksPanel = $("#PatreonsGamePerkMenu");
			let perksPanelClose = $("#ClosePatreonsPerks");
			if (!perksPanel.visible) {
				perksPanel.visible = true;
				perksPanelClose.visible = true;
			}
		});
	}
}
function PatreonsGamePerkInit() {
	GameEvents.Subscribe("reload_patreon_perk_setings_button", ReloadSetttingButton);
	GameEvents.Subscribe("return_patreon_level_and_perks", SetPlayerPatreonLevel);
	GameEvents.SendCustomGameEventToServer("check_patreon_level_and_perks", {});
}
PatreonsGamePerkInit();
