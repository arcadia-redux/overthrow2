--[[
Battlepass inventory system
Includes (but not limited to):
- consumables (shards, cards etc)
- equippable effects
- permanent items


Provides a shortcut to get player data via steamid:
	BP_Inventory["6787120897182"]
]]

BP_Inventory = BP_Inventory or {}

function BP_Inventory:Init()
	BP_Inventory.specs = LoadKeyValues("scripts/vscripts/common/battlepass/inventory/inventory_specs.kv")
	BP_Inventory.rarities = BP_Inventory.specs.Rarity
	--table.print(self.rarities)

	BP_Inventory.categories = BP_Inventory.specs.Category
	--table.print(self.categories)

	BP_Inventory.duplicate_glory = BP_Inventory.specs.DuplicateGlory
	--table.print(self.duplicate_glory)

	BP_Inventory.player_items = {}
	BP_Inventory.equipped_items = {}

	BP_Inventory.item_definitions = {}
	BP_Inventory.responseCollectionItems = {}
	BP_Inventory.responseCollectionTreasures = {}
	BP_Inventory.responseCollectionMasteries = {}

	for category, _ in pairs(BP_Inventory.categories) do
		local itemsData = LoadKeyValues("scripts/vscripts/common/battlepass/inventory/battlepass_items/"..category..".kv")
		for itemName, itemData in pairs(itemsData) do
			if category == "Masteries" then
				local tiersData = {}
				local prices = string.split(itemData.tiers.Prices, " ")
				for id, price in pairs(prices) do
					if not price ~= "0" then
						tiersData[id - 1] = {
							price = price,
						}
					end
				end
				itemData.tiers = tiersData;
				BP_Inventory.responseCollectionMasteries[itemName] = itemData;
				DeepPrintTable(BP_Inventory.responseCollectionMasteries[itemName]);
			else
				local _data = BP_Inventory.responseCollectionItems
				if category == "Treasures" then
					_data = BP_Inventory.responseCollectionTreasures
				end
				_data[itemName] = {
					Rarity = BP_Inventory.rarities[itemData.Rarity],
					Category = BP_Inventory.categories[category],
					Source = itemData.Source,
					Blocked = itemData.Blocked,
					NoAction = itemData.NoAction,
					OverrideCategoty = itemData.OverrideCategoty and BP_Inventory.categories[itemData.OverrideCategoty],
					HideInCollection = itemData.HideInCollection,
					Season = itemData.Season,
				}
			end
			BP_Inventory.item_definitions[itemName] = itemData
			BP_Inventory.item_definitions[itemName].Category = category
		end
	end
	BP_Inventory.bCollectionLoaded = true
	print("ITEMS BP")
	--table.print(self.item_definitions)

	CustomGameEventManager:RegisterListener("battlepass_inventory:get_collection",function(_, keys)
		self:InitBaseCollection(keys)
	end)
	CustomGameEventManager:RegisterListener("battlepass_inventory:equip_item",function(_, keys)
		self:EquipItem(keys)
	end)
	CustomGameEventManager:RegisterListener("battlepass_inventory:take_off_item",function(_, keys)
		self:TakeOffItem(keys)
	end)
	CustomGameEventManager:RegisterListener("battlepass_inventory:buy_item_by_coins",function(_, keys)
		self:BuyItems(keys)
	end)
	CustomGameEventManager:RegisterListener("battlepass_inventory:open_treasure",function(_, keys)
		self:OpenTreasure(keys)
	end)
	CustomGameEventManager:RegisterListener("battlepass_inventory:save_only_equipped_items",function(_, keys)
		self:SaveOnlyEquippedItems(keys)
	end)
end

function BP_Inventory:IsItemOwned(itemName, playerSteamId)
	for id, itemData in pairs(self.player_items[playerSteamId]) do
		if itemData.itemName == itemName then
			return {id, itemData}
		end
	end
end

function BP_Inventory:OnDataArrival(players_inventories, equipped_items)
	BP_Inventory.player_items = players_inventories
	for playerId = 0, 24 do
		local steamId = Battlepass.steamid_map[playerId]
		if PlayerResource:GetPlayer(playerId) and steamId and not BP_Inventory.player_items[steamId] then
			BP_Inventory.player_items[steamId] = {}
		end
	end
	BP_Inventory.equipped_items = equipped_items
	for steam_id, items in pairs(players_inventories) do
		BP_Inventory:UpdateLocalItems(steam_id)
		BP_Inventory:ProcessPlayerItems(steam_id, items)
	end
end

function BP_Inventory:UpdateLocalItems(steam_id)
	if not BP_Inventory.player_items[steam_id] then
		Timers:CreateTimer(1, function()
			BP_Inventory:UpdateLocalItems(steam_id)
		end)
		return
	end

	local playerId = Battlepass.playerid_map[steam_id]
	local playerMMR = 1500
	if WebApi.player_ratings and WebApi.player_ratings[playerId] and WebApi.player_ratings[playerId][GetMapName()] then
		playerMMR = WebApi.player_ratings[playerId][GetMapName()]
	end

	local boosterStatus = Supporters:GetLevel(playerId)
	local addingItemFilter = function(itemName, itemData , varName, varValue)
		if itemData.Source and itemData.Source[varName] and itemData.Source[varName] <= varValue then
			table.insert(BP_Inventory.player_items[steam_id], {
				steamId = steam_id,
				itemName = itemName,
				count = 1,
			})
		end
	end

	for itemName, itemData in pairs (self.item_definitions) do
		addingItemFilter(itemName, itemData, "DOTAU_MMR", playerMMR)
		addingItemFilter(itemName, itemData, "SupporterState", boosterStatus)
	end
end

function BP_Inventory:ProcessPlayerItems(steam_id, items)
	for i, item in pairs(items) do
		item.id = nil
		local definition = self.item_definitions[item.itemName]
		if definition then
			item.ID = definition.ID
			item.rarity = self.rarities[definition.Rarity]
			item.category = self.categories[definition.Category]
		end
		--print("[" .. i .. "] <"..steam_id.."> has item:")
		--table.print(item)
	end
end

function BP_Inventory:UpdateLocalPlayerInfo(playerId)
	BP_PlayerProgress:UpdatePlayerInfo(playerId)
	self:UpdateAvailableItems(playerId)
	local steamId = Battlepass.steamid_map[playerId]
	if not self.equipped_items[steamId] then return end
	for category, itemsList in pairs(self.equipped_items[steamId]) do
		if not (category == "id") and not (category == "steamId") and not (category == "equippedMasteries") then
			for _, itemName in pairs(itemsList) do
				self:EquipItem({PlayerID = Battlepass.playerid_map[steamId], itemName = itemName, skipSave = true})
			end
		end
	end
end

function BP_Inventory:UpdateAvailableItems(playerId)
	local responseItems = {}
	for _, itemData in pairs(self.player_items[Battlepass.steamid_map[playerId]]) do
		table.insert(responseItems, {
			itemName = itemData.itemName,
			count = itemData.count,
		})
	end
	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerId), "battlepass_inventory:update_player_items", responseItems)
end

function BP_Inventory:UpdateEquippedItems(playerId)
	local steamId = Battlepass.steamid_map[playerId]
	if self.equipped_items[steamId] then
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerId), "battlepass_inventory:update_equipped_items", self.equipped_items[steamId])
	end
end

BP_Inventory.scheduledSaveEquippedItems = BP_Inventory.scheduledSaveEquippedItems or {}
function BP_Inventory:SaveEquippedItems(_playerId)
	BP_Inventory.scheduledSaveEquippedItems[_playerId] = true

	if BP_Inventory.saveItemsTimer then Timers:RemoveTimer(BP_Inventory.saveItemsTimer) end

	BP_Inventory.saveItemsTimer = Timers:CreateTimer(10, function()
		BP_Inventory.saveItemsTimer = nil
		local dataForSaveEquippedItems = {}
		for playerId = 0, 23 do
			if PlayerResource:IsValidPlayerID(playerId) and BP_Inventory.scheduledSaveEquippedItems[playerId] then
				local steamId = Battlepass.steamid_map[playerId]
				dataForSaveEquippedItems[steamId] = {}
				for key, data in pairs(self.equipped_items[steamId]) do
					if string.match(key, "equipped") then
						dataForSaveEquippedItems[steamId][key] = data
					end
				end
			end
		end
		self:SetPlayerEquippedItems({equippedItems = dataForSaveEquippedItems})
		BP_Inventory.scheduledSaveEquippedItems = {}
	end)
end

function BP_Inventory:GetItemsPoolForPlayer(playerId, treasureName)
	local itemPool = {}
	local poolForWheel = {}
	for itemName, itemData in pairs(BP_Inventory.item_definitions) do
		if itemData.Source and itemData.Source.Treasure and itemData.Source.Treasure == treasureName then
			table.insert(poolForWheel, itemName)
			itemPool[itemName] = {}
			if itemData.ChanceToPull then
				itemPool[itemName].chanceToPull = itemData.ChanceToPull
			end
			itemPool[itemName].blocked = itemData.Blocked
		end
	end
	local backPool = {}
	local bHasCommonItems = false
	local addItemInPool = function(nChanceToPull, itemName)
		local bAddItem = true
		if nChanceToPull then
			bAddItem = RollPercentage(nChanceToPull)
		end
		if bAddItem then
			table.insert(backPool, itemName)
		end
	end
	for itemName, itemData in pairs(itemPool) do
		if not self:IsItemOwned(itemName, Battlepass.steamid_map[playerId]) and not itemData.blocked then
			if not itemData.chanceToPull then
				bHasCommonItems = true
			end
			addItemInPool(itemData.chanceToPull, itemName)
		end
	end
	if #backPool > 0 then
		if not bHasCommonItems then
			for itemName, itemData in pairs(itemPool) do
				if not itemData.chanceToPull and not itemData.blocked then
					table.insert(backPool, itemName)
				end
			end
		end
	elseif #backPool == 0 then
		for itemName,itemData in pairs(itemPool) do
			if not itemData.blocked then
				addItemInPool(itemData.chanceToPull, itemName)
			end
		end
	end

	return { backPool = backPool, poolForWheel = poolForWheel }
end

function BP_Inventory:OpenTreasure(data)
	local playerSteamId = Battlepass.steamid_map[data.PlayerID]
	local itemInInventory = self:IsItemOwned(data.treasureName, playerSteamId)
	if not itemInInventory then return end

	if data.treasureName == "gift_free_treasure" then
		if WebApi.playerSettings[data.PlayerID] and WebApi.playerSettings[data.PlayerID].got_free_treasure then
			return
		else
			WebApi.playerSettings[data.PlayerID].got_free_treasure = true
			WebApi:ForceSaveSettings(data.PlayerID)
			CustomNetTables:SetTableValue("player_settings", tostring(data.PlayerID), WebApi.playerSettings[data.PlayerID])
		end
	end

	local items = self:GetItemsPoolForPlayer(data.PlayerID, data.treasureName)
	local item = table.random(items.backPool);
	--print("items.backPool")
	--DeepPrintTable(items.backPool)
	local isPlayerAlreadyHasItem = self:IsItemOwned(item, playerSteamId)

	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(data.PlayerID), "battlepass_inventory:show_wheel", {
		itemPool = items.poolForWheel,
		itemPrize = item;
		glory = isPlayerAlreadyHasItem and (self.item_definitions[item].GloryForDuplicate or self.duplicate_glory[self.item_definitions[item].Rarity]) or 0
	})

	local count = itemInInventory[2].count - 1
	local responseData = {
		items = {
			{
				steamId = playerSteamId,
				itemName = data.treasureName,
				count = count,
				-- insertedGem = "string",
			}
		}
	}
	if count > 0 then
		self:UpdatePlayerItems(responseData)
	else
		self:RemoveItems(responseData)
	end

	if not self.item_definitions[item].NotAddInInventory then
		if not isPlayerAlreadyHasItem then
			BP_Inventory:AddItems({
				items = {
					{
						steamId = playerSteamId,
						itemName = item,
						count = 1,
						-- insertedGem = "string",
					}
				}
			})
		else
			local backGlory = self.item_definitions[item].GloryForDuplicate or self.duplicate_glory[self.item_definitions[item].Rarity]
			BP_Inventory:AddGlory({
				steamId = playerSteamId,
				glory = backGlory,
			})
		end
	end
	if string.match(item,"^glory_pack_") then
		local value = string.gsub(item, "^glory_pack_", "")
		value = tonumber(value)
		BP_Inventory:AddGlory({
			steamId = playerSteamId,
			glory = value,
		})
	end

	BP_Inventory:ChangeLocalItemCount(data.treasureName, playerSteamId, -1)
end

function BP_Inventory:AddGlory(glory)
	WebApi:Send(
		"battlepass/add_glory",
		glory,
		function(data)
			local playerId = Battlepass.playerid_map[glory.steamId]
			BP_PlayerProgress:ChangeGlory(playerId, glory.glory)
			CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerId), "battlepass_inventory:update_coins", {
				coins = BP_PlayerProgress:GetGlory(playerId)
			})
			print("Successfully added glory")
		end,
		function(e)
			print("error while add glory: ", e)
		end
	)
end

function BP_Inventory:AddItems(items)
	WebApi:Send(
		"battlepass/inventory/add_items",
		items,
		function(data)
			local itemData = items.items[1]
			self:AddItemLocal(itemData.itemName, itemData.steamId, 1)
			print("Successfully added items")
		end,
		function(e)
			print("error while adding items: ", e)
		end
	)
end

function BP_Inventory:RemoveItems(items)
	WebApi:Send(
		"battlepass/inventory/remove_items",
		items,
		function(data)
			print("Successfully removed items")
		end,
		function(e)
			print("error while removing items: ", e)
		end
	)
end


function BP_Inventory:UpdatePlayerItems(items)
	WebApi:Send(
		"battlepass/inventory/set_items",
		items,
		function(data)
			print("Successfully updated items")
		end,
		function(e)
			print("error while updating items: ", e)
		end
	)
end

function BP_Inventory:SetPlayerEquippedItems(items)
	WebApi:Send(
		"battlepass/inventory/set_player_equipped_items",
		items,
		function(data)
			print("Successfully set equipped items")
		end,
		function(e)
			print("error while set equipped items: ", e)
		end
	)
end

function BP_Inventory:ChangeLocalItemCount(itemName, playerSteamId, changedCount)
	local itemInInventory = self:IsItemOwned(itemName, playerSteamId)
	if itemInInventory then
		local itemId = itemInInventory[1]
		if self.player_items[playerSteamId][itemId] and self.player_items[playerSteamId][itemId].count then
			local newCount = self.player_items[playerSteamId][itemId].count + changedCount
			if newCount > 0 then
				self.player_items[playerSteamId][itemId].count = self.player_items[playerSteamId][itemId].count + changedCount
			else
				self.player_items[playerSteamId][itemId] = nil
			end
		end
	end

	self:UpdateAvailableItems(Battlepass.playerid_map[playerSteamId])
end

function BP_Inventory:AddItemLocal(itemName, playerSteamId, count)
	if not self.player_items[playerSteamId] then return end
	local itemInInventory = self:IsItemOwned(itemName, playerSteamId)
	if itemInInventory then
		local itemId = itemInInventory[1]
		if self.player_items[playerSteamId][itemId] and self.player_items[playerSteamId][itemId].count then
			self.player_items[playerSteamId][itemId].count = self.player_items[playerSteamId][itemId].count + 1
		end
	else
		table.insert(self.player_items[playerSteamId], {
			category = self.categories[self.item_definitions[itemName].Category],
			equipped = false,
			steamId = playerSteamId,
			itemName = itemName,
			rarity = self.rarities[self.item_definitions[itemName].Rarity],
			count = count or 1,
		})
	end

	self:UpdateAvailableItems( Battlepass.playerid_map[playerSteamId])
end

function BP_Inventory:BuyItems(_data)
	if BP_Inventory.item_definitions[_data.itemName] and BP_Inventory.item_definitions[_data.itemName].Source.Coins then
		local cost = BP_Inventory.item_definitions[_data.itemName].Source.Coins
		local playerSteamId = Battlepass.steamid_map[_data.PlayerID]
		local itemsCount = _data.count or 1
		local itemData = {
			steamId = playerSteamId,
			items = {
				{
					itemName = _data.itemName,
					count = itemsCount
				}
			},
			totalPrice = cost * itemsCount
		}

		WebApi:Send(
			"battlepass/inventory/buy_items",
			itemData,
			function(data)
				BP_PlayerProgress:ChangeGlory(_data.PlayerID, data.glory - BP_PlayerProgress:GetGlory(_data.PlayerID))
				CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(_data.PlayerID), "battlepass_inventory:update_coins", {
					coins = data.glory
				})
				BP_Inventory:AddItemLocal(_data.itemName, playerSteamId, itemsCount)
				if _data.itemName == "ability_reroll_1" or _data.itemName == "ability_reroll_2" then
					HeroBuilder:GetMaxRerolls({PlayerID = _data.PlayerID})
				end
				print("Successfully bought items")
			end,
			function(e)
				print("error while bought items: ", e)
			end
		)
	end
end

function BP_Inventory:_CheckItemType(data)
	if not self.item_definitions[data.itemName] then return end
	return data.PlayerID, self.item_definitions[data.itemName].Category
end

function BP_Inventory:EquipItem(data)
	local playerId, category = self:_CheckItemType(data)
	if not category or not playerId then return end
	local playerMMR = 1500

	if WebApi.player_ratings and WebApi.player_ratings[playerId] and WebApi.player_ratings[playerId][GetMapName()] then
		playerMMR = WebApi.player_ratings[playerId][GetMapName()]
	end

	local equipItemFilter = function(sourceName, value)
		local source = self.item_definitions[data.itemName].Source
		return source and source[sourceName] and value < source[sourceName]
	end

	if equipItemFilter("DOTAU_MMR", playerMMR) or equipItemFilter("SupporterState", Supporters:GetLevel(playerId)) then
		data.skipSave = nil
		self:TakeOffItem(data)
		return
	end

	if WearFunc["Equip_"..category] then WearFunc["Equip_"..category](playerId, data.itemName) end

	if not self.equipped_items[Battlepass.steamid_map[playerId]]["equipped"..category] then
		self.equipped_items[Battlepass.steamid_map[playerId]]["equipped"..category] = {}
	end
	if not table.contains(self.equipped_items[Battlepass.steamid_map[playerId]]["equipped"..category], data.itemName) then
		table.insert(self.equipped_items[Battlepass.steamid_map[playerId]]["equipped"..category], data.itemName)
	end

	BP_Inventory:UpdateEquippedItems(playerId)
	if not data.skipSave then self:SaveEquippedItems(playerId) end
end

function BP_Inventory:TakeOffItem(data)
	local playerId, category = self:_CheckItemType(data)
	if not category then return end

	if PlayerResource:GetSelectedHeroEntity(data.PlayerID) then
		if WearFunc["TakeOff_"..category] then WearFunc["TakeOff_"..category](playerId, data.itemName) end
		table.remove_item(self.equipped_items[Battlepass.steamid_map[playerId]]["equipped"..category], data.itemName)
		BP_Inventory:UpdateEquippedItems(playerId)
	else
		Timers:CreateTimer(1, function()
			self:TakeOffItem(data)
			return nil
		end)
	end
	if not data.skipSave then self:SaveEquippedItems(playerId) end
end

function BP_Inventory:SaveOnlyEquippedItems(data)
	local playerId = data.PlayerID
	local state = toboolean(data.state)
	WebApi.playerSettings[playerId].only_owned_items = state
	WebApi:ScheduleUpdateSettings(playerId)
end

function BP_Inventory:InitBaseCollection(_data)
	if not _data.PlayerID or  _data.PlayerID < 0 then return end
	local playerId = _data.PlayerID
	local hero = PlayerResource:GetSelectedHeroEntity(playerId)
	if not hero or not IsValidEntity(hero) or not BP_Inventory.bCollectionLoaded then
		Timers:CreateTimer(1, function()
			BP_Inventory:InitBaseCollection(_data)
		end)
		return
	end
	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerId), "battlepass_inventory:init_collection", {
		treasures = BP_Inventory.responseCollectionTreasures,
		items = BP_Inventory.responseCollectionItems,
		masteries = BP_Inventory.responseCollectionMasteries;
	})
	if not self.player_items[Battlepass.steamid_map[playerId]] then return end
	BP_Inventory:UpdateLocalPlayerInfo(playerId)
end


setmetatable(BP_Inventory, {
	__index = function(tbl, key)
		local pl_table = rawget(tbl, "player_items")
		if pl_table and pl_table[key] then return pl_table[key] end
		return rawget(tbl, key)
	end
})
