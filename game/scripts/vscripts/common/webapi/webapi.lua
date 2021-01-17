WebApi = WebApi or {}
WebApi.playerSettings = WebApi.playerSettings or {}

local isTesting = IsInToolsMode() and true or false
for playerId = 0, 23 do
	WebApi.playerSettings[playerId] = WebApi.playerSettings[playerId] or {}
end
WebApi.matchId = IsInToolsMode() and RandomInt(-10000000, -1) or tonumber(tostring(GameRules:GetMatchID()))
FREE_SUPPORTER_COUNT = 6

local serverHost = IsInToolsMode() and "http://127.0.0.1:5000" or "https://api.overthrow.dota2unofficial.com"
local dedicatedServerKey = GetDedicatedServerKeyV2("1")

function WebApi:Send(path, data, onSuccess, onError, retryWhile)
	local request = CreateHTTPRequestScriptVM("POST", serverHost .. "/api/lua/" .. path)
	if isTesting then
		print("Request to " .. path)
		DeepPrintTable(data)
	end

	request:SetHTTPRequestHeaderValue("Dedicated-Server-Key", dedicatedServerKey)
	if data ~= nil then
		request:SetHTTPRequestRawPostBody("application/json", json.encode(data))
	end

	request:Send(function(response)
		if response.StatusCode >= 200 and response.StatusCode < 300 then
			local data = json.decode(response.Body)
			if isTesting then
				print("Response from " .. path .. ":")
				DeepPrintTable(data)
			end
			if onSuccess then
				onSuccess(data)
			end
		else
			local err = json.decode(response.Body)
			if type(err) ~= "table" then err = {} end

			if isTesting then
				print("Error from " .. path .. ": " .. response.StatusCode)
				if response.Body then
					local status, result = pcall(json.decode, response.Body)
					if status then
						DeepPrintTable(result)
					else
						print(response.Body)
					end
				end
			end

			local message = (response.StatusCode == 0 and "Could not establish connection to the server. Please try again later.") or err.title or "Unknown error."
			if err.traceId then
				message = message .. " Report it to the developer with this id: " .. err.traceId
			end
			err.message = message

			if retryWhile and retryWhile(err) then
				WebApi:Send(path, data, onSuccess, onError, retryWhile)
			elseif onError then
				onError(err)
			end
		end
	end)
end

local function retryTimes(times)
	return function()
		times = times - 1
		return times >= 0
	end
end

function WebApi:BeforeMatch()
	-- TODO: Smart random Init, patreon init, nettables init
	local players = {}
	for playerId = 0, 23 do
		if PlayerResource:IsValidPlayerID(playerId) then
			table.insert(players, tostring(PlayerResource:GetSteamID(playerId)))
		end
	end

	WebApi:Send("match/before", {customGame = WebApi.customGame, mapName = GetMapName(), players = players }, function(data)
		print("BEFORE MATCH")
		WebApi.player_ratings = {}
		WebApi.patch_notes = data.patchnotes
		publicStats = {}
		local matchesCount = {}
		for _, player in ipairs(data.players) do
			local playerId = GetPlayerIdBySteamId(player.steamId)
			if player.rating then
				WebApi.player_ratings[playerId] = {[GetMapName()] = player.rating}
			end
			matchesCount[playerId] = player.matchCount
			if player.supporterState then
				Supporters:SetPlayerState(playerId, player.supporterState)
			end
			if player.masteries then
				BP_Masteries:SetMasteriesForPlayer(playerId, player.masteries)
			end

			publicStats[playerId] = {
				streak = 0,
				bestStreak = 0,
				averageKills = player.stats.kills,
				averageDeaths = player.stats.deaths,
				averageAssists = player.stats.assists,
				wins = player.stats.wins,
				loses = player.stats.loses,
				rating = player.rating,
			}
			SmartRandom:SetPlayerInfo(playerId, nil, "no_stats") -- TODO: either make working or get rid of it
		end
		CustomNetTables:SetTableValue("game_state", "player_stats", publicStats)
		CustomNetTables:SetTableValue("game_state", "player_ratings", data.mapPlayersRating)
		CustomNetTables:SetTableValue("game_state", "leaderboard", data.leaderboard)

		Battlepass:OnDataArrival(data)
	end,
	function(err)
		print(err.message)
	end
	, retryTimes(2))
end

WebApi.scheduledUpdateSettingsPlayers = WebApi.scheduledUpdateSettingsPlayers or {}
function WebApi:ScheduleUpdateSettings(playerId)
	WebApi.scheduledUpdateSettingsPlayers[playerId] = true

	if WebApi.updateSettingsTimer then Timers:RemoveTimer(WebApi.updateSettingsTimer) end
	WebApi.updateSettingsTimer = Timers:CreateTimer(10, function()
		WebApi.updateSettingsTimer = nil
		WebApi:ForceSaveSettings()
		WebApi.scheduledUpdateSettingsPlayers = {}
	end)
end

function WebApi:ForceSaveSettings(_playerId)
	local players = {}
	for playerId = 0, 23 do
		if PlayerResource:IsValidPlayerID(playerId) and (WebApi.scheduledUpdateSettingsPlayers[playerId] or _playerId == playerId) then
			local settings = WebApi.playerSettings[playerId]
			if next(settings) ~= nil then
				local steamId = tostring(PlayerResource:GetSteamID(playerId))
				table.insert(players, { steamId = steamId, settings = settings })
			end
		end
	end
	WebApi:Send("match/update-settings", { players = players })
end

function WebApi:AfterMatch(winnerTeam)
	if not isTesting then
		if GameRules:IsCheatMode() then return end
		if GameRules:GetDOTATime(false, true) < 60 then return end
	end

	if winnerTeam < DOTA_TEAM_FIRST or winnerTeam > DOTA_TEAM_CUSTOM_MAX then return end
	if winnerTeam == DOTA_TEAM_NEUTRALS or winnerTeam == DOTA_TEAM_NOTEAM then return end

	local indexed_teams = {
		DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS
	}

	local requestBody = {
		customGame = WebApi.customGame,
		matchId = isTesting and RandomInt(1, 10000000) or tonumber(tostring(GameRules:GetMatchID())),
		duration = math.floor(GameRules:GetDOTATime(false, true)),
		mapName = GetMapName(),
		winner = winnerTeam,

		teams = {},
	}

	for _, team in pairs(indexed_teams) do
		local team_data = {
			players = {},
			teamId = team
		}
		for n = 1, PlayerResource:GetPlayerCountForTeam(team) do
			local playerId = PlayerResource:GetNthPlayerIDOnTeam(team, n)
			if PlayerResource:IsValidTeamPlayerID(playerId) and not PlayerResource:IsFakeClient(playerId) then
				local player_data = {
					playerId = playerId,
					steamId = tostring(PlayerResource:GetSteamID(playerId)),
					team = team,

					heroName = PlayerResource:GetSelectedHeroName(playerId),
					pickReason = SmartRandom.PickReasons[playerId] or (PlayerResource:HasRandomed(playerId) and "random" or "pick"),
					kills = PlayerResource:GetKills(playerId),
					deaths = PlayerResource:GetDeaths(playerId),
					assists = PlayerResource:GetAssists(playerId),
					level = 0,
					items = {},
				}

				local hero = PlayerResource:GetSelectedHeroEntity(playerId)
				if IsValidEntity(hero) then
					player_data.level = hero:GetLevel()
				end
				table.insert(team_data.players, player_data)
			end
		end
		table.insert(requestBody.teams, team_data)
	end

	if #requestBody.teams[1].players + #requestBody.teams[2].players >= 5 then
		print("Sending aftermatch request: ", #requestBody.teams[1].players + #requestBody.teams[2].players)
		WebApi:Send("match/after", requestBody)
	else
		print("Aftermatch send failed: ", #requestBody.teams[1].players + #requestBody.teams[2].players)
	end
end

function WebApi:AfterMatchTeam(team_number, is_pve)
	if not IsInToolsMode() then
		if GameRules:IsCheatMode() or PartyMode.party_mode_enabled or PartyMode.tournament then return end
		if GameRules:GetDOTATime(false, true) < 60 then return end
		-- TODO: checks for sufficient player count (full lobby for pvp)
	end
	print("TEAM", team_number, " FINISHED AT RANK", GameMode.nRank)

	local loseInfo = GameMode.teamLoseInfo[team_number]
	local requestBody = {
		mapName = GetMapName(),
		matchId = WebApi.matchId,
		isPvp = not is_pve,
		team = {
			teamId = team_number,
			round = loseInfo.round,
			time = loseInfo.time,
			-- TODO: calculate that
			matchPlace = GameMode.nRank - 1,  -- backend is 0-indexed
			otherTeamsAvgMMR = WebApi:GetOtherTeamsAverageRating(team_number),
		},
	}
	local players = {}
	for n = 1, PlayerResource:GetPlayerCountForTeam(team_number) do
		local playerId = PlayerResource:GetNthPlayerIDOnTeam(team_number, n)
		local abilities = HeroBuilder:GetPlayerAbilities(playerId)
		local round_death_data = HeroBuilder:GetPlayerRoundDeaths(playerId)
		local items = HeroBuilder:GetPlayerItems(playerId)
		table.insert(players, {
			playerId = playerId,
			steamId = tostring(PlayerResource:GetSteamID(playerId)),
			innate = abilities.innate,
			abilities = abilities.default,
			roundDeaths = round_death_data,
			items = items,
			otherPlayersAvgMMR = WebApi:GetOtherPlayersAverageRating(playerId),
			earlyLeaver = (GameMode.nRank > teams_layout[GetMapName()].max_fortune_rank),
			mastery = WearFunc.Masteries[playerId] and WearFunc.Masteries[playerId].itemName or nil
		})
	end
	requestBody.team.players = players
	table.print(requestBody.team.players)
	WebApi:Send(
		not GameMode.bGameHasWinner and "match/after_match_team" or "match/set_match_player_round_data",
		requestBody,
		function(resp)
			if not resp then return end
			for steamId, data in pairs(resp.players) do
				if steamId == "0" then return end
				local playerId = Battlepass.playerid_map[steamId]
				local place = not GameMode.bGameHasWinner and GameMode.nRank + 1 or GameMode.nRank
				local dataForClient = {
					mmr_changes = data.ratingChange,
					bp_level_changes = data.battlepassChange.level,
					bp_exp_changes = {
						old = {
							min = BP_PlayerProgress:GetCurrentExp(playerId),
							max = BP_PlayerProgress:GetRequiredExp(playerId),
						},
						new = {
							min = data.battlepassChange.exp.new,
							max = data.battlepassChange.exp.levelup_requirement,
						},
					},
					top = {
						value = place,
						exp = BP_PlayerProgress:GetBPExpByTop(place, playerId),
					},
					old_daily_limit = data.battlepassChange.exp.daily_exp_current - data.battlepassChange.exp.change,
					new_daily_limit = data.battlepassChange.exp.daily_exp_current,
					daily_limit = data.battlepassChange.exp.daily_exp_limit,
				}
				if GameMode.nValidTeamNumber == 1 then
					dataForClient["rounds"] = {
						value = loseInfo.round,
						exp = BP_PlayerProgress:GetBPExpByRounds(loseInfo.round),
					};
				end
				CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerId), 'end_game:init_end_game_results', dataForClient)

				BP_PlayerProgress.players[steamId].level = data.battlepassChange.level.new
				BP_PlayerProgress.players[steamId].current_exp = data.battlepassChange.exp.new
				BP_PlayerProgress.players[steamId].required_exp = data.battlepassChange.exp.levelup_requirement
				BP_PlayerProgress:ChangeGlory(playerId, data.battlepassChange.glory.change)
				BP_PlayerProgress:UpdatePlayerInfo(playerId)
			end
			print("Remote sending successful")
			table.print(resp)
		end,
		function(err)
			print("Remote sending error: ", err)
			table.print(err)
		end
	)
end

function WebApi:GetOtherTeamsAverageRating(target_team_number)
	local rating_average = 1500
	local rating_total = 0
	local rating_count = 0

	if IsInToolsMode() then return rating_average end
	if not WebApi.player_ratings then return rating_average end

	for id, ratingMap in pairs(WebApi.player_ratings) do
		if PlayerResource:GetTeam(id) ~= target_team_number then
			rating_total = rating_total + (ratingMap[mapName] or 1500)
			rating_count = rating_count + 1
		end
	end

	if rating_count > 0 then
		rating_average = rating_total / rating_count
	end

	return rating_average
end

function WebApi:GetOtherPlayersAverageRating(player_id)
	local rating_average = 1500
	local rating_total = 0
	local rating_count = 0

	if IsInToolsMode() then return rating_average end

	for id, ratingMap in pairs(WebApi.player_ratings or {}) do
		if id ~= player_id then
			rating_total = rating_total + (ratingMap[mapName] or 1500)
			rating_count = rating_count + 1
		end
	end

	if rating_count > 0 then
		rating_average = rating_total / rating_count
	end

	return rating_average
end

RegisterGameEventListener("player_connect_full", function()
	print("LOADED WEBAPI")
	if WebApi.firstPlayerLoaded then return end
	WebApi.firstPlayerLoaded = true
	WebApi:BeforeMatch()
end)
