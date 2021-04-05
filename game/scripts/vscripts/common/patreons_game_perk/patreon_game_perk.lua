GamePerks = GamePerks or {}

function GamePerks:Init()
	self.game_perks = {
		["patreon_perk_mp_regen"] = true;
		["patreon_perk_hp_regen"] = true;
		["patreon_perk_bonus_movespeed"] = true;
		["patreon_perk_bonus_agi"] = true;
		["patreon_perk_bonus_str"] = true;
		["patreon_perk_bonus_int"] = true;
		["patreon_perk_bonus_all_stats"] = true;
		["patreon_perk_attack_range"] = true;
		["patreon_perk_bonus_hp_pct"] = true;
		["patreon_perk_cast_range"] = true;
		["patreon_perk_cooldown_reduction"] = true;
		["patreon_perk_damage"] = true;
		["patreon_perk_evasion"] = true;
		["patreon_perk_lifesteal"] = true;
		["patreon_perk_mag_resist"] = true;
		["patreon_perk_spell_amp"] = true;
		["patreon_perk_spell_lifesteal"] = true;
		["patreon_perk_status_resistance"] = true;
		["patreon_perk_outcomming_heal_amplify"] = true;
		["patreon_perk_debuff_time"] = true;
		["patreon_perk_bonus_gold"] = true;
		["patreon_perk_gpm"] = true;
		["patreon_perk_str_for_kill"] = true;
		["patreon_perk_agi_for_kill"] = true;
		["patreon_perk_int_for_kill"] = true;
		["patreon_perk_cleave"] = true;
		["patreon_perk_cd_after_deadth"] = true;
		["patreon_perk_manaburn"] = true;
	};

	self.choosed_perks = {}
	self.visible_perks_for_enemies = {}
	
	for perk_name in pairs(self.game_perks) do
		for tier = 0, 2 do
			local full_perk_name = perk_name .. "_t" .. tier
			LinkLuaModifier( full_perk_name, "common/patreons_game_perk/modifier_lib/" .. full_perk_name, LUA_MODIFIER_MOTION_NONE )
		end
	end
	CustomGameEventManager:RegisterListener("check_patreon_level_and_perks",function(_, event)
		self:CheckPatreonLevelAndPerks(event)
	end)
	CustomGameEventManager:RegisterListener("set_patreon_game_perk",function(_, event)
		self:SetGamePerk(event)
	end)
	CustomGameEventManager:RegisterListener("check_perks_for_players",function(_, event)
		self:CheckPerks(event)
	end)
end

function GamePerks:CheckPatreonLevelAndPerks(event)
	local player_id = event.PlayerID
	if not player_id then return end
	
	local patreon_lvl = Supporters:GetLevel(player_id)
	local current_perk = self.choosed_perks[player_id]
	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(player_id), "return_patreon_level_and_perks", {
		patreonLevel = patreon_lvl,
		patreonCurrentPerk = current_perk
	})
end

function GamePerks:SetGamePerkSchedule(event)
	Timers:CreateTimer(1, function()
		GamePerks:SetGamePerk(event)
		return nil
	end)
end

function GamePerks:SetGamePerk(event)
	local player_id = event.PlayerID
	if not player_id then return end
	
	if self.choosed_perks[player_id] then return end
	local player = PlayerResource:GetPlayer(player_id)
	if not player then GamePerks:SetGamePerkSchedule(event) return end
	
	if PlayerResource:GetConnectionState(player_id) ~= DOTA_CONNECTION_STATE_CONNECTED then GamePerks:SetGamePerkSchedule(event) return end
	
	local perk_name = event.newPerkName
	local supporter_level = Supporters:GetLevel(player_id)
	local perk_tier = tonumber(string.sub(perk_name, -1))
	local is_tier_correct = perk_tier and perk_tier > -1 and perk_tier < 4
	local is_correct_perk = self.game_perks[perk_name:gsub("_t%d*", "")] and is_tier_correct and perk_tier <= supporter_level
	
	if not is_correct_perk then
		CustomGameEventManager:Send_ServerToPlayer(player, "reload_patreon_perk_setings_button", {})
		return
	end
	
	local hero = player:GetAssignedHero()
	
	if hero and not hero:IsNull() and hero:IsAlive() then
		self.choosed_perks[player_id] = perk_name
		hero:AddNewModifier(hero, nil, perk_name, {duration = -1})
	else
		GamePerks:SetGamePerkSchedule(event)
	end
end

function GamePerks:CheckPerks(event)
	local player_id = event.PlayerID
	if not player_id then return end
	
	local playerTeam = PlayerResource:GetTeam(player_id)
	if not self.visible_perks_for_enemies[playerTeam] then return end
	for _, visible_player_id in pairs(self.visible_perks_for_enemies[playerTeam]) do
		if self.choosed_perks[visible_player_id] then
			local perkName = self.choosed_perks[visible_player_id]:gsub("_t%d*", "_t0")
			CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(player_id), "show_player_perk", { 
				playerId = visible_player_id, 
				perkName = perkName
			})
		end
	end
end

function GamePerks:StartTrackPerks(teams_list)	
	local max_players_in_team = 0
	DeepPrintTable(teams_list)
	for team_id, _ in pairs(teams_list) do
		max_players_in_team = max_players_in_team + GameRules:GetCustomGameTeamMaxPlayers(team_id)
	end
	
	local beacon_players = {}
	for team_id, _ in pairs(teams_list) do
		for player_id = 0, max_players_in_team do
			if not beacon_players[team_id] and PlayerResource:GetTeam(player_id) == team_id then
				self.visible_perks_for_enemies[team_id] = {}
				beacon_players[team_id] = player_id
			end
		end
	end

	Timers:CreateTimer(0, function()
		local any_untrack = false
		for team_id, _ in pairs(teams_list) do
			for player_id = 0, max_players_in_team do
				if self.choosed_perks[player_id] then
					if PlayerResource:GetTeam(player_id) == team_id then
						for insepction_team, beacon_player_id_from_enemy_team in pairs(beacon_players) do
							if not table.contains(self.visible_perks_for_enemies[insepction_team], player_id) and beacon_players[insepction_team] then
								
								local beacon_hero = PlayerResource:GetSelectedHeroEntity(beacon_player_id_from_enemy_team)
								local focus_hero = PlayerResource:GetSelectedHeroEntity(player_id)
								
								if beacon_hero and focus_hero and beacon_hero:CanEntityBeSeenByMyTeam(focus_hero) then
									CustomGameEventManager:Send_ServerToTeam(insepction_team, "show_player_perk", { playerId = player_id, perkName = self.choosed_perks[player_id]:gsub("_t%d*", "_t0")})
									table.insert(self.visible_perks_for_enemies[insepction_team], player_id)
								else
									any_untrack = true
								end
							end
						end
					end
				else
					any_untrack = true
				end
			end
		end
		return any_untrack and 1 or nil
	end)
end
