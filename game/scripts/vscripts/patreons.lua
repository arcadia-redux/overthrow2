Patreons = Patreons or {}
Patreons.playerLevels = Patreons.playerLevels or {}

CustomGameEventManager:RegisterListener("update_emblem", Dynamic_Wrap(Patreons, "UpdateEmblem"))
CustomGameEventManager:RegisterListener("toggle_emblem", Dynamic_Wrap(Patreons, "ToggleEmblem"))

function Patreons:SetPlayerLevel(playerId, level)
	Patreons.playerLevels[playerId] = level
end

function Patreons:GetPlayerLevel(playerId, level)
	return Patreons.playerLevels[playerId] or 0
end

function Patreons:SetSameHeroDayHoursLeft(value)
	Patreons.sameHeroDayHoursLeft = value

	CustomNetTables:SetTableValue(
		"game_state",
		"is_same_hero_day",
		{ enable = value ~= nil }
	)

	GameRules:SetSameHeroSelectionEnabled(value ~= nil)
end

function Patreons:SendSameHeroDayMessage()
	if Patreons.sameHeroDayHoursLeft then
		GameRules:SendCustomMessage("Same Hero Saturday has " .. math.ceil(Patreons.sameHeroDayHoursLeft) .. " hours left. All Players have Patreon benefits today. Thanks for playing.", -1, -1)
	end
end

function Patreons:GetPlayerBonusesEnabled(playerId)
	local patreonBonuses = CustomNetTables:GetTableValue("game_state", "patreon_bonus") or {}
	return patreonBonuses[playerId] ~= 0
end

function Patreons:GiveOnSpawnBonus(playerId)
	local hero = PlayerResource:GetSelectedHeroEntity(playerId)
	if sameHeroDayHoursLeft == nil and Patreons:GetPlayerLevel(playerId) < 1 then return end

	hero:AddNewModifier(hero, nil, "modifier_donator", {patron_level = Patreons:GetPlayerLevel(playerId)})

	if hero:HasItemInInventory("item_boots") then
		hero:ModifyGold(500, false, 0)
	else
		hero:AddItemByName("item_boots")
	end
end

function Patreons:TakeOnSpawnBonus(playerId)
	local hero = PlayerResource:GetSelectedHeroEntity(playerId)
	if sameHeroDayHoursLeft == nil and Patreons:GetPlayerLevel(playerId) < 1 then return end

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
		Patreons:GiveOnSpawnBonus(playerId)
	else
		Patreons:TakeOnSpawnBonus(playerId)
	end
end)

function Patreons:UpdateEmblem(args)
	print("Update Emblem:", args.color)
	local hero = PlayerResource:GetSelectedHeroEntity(args.ID)
	local table = {}
	table["Default (White)"] = Vector(255, 255, 255)
	table["Red"] = Vector(200, 0, 0)
	table["Green"] = Vector(0, 200, 0)
	table["Blue"] = Vector(0, 0, 200)
	table["Cyan"] = Vector(0, 200, 200)
	table["Yellow"] = Vector(200, 200, 0)
	table["Pink"] = Vector(200, 170, 185)

	hero.patreon_emblem_color = table[args.color]
end

function Patreons:ToggleEmblem(args)
	local hero = PlayerResource:GetSelectedHeroEntity(args.ID)
	hero.patreon_emblem_enabled = args.bEmblem
end
