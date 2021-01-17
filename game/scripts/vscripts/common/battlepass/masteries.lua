-- Links modifiers for each mastery

BP_Masteries = BP_Masteries or {}
MASTERY_LEVEL_MAX = 3
PRICE_FOR_RANDOM_MASTERY = 5

function BP_Masteries:Init()
	print("BP_Masteries INIT")
	self.playersOwnedMasteries = {}
	self.manuallyEquippedMasteries = {}
	for playerId = 0, 24 do
		self.playersOwnedMasteries[playerId] = {}
	end
	
	self.mastery_types = {
		"regeneration",
		"manafication",
		"champion",
		"brute",
		"nimble",
		"magician",
		"sprinter",
		"celerity",
		"colossus",
		"heavy_armor",
		"vampirism",
		"spell_vampirism",
		"cleave",
		"abjuration",
		"giant_reach",
		"spellcraft",
		"evasion",
		"might",
		"luck",
		"tenacity",
		"control",
		"revenge",
		"ferocity",
		"ascension",
		"glass_cannon",
		"acrobatics",
		"countermagic",
		"iron_body",
		"initiative",
		"speed_of_thought"
	}

	self.cumulative_masteries = {
		revenge = true
	}

	-- Link mastery modifiers
	LinkLuaModifier("modifier_chc_mastery_initiative_buff", "heroes/masteries/initiative", LUA_MODIFIER_MOTION_NONE)
	for _, mastery_type in pairs(self.mastery_types) do
		LinkLuaModifier("modifier_chc_mastery_"..mastery_type, "heroes/masteries/"..mastery_type, LUA_MODIFIER_MOTION_NONE)
		for level = 1, MASTERY_LEVEL_MAX do
			LinkLuaModifier("modifier_chc_mastery_"..mastery_type.."_"..level, "heroes/masteries/"..mastery_type, LUA_MODIFIER_MOTION_NONE)
		end
	end
	
	CustomGameEventManager:RegisterListener("masteries:upgrade_random_mastery",function(_, keys)
		self:UpgradeRandomMastery(keys)
	end)
	CustomGameEventManager:RegisterListener("masteries:upgrade_mastery",function(_, keys)
		self:UpgradeMastery(keys)
	end)
	CustomGameEventManager:RegisterListener("masteries:player_equip_mastery",function(_, keys)
		self:PlayerEquipMastery(keys)
	end)
end

function BP_Masteries:UpdateEquippedMastery(playerId)
	if WearFunc.Masteries[playerId] then
		local masteryName = WearFunc.Masteries[playerId].itemName
		local masteryLevel = BP_Masteries:GetMasteryLevel(playerId, masteryName)
		if masteryLevel < 1 then return end
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerId), "masteries:equip_mastery", {
			name = masteryName,
			tier = masteryLevel,
			manually = BP_Masteries.manuallyEquippedMasteries[playerId]
		})
	end
end

function BP_Masteries:PlayerEquipMastery(data)
	local playerId = data.PlayerID
	if not playerId then return end
	if self.manuallyEquippedMasteries[playerId] then return end
	self.manuallyEquippedMasteries[playerId] = true
	WearFunc.Equip_Masteries(playerId, data.masteryName)
	--BP_Inventory:EquipItem({PlayerID = playerId, itemName = data.masteryName})
end

function BP_Masteries:_UpgradeMasteryPull(playerId, tier)
	if tier > MASTERY_LEVEL_MAX then return end
	local pullTier = {}
	local counter = 0
	for _, masteryName in pairs(self.mastery_types) do
		if BP_Inventory.item_definitions[masteryName].tiers[tier - 1] then
			pullTier[counter] = masteryName
			counter = counter + 1
		end
	end
	for id, tryName in pairs(pullTier) do
		if self.playersOwnedMasteries[playerId][tryName] and self.playersOwnedMasteries[playerId][tryName][tier] then
			pullTier[id] = nil
			counter = counter - 1
		end
	end
	if counter > 0 then
		return {name = table.random(pullTier), tier = tier}
	else
		return BP_Masteries:_UpgradeMasteryPull(playerId, tier + 1)
	end
end

function BP_Masteries:GetMasteryLevel(playerId, masteryName)
	local tier = 0
	local masteryData = self.playersOwnedMasteries[playerId][masteryName]
	if masteryData then
		for _tier, _ in pairs(masteryData) do
			if _tier > tier then tier = _tier end
		end
	end
	return tier
end

function BP_Masteries:UpdateMasteriesForPlayer(playerId, newMastery)
	if not self.playersOwnedMasteries[playerId] then return end
	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerId), "masteries:update_masteries", {
		masteries = self.playersOwnedMasteries[playerId],
		newMastery = newMastery,
	})
end

function BP_Masteries:UpdateMasteryForPlayer(playerId, masteryName, tier, cost)
	BP_Masteries:UpdateFortune(playerId)

	BP_Masteries:UpgradeMasteryBackend({
		steamId = Battlepass.steamid_map[playerId],
		masteryName = masteryName,
		masteryLevel = tier,
		fortuneCost = cost
	}, tier == 1)

	if WearFunc.Masteries[playerId] and WearFunc.Masteries[playerId].itemName == masteryName then
		WearFunc.Equip_Masteries(playerId, masteryName)
	end
end

function BP_Masteries:UpgradeRandomMastery(data)
	local playerId = data.PlayerID
	local newMasteryData = self:_UpgradeMasteryPull(playerId, 1)
	if newMasteryData then
		local oldFotune = BP_PlayerProgress:GetFortune(playerId)
		if not oldFotune or oldFotune < PRICE_FOR_RANDOM_MASTERY then return end
		
		if not self.playersOwnedMasteries[playerId][newMasteryData.name] then 
			self.playersOwnedMasteries[playerId][newMasteryData.name] = {}
		end
		self.playersOwnedMasteries[playerId][newMasteryData.name][newMasteryData.tier] = true
		BP_PlayerProgress:SetFortune(playerId, oldFotune - PRICE_FOR_RANDOM_MASTERY)
		BP_Masteries:UpdateMasteryForPlayer(playerId, newMasteryData.name, newMasteryData.tier, PRICE_FOR_RANDOM_MASTERY)
	else
		print("PLAYER OWNED ALL PERKS")
	end
end

function BP_Masteries:UpgradeMastery(data)
	local playerId = data.PlayerID
	if not table.contains(self.mastery_types, data.name) then return end
	local currentLevel = self:GetMasteryLevel(playerId, data.name)
	if MASTERY_LEVEL_MAX + 1 <= currentLevel or currentLevel == 0 then return end
	if not BP_Inventory.item_definitions[data.name].tiers[currentLevel] then return end
	
	local cost = tonumber(BP_Inventory.item_definitions[data.name].tiers[currentLevel].price)
	local oldFotune = BP_PlayerProgress:GetFortune(playerId)
	
	if not oldFotune or oldFotune < cost then return end
	
	self.playersOwnedMasteries[playerId][data.name][currentLevel + 1] = true
	BP_PlayerProgress:SetFortune(playerId, oldFotune - cost)
	BP_Masteries:UpdateMasteryForPlayer(playerId, data.name, currentLevel + 1, cost)
end

function BP_Masteries:UpdateFortune(playerId)
	local playerFortune = BP_PlayerProgress:GetFortune(playerId)
	if not playerFortune then return end
	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerId), "masteries:update_fortune", { fortune = playerFortune })
end

function BP_Masteries:TakeOffMastery(hero, mastery)
	if not mastery then return end
	for level = 1, MASTERY_LEVEL_MAX do
		hero:RemoveModifierByName("modifier_chc_mastery_"..mastery.."_"..level)
	end
end

function BP_Masteries:EquipMastery(hero, mastery, level)
	if self.cumulative_masteries[mastery] then
		for cumulative_level = 1, level do
			hero:AddNewModifier(hero, nil, "modifier_chc_mastery_"..mastery.."_"..cumulative_level, {})
		end
	else
		hero:AddNewModifier(hero, nil, "modifier_chc_mastery_"..mastery.."_"..level, {})
	end
end

function BP_Masteries:SetMasteriesForPlayer(playerId, data)
	local result = {}
	for _, masteryData in pairs(data) do
		local masteryName = masteryData.masteryName
		if masteryName and BP_Inventory.item_definitions[masteryName] then
			if not result[masteryData.masteryName] then
				result[masteryData.masteryName] = {}
			end
			result[masteryData.masteryName][masteryData.masteryLevel] = masteryData.expirationDate and masteryData.expirationDate or true
		end
	end
	self.playersOwnedMasteries[playerId] = result
end

function BP_Masteries:UpgradeMasteryBackend(responseData, isPermanentMastery)
	WebApi:Send(
		isPermanentMastery and "battlepass/unlock_mastery" or "battlepass/upgrade_mastery",
		responseData,
		function(data)
			local playerId = Battlepass.playerid_map[responseData.steamId]
			if data.masteries then
				BP_Masteries:SetMasteriesForPlayer(playerId, data.masteries)
			end
			if data.fortune then
				BP_PlayerProgress:SetFortune(playerId, data.fortune)
				self:UpdateFortune(playerId)
			end
			BP_Masteries:UpdateMasteriesForPlayer(playerId, responseData.masteryName)
			print("Successfully upgraded masteries for player")
		end,
		function(e)
			print("error while upgrade masteries for player: ", e)
		end
	)
end
