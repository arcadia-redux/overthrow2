DisableHelp = DisableHelp or {}

RegisterCustomEventListener("set_disable_help", function(data)
	local to = data.to;
	if PlayerResource:IsValidPlayerID(to) then
		local playerId = data.PlayerID;
		local disable = data.disable == 1
		PlayerResource:SetUnitShareMaskForPlayer(playerId, to, 4, disable)

		local disableHelp = CustomNetTables:GetTableValue("disable_help", tostring(playerId)) or {}
		disableHelp[tostring(to)] = disable
		CustomNetTables:SetTableValue("disable_help", tostring(playerId), disableHelp)
	end
end)

local disabledModifiers = {
	modifier_tiny_toss = true,
}

function DisableHelp.ModifierGainedFilter(filterTable)
	if disabledModifiers[filterTable.name_const] then
		local parent = EntIndexToHScript(filterTable.entindex_parent_const)
		local caster = EntIndexToHScript(filterTable.entindex_caster_const)
		local ability = EntIndexToHScript(filterTable.entindex_ability_const)

		if PlayerResource:IsDisableHelpSetForPlayerID(parent:GetPlayerOwnerID(), caster:GetPlayerOwnerID()) then
			ability:EndCooldown()
			ability:RefundManaCost()
			DisplayError(caster:GetPlayerOwnerID(), "dota_hud_error_target_has_disable_help")
			return false
		end
	end
end

local disabledAbilities = {
	oracle_fates_edict = true,
	oracle_purifying_flames = true,
	wisp_tether = true,
	earth_spirit_boulder_smash = true,
	earth_spirit_geomagnetic_grip = true,
	earth_spirit_petrify = true,
	troll_warlord_battle_trance = true,
	vengefulspirit_nether_swap = true,
	pugna_decrepify = true,
	pudge_dismember = true,
	lycan_wolf_bite = true,
}

function DisableHelp.ExecuteOrderFilter(orderType, ability, target, unit)
	if (
		orderType == DOTA_UNIT_ORDER_CAST_TARGET and
		ability and
		target and
		unit and
		disabledAbilities[ability:GetAbilityName()] and
		PlayerResource:IsDisableHelpSetForPlayerID(target:GetPlayerOwnerID(), unit:GetPlayerOwnerID())
	) then
		DisplayError(unit:GetPlayerOwnerID(), "dota_hud_error_target_has_disable_help")
		return false
	end
end
