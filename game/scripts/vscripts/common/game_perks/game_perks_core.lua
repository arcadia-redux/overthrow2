require("common/game_perks/buff_amplified_list")

GamePerks = GamePerks or {}

function GamePerks:Init()
	self.game_perks = {
		["mp_regen"] = true;
		["hp_regen"] = true;
		["bonus_movespeed"] = true;
		["bonus_agi"] = true;
		["bonus_str"] = true;
		["bonus_int"] = true;
		["bonus_all_stats"] = true;
		["attack_range"] = true;
		["bonus_hp_pct"] = true;
		["cast_range"] = true;
		["cooldown_reduction"] = true;
		["damage"] = true;
		["evasion"] = true;
		["lifesteal"] = true;
		["mag_resist"] = true;
		["spell_amp"] = true;
		["spell_lifesteal"] = true;
		["status_resistance"] = true;
		["outcomming_heal_amplify"] = true;
		["debuff_time"] = true;
		["bonus_gold"] = true;
		["gpm"] = true;
		["str_for_kill"] = true;
		["agi_for_kill"] = true;
		["int_for_kill"] = true;
		["cleave"] = true;
		["cd_after_death"] = true;
		["manaburn"] = true;
		["magician"] = true;
		["linken"] = true;
		["buff_amplify"] = true;
		--["builder"] = true;
		--["traveler"] = true;
		["delayed_damage"] = true;
	};

	self.choosed_perks = {}
	self.visible_perks_for_enemies = {}
	
	for perk_name in pairs(self.game_perks) do
		for tier = 0, 2 do
			local full_perk_name = perk_name .. "_t" .. tier
			LinkLuaModifier( full_perk_name, "common/game_perks/modifier_lib/" .. perk_name, LUA_MODIFIER_MOTION_NONE )
		end
	end
	CustomGameEventManager:RegisterListener("game_perks:get_level_and_perks",function(_, event)
		self:CheckPatreonLevelAndPerks(event)
	end)
	CustomGameEventManager:RegisterListener("game_perks:set_perk",function(_, event)
		self:SetGamePerk(event)
	end)
	CustomGameEventManager:RegisterListener("game_perks:check_perks_for_players",function(_, event)
		self:CheckPerks(event)
	end)
end

function GamePerks:CheckPatreonLevelAndPerks(event)
	local player_id = event.PlayerID
	if not player_id then return end
	
	local patreon_lvl = Supporters:GetLevel(player_id)
	local current_perk = self.choosed_perks[player_id]
	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(player_id), "game_perks:set_supp_level", {
		patreon_level = patreon_lvl,
		current_perk = current_perk
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
	local is_correct_perk = self.game_perks[perk_name:gsub("_t%d*$", "")] and is_tier_correct and perk_tier <= supporter_level
	
	if not is_correct_perk then
		CustomGameEventManager:Send_ServerToPlayer(player, "game_perks:reload_button", {})
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
			local perkName = self.choosed_perks[visible_player_id]:gsub("_t%d*$", "_t0")
			CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(player_id), "game_perks:show_player_perk", { 
				playerId = visible_player_id, 
				perkName = perkName
			})
		end
	end
end

function GamePerks:StartTrackPerks()
	local teams_list = {
		DOTA_TEAM_GOODGUYS,
		DOTA_TEAM_BADGUYS,
	}
	
	local max_players_in_team = 0
	for _, team_id in pairs(teams_list) do
		max_players_in_team = max_players_in_team + GameRules:GetCustomGameTeamMaxPlayers(team_id)
	end
	
	local beacon_players = {}
	for _, team_id in pairs(teams_list) do
		for player_id = 0, max_players_in_team do
			if not beacon_players[team_id] and PlayerResource:GetTeam(player_id) == team_id then
				self.visible_perks_for_enemies[team_id] = {}
				beacon_players[team_id] = player_id
			end
		end
	end

	Timers:CreateTimer(0, function()
		local any_untrack = false
		for _, team_id in pairs(teams_list) do
			for player_id = 0, max_players_in_team do
				if self.choosed_perks[player_id] then
					if PlayerResource:GetTeam(player_id) == team_id then
						for insepction_team, beacon_player_id_from_enemy_team in pairs(beacon_players) do
							if not table.contains(self.visible_perks_for_enemies[insepction_team], player_id) and beacon_players[insepction_team] then
								
								local beacon_hero = PlayerResource:GetSelectedHeroEntity(beacon_player_id_from_enemy_team)
								local focus_hero = PlayerResource:GetSelectedHeroEntity(player_id)
								
								if beacon_hero and focus_hero and beacon_hero:CanEntityBeSeenByMyTeam(focus_hero) then
									CustomGameEventManager:Send_ServerToTeam(insepction_team, "show_player_perk", { playerId = player_id, perkName = self.choosed_perks[player_id]:gsub("_t%d*$", "_t0")})
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
