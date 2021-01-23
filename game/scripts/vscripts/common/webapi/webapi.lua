WebApi = WebApi or {}
WebApi.playerSettings = WebApi.playerSettings or {}

local isTesting = IsInToolsMode() and true or false
for playerId = 0, 23 do
	WebApi.playerSettings[playerId] = WebApi.playerSettings[playerId] or {}
end
WebApi.matchId = IsInToolsMode() and RandomInt(-10000000, -1) or tonumber(tostring(GameRules:Script_GetMatchID()))
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
		data.customGame = WebApi.customGame
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
		WebApi.playerMatchesCount = {}
		
		for _, player in ipairs(data.players) do
			local playerId = GetPlayerIdBySteamId(player.steamId)
			if player.rating then
				WebApi.player_ratings[playerId] = {[GetMapName()] = player.rating}
			end
			if player.supporterState then
				Supporters:SetPlayerState(playerId, player.supporterState)
			end
			if player.masteries then
				BP_Masteries:SetMasteriesForPlayer(playerId, player.masteries)
			end
			if player.settings then
				WebApi.playerSettings[playerId] = player.settings
			end
			if player.stats then
				WebApi.playerMatchesCount[playerId] = (player.stats.wins or 0) + (player.stats.loses or 0)
			end
			publicStats[playerId] = {
				streak = player.streak.current or 0,
				bestStreak = player.streak.best or 0,
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

	local sorted_teams = COverthrowGameMode:GetSortedTeams()

	local requestBody = {
		customGame = WebApi.customGame,
		matchId = isTesting and RandomInt(1, 10000000) or tonumber(tostring(GameRules:Script_GetMatchID())),
		duration = math.floor(GameRules:GetDOTATime(false, true)),
		mapName = GetMapName(),
		winner = winnerTeam,
		teams = {},
	}

	for place, team_score in pairs(sorted_teams) do
		local team = team_score.team
		local team_data = {
			players = {},
			otherTeamsAvgMMR = WebApi:GetOtherTeamsAverageRating(team),
			place = place,
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
				}

				local hero = PlayerResource:GetSelectedHeroEntity(playerId)
				if IsValidEntity(hero) then
					player_data.level = hero:GetLevel()
				end

				table.insert(team_data.players, player_data)
			end
		end
		if team_data.players and #team_data.players > 0 then
			table.insert(requestBody.teams, team_data)
		end
	end
	local resulting_player_count = WebApi:GetResultingPlayerCount(requestBody.teams)
	if isTesting or resulting_player_count >= 5 then
		print("Sending aftermatch request: ")
		WebApi:Send("match/after", requestBody)
	else
		print("Aftermatch send failed: ", resulting_player_count)
	end
end


function WebApi:GetResultingPlayerCount(data)
	local count = 0
	for _, team in pairs(data) do
		count = count + #team.players
	end
	return count
end

function WebApi:GetOtherTeamsAverageRating(target_team_number)
	local rating_average = 1500
	local rating_total = 0
	local rating_count = 0

	if IsInToolsMode() then return rating_average end
	if not WebApi.player_ratings then return rating_average end

	for id, ratingMap in pairs(WebApi.player_ratings) do
		if PlayerResource:GetTeam(id) ~= target_team_number then
			rating_total = rating_total + (ratingMap[GetMapName()] or 1500)
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
