let MASTERIES_LIST;
let TIERS_LIST;
let CURRENT_MASTERY;
let MASTERIES_LIST_BY_NAME = {};
let TIERS = [];
let TOTAL_BASIC_MASTERIES = 0;
let EQUIPPED_MASTERY;
let PLAYER_FORTUNE = 0;

class Tier {
	constructor(tierNumber) {
		this.oldState = TIER_LOCK;
		const tierPanel = $.CreatePanel("Panel", TIERS_LIST, "MasteryTier_" + tierNumber);
		tierPanel.BLoadLayoutSnippet("AbilityTier");
		tierPanel.FindChildTraverse("TierName").text = $.Localize("#tier_" + tierNumber + "_name");
		tierPanel.AddClass("State_1");
		tierPanel.AddClass("MasteryTier_" + tierNumber);
		this.panel = tierPanel;
		this.progressBar = tierPanel.FindChildTraverse("TierStateAction");
		this.stateText = tierPanel.FindChildTraverse("TierStateText");
		this.description = tierPanel.FindChildTraverse("MasteryTierDescription");
	}
	ChangeState(state) {
		this.panel.RemoveClass("State_" + this.oldState);
		this.panel.AddClass("State_" + state);
		this.oldState = state;
	}
	UpdateStateText(text) {
		this.stateText.text = text;
	}
	UpdateProgressBar(value) {
		this.progressBar.value = value;
	}
	UpdateDescription(text) {
		this.description.text = text.replace(/%%/g, "%");
	}
}

function MinimapMasteryButtonAction(bool, image, name) {
	const minimapMasteryButton = $("#MapPatreonButtonButton");
	minimapMasteryButton.SetHasClass("MasterySeleceted", bool);
	minimapMasteryButton.style.backgroundImage = bool
		? image
		: "url('file://{images}/custom_game/collection/mastery/fortune_icon.png');";
	minimapMasteryButton.SetPanelEvent("onmouseover", () => {
		if (bool && image != undefined) {
			$.DispatchEvent(
				"DOTAShowTitleTextTooltip",
				minimapMasteryButton,
				$.Localize("chc_mastery_" + name + "_name"),
				$.Localize("chc_mastery_" + name + "_description_other"),
			);
		} else {
			MinimapButtonTooltip();
		}
	});
	minimapMasteryButton.SetPanelEvent("onmouseout", () => {
		if (bool) {
			$.DispatchEvent("DOTAHideTitleTextTooltip");
		} else {
			MinimapButtonTooltipOver();
		}
	});
}

class Mastery {
	constructor(name, data) {
		this.select = false;
		this.equipped = false;
		this.maxTier = 0;
		const masteryPanel = $.CreatePanel("Panel", MASTERIES_LIST, "Mastery_" + name);
		masteryPanel.BLoadLayoutSnippet("Mastery");
		this.image = "url('file://{images}/custom_game/collection/mastery/icons/" + name + ".png')";
		masteryPanel.FindChildTraverse("MasteryIcon").style.backgroundImage = this.image;
		masteryPanel.SetPanelEvent("onactivate", () => {
			this.ChangeSelectState(true);
		});
		masteryPanel.SetPanelEvent("onmouseout", () => {
			$.DispatchEvent("DOTAHideTextTooltip");
		});

		this.panel = masteryPanel;
		this.name = name;
		this.tiers = data.tiers;
		this.playerHaveTier = {};
		this.particleRoot = masteryPanel.FindChildTraverse("MasteryParticleRoot2");
		this.equippedParticleParent = masteryPanel.FindChildTraverse("MasteryParticleRoot1");

		masteryPanel.SetPanelEvent("onmouseover", () => {
			$.DispatchEvent(
				"DOTAShowTextTooltip",
				masteryPanel.FindChildTraverse("MasteryTooltip"),
				$.Localize("#chc_mastery_" + name + "_name"),
			);
		});
	}
	Equip() {
		if (!this.panel.BHasClass("Availeble")) return;
		if (EQUIPPED_MASTERY != undefined) {
			EQUIPPED_MASTERY.TakeOff();
		}
		EQUIPPED_MASTERY = this;
		EQUIPPED_MASTERY.panel.SetHasClass("Equipped", true);
		this.panel
			.FindChildTraverse("MasteryParticleRoot1")
			.BCreateChildren(
				'<DOTAScenePanel class="EquippedMasteryParticle" camera="camera_common" particleonly="false" map="collection/spin_glow" hittest="false"/>',
			);
		this.equipped = true;
		MinimapMasteryButtonAction(true, this.image, this.name);
		SetMinimapMasteryHintVisible(false);
	}

	TakeOff() {
		MinimapMasteryButtonAction(false);
		this.panel.SetHasClass("Equipped", false);
		this.equippedParticleParent.RemoveAndDeleteChildren();
		this.equipped = false;
	}
	ChangeSelectState(bool) {
		if (CURRENT_MASTERY != undefined && CURRENT_MASTERY != this) CURRENT_MASTERY.ChangeSelectState(false);
		this.panel.SetHasClass("Selected", bool);
		CURRENT_MASTERY = this;
		if (bool) {
			Game.EmitSound("Item.PickUpShop");
			this.OpenInfo();
		}
	}

	OpenInfo() {
		const equipButton = $("#MasteryEquipButton");
		equipButton.SetHasClass(
			"Blocked",
			!this.panel.BHasClass("Availeble") || equipButton.BHasClass("Equipped") || this.equipped,
		);

		$("#MasteriesInfo").AddClass("show");
		$("#AbilityName").text = $.Localize("#mastery_name")
			.replace("##name##", $.Localize("chc_mastery_" + this.name + "_name"))
			.toUpperCase();

		$("#AbilityBorder").SetImage(
			"file://{images}/custom_game/collection/mastery/mastery_poligon_tier_" + (this.maxTier + 1) + ".png",
		);
		$("#AbilityShadow").SetHasClass("show", this.maxTier == 0);

		$("#AbilityImage").style.backgroundImage = this.image;

		TIERS_LIST.Children().forEach((tierPanel, index) => {
			const currentTier = TIERS[index];
			currentTier.panel.SetHasClass("Blocked", true);
			currentTier.UpdateProgressBar(0);
			const notHaveTier = this.tiers[index] == undefined;
			if (!notHaveTier) {
				if (this.playerHaveTier[index] != undefined) {
					currentTier.panel.SetHasClass("Blocked", false);
					const isPermanent = typeof this.playerHaveTier[index].value == "boolean";
					if (isPermanent) {
						currentTier.ChangeState(TIER_UNLOCKED);
						currentTier.UpdateStateText($.Localize("#tier_unlimited"));
					} else {
						const masteryPlayerData = this.playerHaveTier[index];
						currentTier.UpdateProgressBar(masteryPlayerData.progress);
						currentTier.ChangeState(TIER_TIMELESS);
						currentTier.UpdateStateText(
							$.Localize("boost_time_left_" + masteryPlayerData.format).replace(
								"##time##",
								Math.floor(
									masteryPlayerData.value * TIMES_MULTIPLAYER[masteryPlayerData.format],
								).toString(),
							),
						);
					}
				} else {
					currentTier.ChangeState(TIER_LOCK);
					currentTier.UpdateStateText(
						index == 0 ? $.Localize("#only_random_unlock") : $.Localize("#upgrade_to_unlock"),
					);
				}
				currentTier.UpdateDescription(
					$.Localize("#chc_mastery_" + this.name + "_description_self_" + (index + 1)),
				);
			} else {
				currentTier.ChangeState(TIER_REMOVED);
			}
		});
		this.SetUpgradeTextValue();
	}
	UnlockTier(tier, date) {
		this.panel.AddClass("Availeble");
		this.panel.AddClass("MasteryTier_" + tier);
		if (tier > this.maxTier) this.maxTier = tier;
		if (typeof date == "string") {
			const timeLeft = GetTimeLeft(date);
			const progressTimeLeft = Math.min(timeLeft.timeLeft / 30, 1);
			this.playerHaveTier[tier] = {
				value: timeLeft.timeLeft,
				format: timeLeft.format,
				progress: progressTimeLeft,
			};
		} else {
			this.playerHaveTier[tier] = {
				value: true,
			};
		}
	}
	SetUpgradeTextValue() {
		const masteryUpgradeButton = $("#MasteryUpgradeButton");
		const masteryUpgradeText = $("#UpgradeMasteryText");
		masteryUpgradeButton.SetHasClass("FullUpgrade", false);
		masteryUpgradeButton.SetHasClass("Blocked", false);
		masteryUpgradeButton.ClearPanelEvent("onmouseover");
		if (this.tiers[0] && this.playerHaveTier[0] == undefined) {
			masteryUpgradeButton.SetHasClass("Blocked", true);
			masteryUpgradeButton.SetPanelEvent("onmouseover", () => {
				$.DispatchEvent("DOTAShowTextTooltip", masteryUpgradeButton, $.Localize("#need_unlock_mastery"));
			});
		}
		let firstClosedUpgrade;
		Object.entries(this.tiers).forEach(([tier, data]) => {
			if (firstClosedUpgrade == undefined && this.playerHaveTier[tier] == undefined) {
				firstClosedUpgrade = data;
			}
		});
		if (firstClosedUpgrade) {
			masteryUpgradeText.text = $.Localize("#upgrade_mastery").replace(
				"##upgrade_info##",
				$.Localize("#tier_unlock_fortune").replace("##cost##", firstClosedUpgrade.price).toUpperCase(),
			);
			masteryUpgradeButton.SetHasClass(
				"Blocked",
				this.playerHaveTier[0] == undefined || firstClosedUpgrade.price > PLAYER_FORTUNE,
			);
		} else {
			masteryUpgradeButton.SetHasClass("Blocked", true);
			masteryUpgradeButton.SetHasClass("FullUpgrade", true);
			masteryUpgradeText.text = $.Localize("#no_mastery_upgrades");
		}
	}
}

function CreateMasteriesTab(masteriesData) {
	const masteriesListParent = $("#ItemsList_Masteries");
	masteriesListParent.FindChild("Items").visible = false;
	masteriesListParent.FindChild("ItemNone").visible = false;
	masteriesListParent.BLoadLayoutSnippet("MasteriesRoot");
	MASTERIES_LIST = $("#MasteriesAbilitiesList");
	CreateBasicTiers();
	CreateMasteries(masteriesData);
}
function CreateBasicTiers() {
	TIERS_LIST = $("#AbilityTiers");
	TIERS_LIST.RemoveAndDeleteChildren();

	for (let tier = 0; tier < DEFAULT_TIERS_COUNT; tier++) {
		TIERS.push(new Tier(tier));
	}
}

function CreateMasteries(masteriesData) {
	$("#MasteriesUpgradeCost").text = $.Localize("#tier_unlock_fortune")
		.replace("##cost##", RANDOM_UNLOCK_MASTERY_COST)
		.toUpperCase();
	MASTERIES_LIST.RemoveAndDeleteChildren();
	Object.entries(masteriesData).forEach(([name, data]) => {
		MASTERIES_LIST_BY_NAME[name] = new Mastery(name, data);
		if (data.tiers[0] != undefined) {
			TOTAL_BASIC_MASTERIES++;
		}
	});
}
function GetTimeLeft(endDate) {
	let format = "";
	const timeLeft = (new Date(endDate) - new Date()) / 864e5;
	Object.entries(TIMES_MULTIPLAYER).forEach(([_format, multiplayer]) => {
		if (timeLeft > 1 / multiplayer) {
			format = _format;
		}
	});
	if (timeLeft <= 0) return "";
	return { format: format, timeLeft: timeLeft };
}
function UpdatePlayerMasteries(data) {
	let availebleMasteriesCount = 0;
	Object.entries(data.masteries).forEach(([name, masteryData]) => {
		const focusMastery = MASTERIES_LIST_BY_NAME[name];
		Object.entries(masteryData).forEach(([tier, availebleValue]) => {
			tier = parseInt(tier) - 1;
			if (tier == 0) availebleMasteriesCount++;
			focusMastery.UnlockTier(tier, availebleValue);
		});
	});

	const buttonUnlockMastery = $("#MasteriesUpgrade");
	const notAllBasicTiers = availebleMasteriesCount < TOTAL_BASIC_MASTERIES;
	buttonUnlockMastery.GetChild(0).text = $.Localize(
		notAllBasicTiers ? "#mastery_unlock_random" : "#mastery_upgrade_random",
	);
	$("#MasteriesUpgradeDescription").text = $.Localize(
		notAllBasicTiers ? "#mastery_unlock_random_description" : "#mastery_upgrade_random_description",
	);
	if (CURRENT_MASTERY) CURRENT_MASTERY.OpenInfo();
	if (data.newMastery) {
		const newMastery = MASTERIES_LIST_BY_NAME[data.newMastery];
		newMastery.panel.ScrollParentToMakePanelFit(1, true);
		const particle = $.CreatePanel("Panel", newMastery.particleRoot, "");
		particle.BLoadLayoutSnippet("WheelWinParticle");
		particle.AddClass("MasteryParticle");
		particle.AddClass("MasteryParticlePure");
		$.Schedule(5, () => {
			particle.DeleteAsync(0);
		});
		Game.EmitSound("ui.treasure_03");
		newMastery.ChangeSelectState(true);
	}
	$("#MasteryUpgradeButton").SetHasClass("Cooldown", false);
}

function UpgradeRandomMastery() {
	GameEvents.SendCustomGameEventToServer("masteries:upgrade_random_mastery", {});
}
function UpgradeMasteryResponse() {
	const upgradeButton = $("#MasteryUpgradeButton");
	if (upgradeButton.BHasClass("Blocked") || upgradeButton.BHasClass("Cooldown")) return;
	upgradeButton.SetHasClass("Cooldown", true);
	GameEvents.SendCustomGameEventToServer("masteries:upgrade_mastery", { name: CURRENT_MASTERY.name });
}
function SetBlockEquipButton(bool) {
	const equipButton = $("#MasteryEquipButton");
	equipButton.SetHasClass("Blocked", bool);
	equipButton.SetHasClass("Equipped", bool);
	equipButton.GetChild(0).text = $.Localize(bool ? "#equipped_mastery" : "#equip_mastery");
}
function EquipMastery(data) {
	MASTERIES_LIST_BY_NAME[data.name].Equip();
	if (data.manually) SetBlockEquipButton(true);
}
function TakeOffMastery() {
	if (EQUIPPED_MASTERY != undefined) {
		EQUIPPED_MASTERY.TakeOff();
	}
	EQUIPPED_MASTERY = undefined;
	SetBlockEquipButton(false);
	SetMinimapMasteryHintVisible(true);
}

function EquipMasteryResponse() {
	if ($("#MasteryEquipButton").BHasClass("Blocked")) return;
	SetBlockEquipButton(true);
	GameEvents.SendCustomGameEventToServer("masteries:player_equip_mastery", { masteryName: CURRENT_MASTERY.name });
}
function MasteryEquipHint() {
	const equipButton = $("#MasteryEquipButton");
	$.DispatchEvent(
		"DOTAShowTextTooltip",
		equipButton,
		equipButton.BHasClass("Equipped")
			? "#mastery_equipped_already"
			: equipButton.BHasClass("Blocked")
			? "#mastery_equip_need_unlock"
			: "#mastery_equip_current",
	);
}

function UpdateFortune(data) {
	PLAYER_FORTUNE = data.fortune;
	$("#PlayerFortune").text = data.fortune;
}

function SetMinimapMasteryHintVisible(bool) {
	MINIMAP_TOOLTIP.SetHasClass("hide", !bool);
	MINIMAP_TOOLTIP.SetHasClass("TooltipGlow", bool);
}
function MinimapButtonTooltipOver() {
	SetMinimapMasteryHintVisible(false);
}
function MinimapButtonTooltip() {
	MINIMAP_TOOLTIP.SetHasClass("hide", false);
}
function MinimapButtonAction() {
	OpenSpecificCollection({
		category: "Masteries",
		boostGlow: true,
	});
	if (EQUIPPED_MASTERY != undefined) EQUIPPED_MASTERY.ChangeSelectState(true);
}

(function () {
	if (MAP_NAME == "dota") return;
	GameEvents.Subscribe("masteries:update_masteries", UpdatePlayerMasteries);
	GameEvents.Subscribe("masteries:update_fortune", UpdateFortune);
	GameEvents.Subscribe("masteries:equip_mastery", EquipMastery);
	GameEvents.Subscribe("masteries:take_off_mastery", TakeOffMastery);
})();
