-- Core initialization
if FFA == nil then
	_G.FFA = class({})
end

function FFA:Init()

	self.teams = {
		DOTA_TEAM_GOODGUYS,
		DOTA_TEAM_BADGUYS,
		DOTA_TEAM_CUSTOM_1,
		DOTA_TEAM_CUSTOM_2,
		DOTA_TEAM_CUSTOM_3,
		DOTA_TEAM_CUSTOM_4,
		DOTA_TEAM_CUSTOM_5,
		DOTA_TEAM_CUSTOM_6,
		DOTA_TEAM_CUSTOM_7,
		DOTA_TEAM_CUSTOM_8
	}

	self.spawn_locations = {}
	local initial_spawn_points = Entities:FindAllByName("ffa_spawn_point")
	for _, spawn_point in pairs(initial_spawn_points) do
		print("spawn point added")
		table.insert(self.spawn_locations, spawn_point:GetOrigin())
	end

	for _, team in pairs(self.teams) do
		GameRules:SetCustomGameTeamMaxPlayers(team, 24)
	end

	--SetTeamCustomHealthbarColor(DOTA_TEAM_GOODGUYS, 255, 255, 255)
	--SetTeamCustomHealthbarColor(DOTA_TEAM_BADGUYS, 255, 255, 0)
	--SetTeamCustomHealthbarColor(DOTA_TEAM_CUSTOM_1, 255, 0, 255)
	--SetTeamCustomHealthbarColor(DOTA_TEAM_CUSTOM_2, 255, 0, 0)
	--SetTeamCustomHealthbarColor(DOTA_TEAM_CUSTOM_3, 0, 255, 255)
	--SetTeamCustomHealthbarColor(DOTA_TEAM_CUSTOM_4, 0, 255, 0)
	--SetTeamCustomHealthbarColor(DOTA_TEAM_CUSTOM_5, 0, 0, 255)
	--SetTeamCustomHealthbarColor(DOTA_TEAM_CUSTOM_6, 0, 0, 0)
	--SetTeamCustomHealthbarColor(DOTA_TEAM_CUSTOM_7, 128, 0, 128)
	--SetTeamCustomHealthbarColor(DOTA_TEAM_CUSTOM_8, 0, 128, 0)

	self.forbidden_distance = 1000
	self.max_player_id = -1
	self.player_heroes = {}
	self.player_positions = {}
	self.player_teams = {}

	for id = 0, 23 do
		if PlayerResource:IsValidPlayerID(id) then
			Timers:CreateTimer(0, function()
				if PlayerResource:GetSelectedHeroEntity(id) then
					self.player_heroes[id] = PlayerResource:GetSelectedHeroEntity(id)
					self.player_positions[id] = self.player_heroes[id]:GetAbsOrigin()
					self.player_teams[id] = self.player_heroes[id]:GetTeam()
					self.max_player_id = self.max_player_id + 1
				else
					return 1
				end
			end)
		end
	end

	self.players_by_team = {}
	self.players_by_team[DOTA_TEAM_GOODGUYS] = {}
	self.players_by_team[DOTA_TEAM_BADGUYS] = {}
	self.players_by_team[DOTA_TEAM_CUSTOM_1] = {}
	self.players_by_team[DOTA_TEAM_CUSTOM_2] = {}
	self.players_by_team[DOTA_TEAM_CUSTOM_3] = {}
	self.players_by_team[DOTA_TEAM_CUSTOM_4] = {}
	self.players_by_team[DOTA_TEAM_CUSTOM_5] = {}
	self.players_by_team[DOTA_TEAM_CUSTOM_6] = {}
	self.players_by_team[DOTA_TEAM_CUSTOM_7] = {}
	self.players_by_team[DOTA_TEAM_CUSTOM_8] = {}

	self.players_by_team_switch = {}
	self.players_by_team_switch[DOTA_TEAM_GOODGUYS] = {}
	self.players_by_team_switch[DOTA_TEAM_BADGUYS] = {}
	self.players_by_team_switch[DOTA_TEAM_CUSTOM_1] = {}
	self.players_by_team_switch[DOTA_TEAM_CUSTOM_2] = {}
	self.players_by_team_switch[DOTA_TEAM_CUSTOM_3] = {}
	self.players_by_team_switch[DOTA_TEAM_CUSTOM_4] = {}
	self.players_by_team_switch[DOTA_TEAM_CUSTOM_5] = {}
	self.players_by_team_switch[DOTA_TEAM_CUSTOM_6] = {}
	self.players_by_team_switch[DOTA_TEAM_CUSTOM_7] = {}
	self.players_by_team_switch[DOTA_TEAM_CUSTOM_8] = {}

	self.team_congestion = {}
	self.team_congestion[DOTA_TEAM_GOODGUYS] = 0
	self.team_congestion[DOTA_TEAM_BADGUYS] = 0
	self.team_congestion[DOTA_TEAM_CUSTOM_1] = 0
	self.team_congestion[DOTA_TEAM_CUSTOM_2] = 0
	self.team_congestion[DOTA_TEAM_CUSTOM_3] = 0
	self.team_congestion[DOTA_TEAM_CUSTOM_4] = 0
	self.team_congestion[DOTA_TEAM_CUSTOM_5] = 0
	self.team_congestion[DOTA_TEAM_CUSTOM_6] = 0
	self.team_congestion[DOTA_TEAM_CUSTOM_7] = 0
	self.team_congestion[DOTA_TEAM_CUSTOM_8] = 0

	Timers:CreateTimer(0, function()
		if self.max_player_id >= 23 then
			self:OptimizeTeams()
			return 0.03
		else
			return 1
		end
	end)

end

function FFA:UpdatePlayerPositionsAndTeams()
	for id = 0, self.max_player_id do
		self.player_positions[id] = self.player_heroes[id]:GetAbsOrigin()
		self.player_teams[id] = self.player_heroes[id]:GetTeam()
	end
end

function FFA:UpdatePlayersByTeam()
	for team, player_table in pairs(self.players_by_team) do
		self.players_by_team[team] = {}
	end
	
	for id = 0, self.max_player_id do
		if self.players_by_team[self.player_teams[id]] then
			table.insert(self.players_by_team[self.player_teams[id]], id)
		end
	end
end

function FFA:CalculateTeamCongestion(team)
	local congestion = 0
	local pair_distances = {}
	local sum = 0

	if #self.players_by_team[team] >= 2 then
		for first_player = 1, (#self.players_by_team[team] - 1) do
			for second_player = (first_player + 1), #self.players_by_team[team] do
				table.insert(pair_distances, (self.player_positions[self.players_by_team[team][first_player]] - self.player_positions[self.players_by_team[team][second_player]]):Length2D())
			end
		end
	end

	if #pair_distances > 0 then
		for _, distance in pairs(pair_distances) do
			sum = sum + (1 / distance)
		end

		congestion = #self.players_by_team[team] * (sum / #pair_distances)
	end

	return congestion
end

function FFA:CalculateCongestion()
	self:UpdatePlayerPositionsAndTeams()
	self:UpdatePlayersByTeam()

	local total_congestion = 0
	for team, congestion in pairs(self.team_congestion) do
		self.team_congestion[team] = self:CalculateTeamCongestion(team)
		total_congestion = total_congestion + self.team_congestion[team]
	end

	return total_congestion
end

function FFA:CalculateTheoreticalTeamCongestion(team)
	local congestion = 0
	local pair_distances = {}
	local sum = 0

	if #self.players_by_team_switch[team] >= 2 then
		for first_player = 1, (#self.players_by_team_switch[team] - 1) do
			for second_player = (first_player + 1), #self.players_by_team_switch[team] do
				table.insert(pair_distances, (self.player_positions[self.players_by_team_switch[team][first_player]] - self.player_positions[self.players_by_team_switch[team][second_player]]):Length2D())
			end
		end
	end

	if #pair_distances > 0 then
		for _, distance in pairs(pair_distances) do
			sum = sum + (1 / distance)
		end

		congestion = #self.players_by_team_switch[team] * (sum / #pair_distances)
	end

	return congestion
end

function FFA:CalculatePlayerSwitchDelta(id, team)

	local original_team = self.player_teams[id]
	if team == original_team then
		return 0
	end

	local surrounding_teammates = FindUnitsInRadius(team, self.player_positions[id], nil, self.forbidden_distance, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	if #surrounding_teammates > 0 then
		return 0
	end

	self.players_by_team_switch[team] = {}
	self.players_by_team_switch[original_team] = {}

	for _, player_id in pairs(self.players_by_team[team]) do
		table.insert(self.players_by_team_switch[team], player_id)
	end
	table.insert(self.players_by_team_switch[team], id)

	for _, player_id in pairs(self.players_by_team[original_team]) do
		if player_id ~= id then
			table.insert(self.players_by_team_switch[original_team], player_id)
		end
	end

	local delta = self.team_congestion[team] - FFA:CalculateTheoreticalTeamCongestion(team)
	delta = delta + self.team_congestion[original_team] - FFA:CalculateTheoreticalTeamCongestion(original_team)

	return delta
end


function FFA:OptimizeTeams()
	--print("total congestion: "..self:CalculateCongestion())
	self:CalculateCongestion()

	local best_delta = 0
	local delta_player = 0
	local delta_team = 0

	for id = 0, self.max_player_id do
		for _, team in pairs(self.teams) do
			local delta = self:CalculatePlayerSwitchDelta(id, team)
			if delta > best_delta then
				best_delta = delta
				delta_player = id
				delta_team = team
			end
		end
	end

	if best_delta > 0 then
		--print("switching player "..delta_player.." to team "..delta_team..", resulting in "..best_delta.." decrease in congestion")
		PlayerResource:SetCustomTeamAssignment(delta_player, delta_team)
		self.player_heroes[delta_player]:SetTeam(delta_team)
	end
end

function FFA:GetBestRespawnPosition()
	local best_location = Vector(0, 0, 0)
	local best_score = 1000
	for _, location in pairs(self.spawn_locations) do
		print("testing location:")
		print(location)
		local current_location_score = 0
		for id = 0, self.max_player_id do
			local distance = (self.player_positions[id] - location):Length2D()
			if distance <= 500 then
				current_location_score = current_location_score + 5
			elseif distance <= 1000 then
				current_location_score = current_location_score + 2
			elseif distance <= 1500 then
				current_location_score = current_location_score + 1
			end
		end

		if current_location_score < best_score then
			best_score = current_location_score
			best_location = location
		end
	end

	return best_location
end