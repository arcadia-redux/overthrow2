local function getPlayerIdBySteam(id)
	for i = 0, 23 do
		if PlayerResource:IsValidPlayerID(i) and tostring(PlayerResource:GetSteamID(i)) == id then
			return i
		end
	end

	return -1
end

local patreonLevels = {}
local sameHeroDayHoursLeft
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

	local request = CreateHTTPRequestScriptVM("GET", "http://163.172.174.77:8000/api/same-hero-day")
	request:Send(function(response)
		if response.StatusCode ~= 200 then return end
		sameHeroDayHoursLeft = json.decode(response.Body)

		CustomNetTables:SetTableValue(
			"game_state",
			"is_same_hero_day",
			{ enable = sameHeroDayHoursLeft ~= nil }
		)
		if sameHeroDayHoursLeft then
			GameRules:SetSameHeroSelectionEnabled(true)
		end
	end)
end

function GetPlayerPatreonLevel(playerId)
	return patreonLevels[playerId] or 0
end

function HasPlayerPatreonBonusesEnabled(playerId)
	local patreonBonuses = CustomNetTables:GetTableValue("game_state", "patreon_bonus") or {}
	return patreonBonuses[playerId] ~= 0
end

function SendSameHeroDayMessage()
	if sameHeroDayHoursLeft then
		GameRules:SendCustomMessage("Same Hero Saturday has " .. math.ceil(sameHeroDayHoursLeft) .. " hours left. All Players have Patreon benefits today. Thanks for playing.", -1, -1)
	end
end

function GivePlayerPatreonBonus(playerId)
	local hero = PlayerResource:GetSelectedHeroEntity(playerId)
	if sameHeroDayHoursLeft == nil and GetPlayerPatreonLevel(playerId) < 1 then return end

	if hero:HasItemInInventory("item_boots") then
		hero:ModifyGold(500, false, 0)
	else
		hero:AddItemByName("item_boots")
	end
end

function TakePlayerPatreonBonus(playerId)
	local hero = PlayerResource:GetSelectedHeroEntity(playerId)
	if sameHeroDayHoursLeft == nil and GetPlayerPatreonLevel(playerId) < 1 then return end

	if hero:HasItemInInventory("item_boots") then
		for i = DOTA_ITEM_SLOT_1, DOTA_STASH_SLOT_6 do
			local item = hero:GetItemInSlot(i)
			if item and item:GetAbilityName() == "item_boots" then
				UTIL_Remove(item)
				break
			end
		end
	else
		hero:ModifyGold(-500, false, 0)
	end
end

CustomGameEventManager:RegisterListener("set_patreon_bonus", function(_, data)
	local playerId = data.PlayerID
	local hero = PlayerResource:GetSelectedHeroEntity(playerId)
	if not hero then return end

	local enable = data.enable == 1
	local patreonBonuses = CustomNetTables:GetTableValue("game_state", "patreon_bonus") or {}
	local oldState = patreonBonuses[tostring(playerId)] ~= 0
	if oldState == data.enable then return end

	patreonBonuses[tostring(playerId)] = enable
	CustomNetTables:SetTableValue("game_state", "patreon_bonus", patreonBonuses)

	if enable then
		GivePlayerPatreonBonus(playerId)
	else
		TakePlayerPatreonBonus(playerId)
	end
end)
