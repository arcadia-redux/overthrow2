local patreonLevels =  {
	["76561198054179075"] = 1,
}

function GetPlayerPatreonLevel(playerId)
	local steamId = tostring(PlayerResource:GetSteamID(playerId))
	return patreonLevels[steamId] or 0
end
