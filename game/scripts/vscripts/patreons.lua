local function getPlayerIdBySteam(id)
	for i = 0, 23 do
		if PlayerResource:IsValidPlayerID(i) and tostring(PlayerResource:GetSteamID(i)) == id then
			return i
		end
	end

	return -1
end

local patreonLevels =  {}
function FetchPatreons()
	local ids = {}
	for i = 0, 23 do
		if PlayerResource:IsValidPlayerID(i) then
			table.insert(ids, "id=" .. tostring(PlayerResource:GetSteamID(i)))
		end
	end

	local request = CreateHTTPRequestScriptVM("GET", "http://163.172.174.77:8000/api/players?" .. table.concat(ids, "&"))
	request:Send(function(response)
		if response.StatusCode ~= 200 then return end
		local data = json.decode(response.Body)

		for _,player in ipairs(data) do
			patreonLevels[getPlayerIdBySteam(player.steamId)] = player.patreonLevel
		end
		CustomNetTables:SetTableValue("game_state", "patreons", patreonLevels)
	end)
end

function GetPlayerPatreonLevel(playerId)
	return patreonLevels[playerId] or 0
end
