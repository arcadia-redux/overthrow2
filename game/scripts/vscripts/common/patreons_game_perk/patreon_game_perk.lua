local perksTierPatreon = {
	["patreon_perk_mp_regen_t0"] = 0,
	["patreon_perk_mp_regen_t1"] = 1,
	["patreon_perk_mp_regen_t2"] = 2,
	["patreon_perk_hp_regen_t0"] = 0,
	["patreon_perk_hp_regen_t1"] = 1,
	["patreon_perk_hp_regen_t2"] = 2,
	["patreon_perk_bonus_movespeed_t0"] = 0,
	["patreon_perk_bonus_movespeed_t1"] = 1,
	["patreon_perk_bonus_movespeed_t2"] = 2,
	["patreon_perk_bonus_agi_t0"] = 0,
	["patreon_perk_bonus_agi_t1"] = 1,
	["patreon_perk_bonus_agi_t2"] = 2,
	["patreon_perk_bonus_str_t0"] = 0,
	["patreon_perk_bonus_str_t1"] = 1,
	["patreon_perk_bonus_str_t2"] = 2,
	["patreon_perk_bonus_int_t0"] = 0,
	["patreon_perk_bonus_int_t1"] = 1,
	["patreon_perk_bonus_int_t2"] = 2,
	["patreon_perk_bonus_all_stats_t0"] = 0,
	["patreon_perk_bonus_all_stats_t1"] = 1,
	["patreon_perk_bonus_all_stats_t2"] = 2,
	["patreon_perk_attack_range_t0"] = 0,
	["patreon_perk_attack_range_t1"] = 1,
	["patreon_perk_attack_range_t2"] = 2,
	["patreon_perk_bonus_hp_pct_t0"] = 0,
	["patreon_perk_bonus_hp_pct_t1"] = 1,
	["patreon_perk_bonus_hp_pct_t2"] = 2,
	["patreon_perk_cast_range_t0"] = 0,
	["patreon_perk_cast_range_t1"] = 1,
	["patreon_perk_cast_range_t2"] = 2,
	["patreon_perk_cooldown_reduction_t0"] = 0,
	["patreon_perk_cooldown_reduction_t1"] = 1,
	["patreon_perk_cooldown_reduction_t2"] = 2,
	["patreon_perk_damage_t0"] = 0,
	["patreon_perk_damage_t1"] = 1,
	["patreon_perk_damage_t2"] = 2,
	["patreon_perk_evasion_t0"] = 0,
	["patreon_perk_evasion_t1"] = 1,
	["patreon_perk_evasion_t2"] = 2,
	["patreon_perk_lifesteal_t0"] = 0,
	["patreon_perk_lifesteal_t1"] = 1,
	["patreon_perk_lifesteal_t2"] = 2,
	["patreon_perk_mag_resist_t0"] = 0,
	["patreon_perk_mag_resist_t1"] = 1,
	["patreon_perk_mag_resist_t2"] = 2,
	["patreon_perk_spell_amp_t0"] = 0,
	["patreon_perk_spell_amp_t1"] = 1,
	["patreon_perk_spell_amp_t2"] = 2,
	["patreon_perk_spell_lifesteal_t0"] = 0,
	["patreon_perk_spell_lifesteal_t1"] = 1,
	["patreon_perk_spell_lifesteal_t2"] = 2,
	["patreon_perk_status_resistance_t0"] = 0,
	["patreon_perk_status_resistance_t1"] = 1,
	["patreon_perk_status_resistance_t2"] = 2,
	["patreon_perk_outcomming_heal_amplify_t0"] = 0,
	["patreon_perk_outcomming_heal_amplify_t1"] = 1,
	["patreon_perk_outcomming_heal_amplify_t2"] = 2,
	["patreon_perk_debuff_time_t0"] = 0,
	["patreon_perk_debuff_time_t1"] = 1,
	["patreon_perk_debuff_time_t2"] = 2,
	["patreon_perk_bonus_gold_t0"] = 0,
	["patreon_perk_bonus_gold_t1"] = 1,
	["patreon_perk_bonus_gold_t2"] = 2,
	["patreon_perk_gpm_t0"] = 0,
	["patreon_perk_gpm_t1"] = 1,
	["patreon_perk_gpm_t2"] = 2,
	["patreon_perk_str_for_kill_t0"] = 0,
	["patreon_perk_str_for_kill_t1"] = 1,
	["patreon_perk_str_for_kill_t2"] = 2,
	["patreon_perk_agi_for_kill_t0"] = 0,
	["patreon_perk_agi_for_kill_t1"] = 1,
	["patreon_perk_agi_for_kill_t2"] = 2,
	["patreon_perk_int_for_kill_t0"] = 0,
	["patreon_perk_int_for_kill_t1"] = 1,
	["patreon_perk_int_for_kill_t2"] = 2,
	["patreon_perk_cleave_t0"] = 0,
	["patreon_perk_cleave_t1"] = 1,
	["patreon_perk_cleave_t2"] = 2,
	["patreon_perk_cd_after_deadth_t0"] = 0,
	["patreon_perk_cd_after_deadth_t1"] = 1,
	["patreon_perk_cd_after_deadth_t2"] = 2,
	["patreon_perk_manaburn_t0"] = 0,
	["patreon_perk_manaburn_t1"] = 1,
	["patreon_perk_manaburn_t2"] = 2,
};

for name in pairs(perksTierPatreon) do
	LinkLuaModifier( name, "common/patreons_game_perk/modifier_lib/"..name ,LUA_MODIFIER_MOTION_NONE )
end

_G.PlayersPatreonsPerk = {}
_G.VisiblePerksForEnemyTeam = {}
_G.timerForCheckerPerks = false

RegisterCustomEventListener("check_patreon_level_and_perks", function(data)
	local patreon = Patreons:GetPlayerSettings(data.PlayerID)
	local patreonLvl = patreon.level
	local currentPerk = _G.PlayersPatreonsPerk[data.PlayerID]
	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(data.PlayerID), "return_patreon_level_and_perks", {
		patreonLevel = patreonLvl,
		patreonCurrentPerk = currentPerk
	})
end)

RegisterCustomEventListener("set_patreon_game_perk", function(data)
	local playerID = data.PlayerID
	if not playerID then return end
	if _G.PlayersPatreonsPerk[playerID] then return end
	local player = PlayerResource:GetPlayer(playerID)
	local newModifierName = data.newPerkName
	local patreon = Patreons:GetPlayerSettings(playerID)
	local correctPerk = perksTierPatreon[newModifierName] and perksTierPatreon[newModifierName] <= patreon.level
	if not correctPerk then
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "reload_patreon_perk_setings_button", {})
		return
	end
	local hero = player:GetAssignedHero()
	_G.PlayersPatreonsPerk[playerID] = newModifierName
	if hero then
		if hero:IsAlive() then
			hero:AddNewModifier(hero, nil, newModifierName, {duration = -1})
		else
			Timers:CreateTimer(0.5, function()
				if hero:IsAlive() then
					hero:AddNewModifier(hero, nil, newModifierName, {duration = -1})
					return nil
				end
				return 0.5
			end)
		end
	else
		Timers:CreateTimer(3, function()
			hero = player:GetAssignedHero()
			if hero then
				hero:AddNewModifier(hero, nil, newModifierName, {duration = -1})
				return nil
			else
				return 1
			end
		end)
	end
end)

function StartTrackPerks()
	local teamlist = {
		DOTA_TEAM_GOODGUYS,
		DOTA_TEAM_BADGUYS,
	}
	local maxPlayerForThisMode = 0
	for _, teamId in pairs(teamlist) do
		maxPlayerForThisMode = maxPlayerForThisMode + GameRules:GetCustomGameTeamMaxPlayers(teamId)
	end
	local beaconPlayers = {}
	for _, teamId in pairs(teamlist) do
		for playerId = 0, maxPlayerForThisMode do
			if not beaconPlayers[teamId] and PlayerResource:GetTeam(playerId) == teamId then
				_G.VisiblePerksForEnemyTeam[teamId] = {}
				beaconPlayers[teamId] = playerId
			end
		end
	end

	Timers:CreateTimer(0, function()
		local anyUntrack = false
		for _, teamId in pairs(teamlist) do
			for playerId = 0, maxPlayerForThisMode do
				if _G.PlayersPatreonsPerk[playerId] then
					if PlayerResource:GetTeam(playerId) == teamId then
						for insepctionTeamId, beaconPlayerIdFromEnemyTeam in pairs(beaconPlayers) do
							if not table.contains(_G.VisiblePerksForEnemyTeam[insepctionTeamId], playerId) and beaconPlayers[insepctionTeamId] then
								if PlayerResource:GetSelectedHeroEntity(beaconPlayerIdFromEnemyTeam):CanEntityBeSeenByMyTeam(PlayerResource:GetSelectedHeroEntity(playerId)) then
									CustomGameEventManager:Send_ServerToTeam(insepctionTeamId, "show_player_perk", { playerId = playerId, perkName = _G.PlayersPatreonsPerk[playerId]:gsub("_t%d*", "_t0")})
									table.insert(_G.VisiblePerksForEnemyTeam[insepctionTeamId], playerId)
								else
									anyUntrack = true
								end
							end
						end
					end
				else
					anyUntrack = true
				end
			end
		end
		if anyUntrack then
			return 1
		else
			return nil
		end
	end)
end
RegisterCustomEventListener("check_perks_for_players", function(data)
	if not data.PlayerID then return end
	local playerTeam = PlayerResource:GetTeam(data.PlayerID)
	if not _G.VisiblePerksForEnemyTeam[playerTeam] then return end
	for _, playerId in pairs(_G.VisiblePerksForEnemyTeam[playerTeam]) do
		if _G.PlayersPatreonsPerk[playerId] then
			CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(data.PlayerID), "show_player_perk", { playerId = playerId, perkName = _G.PlayersPatreonsPerk[playerId]:gsub("_t%d*", "")})
		end
	end
end)
