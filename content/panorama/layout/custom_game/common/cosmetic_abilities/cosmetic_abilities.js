const cosmeticAbilityOverrideImages = {
	high_five_custom: "file://{images}/spellicons/consumables/high_five.png",
	seasonal_ti9_banner: "file://{images}/spellicons/consumables/seasonal_ti9_banner_2.png",
	default_cosmetic_ability: "file://{images}/custom_game/collection/default_cosmetic_ability.png",
	spray_custom: "file://{images}/custom_game/collection/spray_empty.png",
};
let dummyCaster = -1;
const ABILITIES_DEFAULT_ACTION = {
	high_five_custom: () => {
		CastAbilityByDummy("high_five_custom");
	},
	default_cosmetic_ability: () => {
		GameEvents.SendEventClientSide("battlepass_inventory:open_specific_collection", {
			category: "CosmeticAbilities",
		});
	},
	spray_custom: () => {
		GameEvents.SendEventClientSide("battlepass_inventory:open_specific_collection", {
			category: "Sprays",
		});
	},
};
function CastAbilityByDummy(abilityName) {
	if (dummyCaster > -1) {
		let ability;
		for (let i = 0; i < Entities.GetAbilityCount(dummyCaster); i++) {
			if (Entities.GetAbility(dummyCaster, i) > -1) {
				const _ability = Entities.GetAbility(dummyCaster, i);
				const _abilityName = Abilities.GetAbilityName(_ability);
				if (_abilityName == abilityName) ability = _ability;
			}
		}
		if (ability) {
			if (!Abilities.IsCooldownReady(ability)) {
				GameEvents.SendEventClientSide("dota_hud_error_message", {
					splitscreenplayer: 0,
					reason: 80,
					message: "dota_cursor_cooldown_no_time",
				});
			} else {
				const oldSelectedUnit = Players.GetSelectedEntities(Game.GetLocalPlayerID());
				GameUI.SelectUnit(dummyCaster, false);
				Abilities.ExecuteAbility(ability, dummyCaster, false);
				oldSelectedUnit.forEach((ent, index) => {
					GameUI.SelectUnit(ent, index != 0);
				});
			}
		}
	}
}

function UpdateCosmeticSpray(data) {
	const spray = FindDotaHudElement("CustomAbility_spray_custom");
	const isEmptySpray = data.spray == "";
	spray
		.FindChildTraverse("CosmeticAbilityImage")
		.SetImage(
			isEmptySpray
				? cosmeticAbilityOverrideImages.spray_custom
				: "file://{images}/custom_game/collection/spray_no_empty.png",
		);

	spray.SetPanelEvent(
		"onactivate",
		isEmptySpray
			? ABILITIES_DEFAULT_ACTION.spray_custom
			: () => {
					CastAbilityByDummy("spray_custom");
			  },
	);
}
function UpdateCosmeticAbility(data) {
	_CreateCustomAbility(FindDotaHudElement("CustomAbility_default_cosmetic_ability"), data.ability);
}
function _CreateCustomAbility(ability, abilityName) {
	const image_path =
		cosmeticAbilityOverrideImages[abilityName] || "file://{images}/spellicons/consumables/" + abilityName + ".png";

	ability.cooldownEffect.style["opacity-mask"] = "url( '" + image_path + "' )";
	ability.FindChildTraverse("CosmeticAbilityImage").SetImage(image_path);
	ability.SetPanelEvent("onmouseover", () => {
		$.DispatchEvent("DOTAShowAbilityTooltip", ability, abilityName);
	});
	ability.SetPanelEvent("onmouseout", () => {
		$.DispatchEvent("DOTAHideAbilityTooltip", ability);
	});
	if (ABILITIES_DEFAULT_ACTION[abilityName]) {
		ability.SetPanelEvent("onactivate", ABILITIES_DEFAULT_ACTION[abilityName]);
	} else {
		ability.SetPanelEvent("onactivate", () => {
			CastAbilityByDummy(abilityName);
		});
	}
}
function _StartTrackAbilitiesCooldown(dummyEntIndex) {
	for (let i = 0; i < Entities.GetAbilityCount(dummyEntIndex); i++) {
		if (Entities.GetAbility(dummyEntIndex, i) > -1) {
			const ability = Entities.GetAbility(dummyEntIndex, i);
			let abilityName = Abilities.GetAbilityName(ability);
			if (abilityName != "high_five_custom" && abilityName != "spray_custom")
				abilityName = "default_cosmetic_ability";
			const abilityPanel = FindDotaHudElement("CustomAbility_" + abilityName);
			if (abilityPanel == undefined) continue;
			if (!Abilities.IsCooldownReady(ability)) {
				if (abilityPanel.maxCooldown == null) {
					abilityPanel.maxCooldown = Abilities.GetCooldownLength(ability);
				}
				const remaining = Abilities.GetCooldownTimeRemaining(ability);
				const progress = (remaining / abilityPanel.maxCooldown) * -360;
				abilityPanel.cooldownRoot.visible = true;
				abilityPanel.cooldownEffect.style.clip = "radial( 50% 75%, 0deg, " + progress + "deg )";
				abilityPanel.cooldownValue.text = Math.ceil(remaining);
			} else {
				abilityPanel.maxCooldown = null;
				abilityPanel.cooldownRoot.visible = false;
			}
		}
	}
	$.Schedule(0.1, () => {
		_StartTrackAbilitiesCooldown(dummyEntIndex);
	});
}
function UpdateCosmeticDummy(data) {
	const dummyEntIndex = data.ent;
	dummyCaster = dummyEntIndex;
	_StartTrackAbilitiesCooldown(dummyEntIndex);
}
(function () {
	$.Msg("Qwerty");
	const centerBlock = FindDotaHudElement("center_block");
	let cosmetics = centerBlock.FindChildTraverse("BarOverItems");

	if (cosmetics) {
		cosmetics.DeleteAsync(0);
	}

	Object.entries(ABILITIES_DEFAULT_ACTION).forEach(([abilityName, action]) => {
		const ability = $.CreatePanel("Button", FindDotaHudElement("BarOverItems"), "CustomAbility_" + abilityName);
		ability.BLoadLayoutSnippet("CosmeticAbility");
		ability.SetPanelEvent("onactivate", action);
		ability.cooldownEffect = ability.FindChildTraverse("CooldownEffect");
		ability.cooldownValue = ability.FindChildTraverse("CooldownValue");
		ability.cooldownRoot = ability.FindChildTraverse("CooldownRoot");
		_CreateCustomAbility(ability, abilityName);
	});

	if (!cosmetics) {
		$("#BarOverItems").SetParent(centerBlock);
	}

	FindDotaHudElement("buffs").style.transform = "translateY( -43px )";
	FindDotaHudElement("debuffs").style.transform = "translateY( -43px )";
	GameEvents.Subscribe("cosmetic_abilities:update_ability", UpdateCosmeticAbility);
	GameEvents.Subscribe("cosmetic_abilities:update_dummy_tracking", UpdateCosmeticDummy);
	GameEvents.Subscribe("cosmetic_abilities:update_spray", UpdateCosmeticSpray);
	GameEvents.SendCustomGameEventToServer("cosmetic_abilities:get_dummy_caster", {});
})();
