let patreon_level = 0;
let current_perk;
const SETTINGS_BUTTON = $("#SetGamePerkButton");
const ROOT = $.GetContextPanel();

const PERK_MENU = $("#GamePerksMenu");
const CLOSE_PERK_MENU = $("#CloseGamePerks");

function SetPlayerPatreonLevel(data) {
	patreon_level = data.patreon_level;
	current_perk = data.current_perk;
	CreateGamePerks();
}

function ShowGamePerks() {
	ROOT.SetHasClass("Show", true);
}

function HideGamePerks() {
	ROOT.SetHasClass("Show", false);
}

function ReloadSettingButton() {
	SETTINGS_BUTTON.style.backgroundImage =
		"url('file://{resources}/layout/custom_game/common/game_perks/perk_button_plus_off.png')";

	SETTINGS_BUTTON.SetPanelEvent("onmouseover", function () {
		$.DispatchEvent("DOTAShowTextTooltip", SETTINGS_BUTTON, $.Localize("#game_perk_choose_hint"));
	});
	SETTINGS_BUTTON.SetPanelEvent("onactivate", function () {
		ShowGamePerks();
	});
}

function SetGamePerkButtonAction(panel, perk_name) {
	panel.SetPanelEvent("onactivate", function () {
		current_perk = perk_name;
		SETTINGS_BUTTON.style.backgroundImage = `url('file://{resources}/layout/custom_game/common/game_perks/icons/${perk_name}.png')`;

		GameEvents.SendCustomGameEventToServer("game_perks:set_perk", {
			newPerkName: perk_name,
		});
		SETTINGS_BUTTON.SetPanelEvent("onmouseover", function () {
			$.DispatchEvent("DOTAShowTextTooltip", SETTINGS_BUTTON, $.Localize(`${perk_name}_tooltip`));
		});
		SETTINGS_BUTTON.ClearPanelEvent(`onactivate`);

		HideGamePerks();
		PERK_MENU.DeleteAsync(0);
		CLOSE_PERK_MENU.DeleteAsync(0);
	});

	panel.SetPanelEvent("onmouseover", function () {
		$.DispatchEvent("DOTAShowTextTooltip", panel, $.Localize(perk_name + "_tooltip"));
	});
	panel.SetPanelEvent("onmouseout", function () {
		$.DispatchEvent("DOTAHideTextTooltip", panel);
	});
}

function UpdateBlockGamePerk(panel, current_patreon_level) {
	panel.SetPanelEvent("onmouseover", function () {
		$.DispatchEvent(
			"DOTAShowTextTooltip",
			panel,
			$.Localize("#patreon_perks_list_error_tier_" + current_patreon_level),
		);
	});
	panel.SetPanelEvent("onmouseout", function () {
		$.DispatchEvent("DOTAHideTextTooltip", panel);
	});
}

const TIERS_ROOT = $("#GamePerksTierList");
function CreateGamePerks() {
	TIERS_ROOT.RemoveAndDeleteChildren();
	for (let tier = 0; tier < perks_levels; tier++) {
		const tier_root = $.CreatePanel("Panel", TIERS_ROOT, "");
		tier_root.BLoadLayoutSnippet("GamePerksTier");

		const header = tier_root.FindChildTraverse("GamePerksTierHeaderTextMain");
		header.AddClass(`GamePerksTier${tier}`);
		header.text = $.Localize("#game_perk_tolltip_tier_" + tier);

		const perks_root = tier_root.FindChildTraverse("PerksRoot");

		game_perks.forEach((perk_name) => {
			const perk_panel = $.CreatePanel("Panel", perks_root, "");
			perk_panel.BLoadLayoutSnippet("GamePerk");

			const perk_icon = perk_panel.FindChildTraverse("GamePerkImage");

			const full_name = `${perk_name}_t${tier}`;
			perk_icon.SetImage(`file://{resources}/layout/custom_game/common/game_perks/icons/${full_name}.png`);
			perk_icon.icon = full_name;

			const perk_label = perk_panel.FindChildTraverse("GamePerkText");
			perk_label.text = $.Localize(full_name);

			if (tier == patreon_level) {
				perk_icon.AddClass("GamePerkImageHover");
				SetGamePerkButtonAction(perk_icon, full_name);
			} else {
				perk_panel.AddClass("GamePerkNotAvailable");
				UpdateBlockGamePerk(perk_icon, tier);
			}

			if (current_perk != null) {
				SETTINGS_BUTTON.style.backgroundImage = `url('file://{resources}/layout/custom_game/common/game_perks/icons/${current_perk}.png')`;
				SETTINGS_BUTTON.SetPanelEvent("onmouseover", function () {
					$.DispatchEvent("DOTAShowTextTooltip", SETTINGS_BUTTON, $.Localize(`${current_perk}_tooltip`));
				});
				SETTINGS_BUTTON.ClearPanelEvent("onactivate");
				HideGamePerks();
				PERK_MENU.DeleteAsync(0);
				CLOSE_PERK_MENU.DeleteAsync(0);
			}
		});
	}
	if (current_perk == null) {
		$.Schedule(3, ShowGamePerks);
	}
}
function GamePerksInit() {
	GameEvents.Subscribe("game_perks:reload_button", ReloadSettingButton);
	GameEvents.Subscribe("game_perks:set_supp_level", SetPlayerPatreonLevel);
	GameEvents.SendCustomGameEventToServer("game_perks:get_level_and_perks", {});
}
GamePerksInit();
