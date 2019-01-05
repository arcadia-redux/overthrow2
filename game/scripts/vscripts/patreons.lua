Patreons = Patreons or {}
Patreons.playerLevels = Patreons.playerLevels or {}

patreonBonsuses = patreonBonsuses or {}

CustomGameEventManager:RegisterListener("patreon_update_emblem", Dynamic_Wrap(Patreons, "UpdateEmblem"))
CustomGameEventManager:RegisterListener("patreon_toggle_emblem", Dynamic_Wrap(Patreons, "ToggleEmblem"))

function GetPlayerPatreonBonuses(playerId)
	local bonuses = patreonBonsuses[playerId]

	if bonuses == nil then
		bonuses = {
			emblemColor = "White",
			emblemEnabled = false,
			bootsEnabled = Patreons:GetPlayerLevel(playerId) > 0
		}

		patreonBonsuses[playerId] = bonuses

		UpdatePlayerBonuses()
	end

	return bonuses
end

function UpdatePlayerBonuses()
	CustomNetTables:SetTableValue("game_state", "patreon_bonuses", patreonBonsuses)
end

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

CustomGameEventManager:RegisterListener("patreon_toggle_boots", function(_, data)
	local playerId = data.PlayerID
	local hero = PlayerResource:GetSelectedHeroEntity(playerId)
	if not hero then return end

	local enable = data.enabled == 1
	local playerBonuses = GetPlayerPatreonBonuses(playerId)
	if playerBonuses.bootsEnabled == enable then return end

	playerBonuses.bootsEnabled = enable

	UpdatePlayerBonuses()

	if enable then
		Patreons:GiveOnSpawnBonus(playerId)
	else
		Patreons:TakeOnSpawnBonus(playerId)
	end
end)

function Patreons:UpdateEmblem(args)
	--print("Update Emblem:", args.color)
	local hero = PlayerResource:GetSelectedHeroEntity(args.PlayerID)
	local table = {}
	table["White"] = Vector(255, 255, 255)
	table["Red"] = Vector(200, 0, 0)
	table["Green"] = Vector(0, 200, 0)
	table["Blue"] = Vector(0, 0, 200)
	table["Cyan"] = Vector(0, 200, 200)
	table["Yellow"] = Vector(200, 200, 0)
	table["Pink"] = Vector(200, 170, 185)
	table["Maroon"] = Vector(128, 0, 0)
	table["Brown"] = Vector(154, 99, 36)
	table["Olive"] = Vector(0, 128, 128)
	table["Teal"] = Vector(70, 153, 144)
	table["Navy"] = Vector(0, 0, 117)
	table["Black"] = Vector(0, 0, 0)
	table["Orange"] = Vector(245, 130, 49)
	table["Lime"] = Vector(191, 239, 69)
	table["Purple"] = Vector(145, 30, 180)
	table["Magenta"] = Vector(240, 50, 230)
	table["Grey"] = Vector(169, 169, 169)
	table["Apricot"] = Vector(255, 216, 177)
	table["Beige"] = Vector(255, 250, 200)
	table["Mint"] = Vector(170, 255, 195)
	table["Lavender"] = Vector(230, 190, 255)

	hero.patreon_emblem_color = table[args.color]

	GetPlayerPatreonBonuses(args.PlayerID).emblemColor = args.color
	UpdatePlayerBonuses()
end

function Patreons:ToggleEmblem(args)
	local hero = PlayerResource:GetSelectedHeroEntity(args.PlayerID)
	hero.patreon_emblem_enabled = args.enabled

	GetPlayerPatreonBonuses(args.PlayerID).emblemEnabled = args.enabled
	UpdatePlayerBonuses()
end
