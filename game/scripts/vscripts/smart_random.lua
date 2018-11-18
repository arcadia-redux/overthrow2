SmartRandom = SmartRandom or {}
SmartRandom.SmartRandomHeroes = SmartRandom.SmartRandomHeroes or {}
SmartRandom.AutoPickHeroes = SmartRandom.AutoPickHeroes or {}
SmartRandom.PickReasons = SmartRandom.PickReasons or {}

function SmartRandom:SetPlayerInfo(playerId, heroes, err)
	local table = CustomNetTables:GetTableValue("game_state", "smart_random") or {}
	SmartRandom.SmartRandomHeroes[playerId] = heroes
	table[playerId] = heroes or err
	CustomNetTables:SetTableValue("game_state", "smart_random", table)
end

local npc_heroes = LoadKeyValues("scripts/npc/npc_heroes.txt")
local function getReadableHeroName(name)
	return npc_heroes[name].workshop_guide_name or ""
end

local function pickRandomHeroFromList(playerId, list)
	local player = PlayerResource:GetPlayer(playerId)
	if not player then return end

	local picked = false
	for _,v in ipairs(ShuffledList(list)) do
		if not PlayerResource:IsHeroSelected(v) then
			UTIL_Remove(CreateHeroForPlayer(v, player))
			picked = true
			break
		end
	end

	if not picked then
		player:MakeRandomHeroSelection()
	end
end

function SmartRandom:SmartRandomHero(event)
	local playerId = event.PlayerID
	if GameRules:State_Get() > DOTA_GAMERULES_STATE_HERO_SELECTION then return end
	if PlayerResource:HasSelectedHero(playerId) then return end

	SmartRandom.PickReasons[playerId] = "smart-random"
	pickRandomHeroFromList(playerId, SmartRandom.SmartRandomHeroes[playerId] or {})

	GameRules:SendCustomMessage("%s1 has smart-randomed " .. getReadableHeroName(PlayerResource:GetSelectedHeroName(playerId)), playerId, -1)
end

function SmartRandom:PrepareAutoPick()
	local players = {}
	local heroes = {}
	for i = 0, 23 do
		if PlayerResource:IsValidPlayerID(i) then
			if PlayerResource:HasSelectedHero(i) then
				table.insert(heroes, PlayerResource:GetSelectedHeroName(i))
			else
				table.insert(players, tostring(PlayerResource:GetSteamID(i)))
			end
		end
	end

	SendWebApiRequest("auto-pick", { mapName = GetMapName(), players = players, selectedHeroes = heroes }, function(data)
		for _,player in ipairs(data.players) do
			local playerId = GetPlayerIdBySteamId(player.steamId)
			SmartRandom.AutoPickHeroes[playerId] = player.heroes
		end
	end)
end

function SmartRandom:AutoPick()
	for i = 0, 23 do
		if PlayerResource:IsValidPlayerID(i) and not PlayerResource:HasSelectedHero(i) then
			if PlayerResource:GetPlayer(i) then
				SmartRandom.PickReasons[i] = "auto"
				pickRandomHeroFromList(i, SmartRandom.AutoPickHeroes[i] or {})
				GameRules:SendCustomMessage("%s1 has auto-picked " .. getReadableHeroName(PlayerResource:GetSelectedHeroName(i)), i, -1)
			end
		end
	end
end

CustomGameEventManager:RegisterListener("smart_random_hero", Dynamic_Wrap(SmartRandom, "SmartRandomHero"))
