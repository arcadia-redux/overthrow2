local lastTimeBuyItemWithCooldown = {}
local maximumItemsForPlayersData = {}
LinkLuaModifier("modifier_dummy_inventory_custom", LUA_MODIFIER_MOTION_VERTICAL)

-------------------------------------------------------------------------
local itemsCooldownForPlayer = {
	["item_disable_help_custom"] = 10,
	["item_mute_custom"] = 10,
}
-------------------------------------------------------------------------
local maximumItemsForPlayers = {
	--["item_banhammer"] = 2,
}
-------------------------------------------------------------------------
local notFastItems = {
	["item_ward_observer"] = true,
	["item_ward_sentry"] = true,
	["item_smoke_of_deceit"] = true,
	["item_clarity"] = true,
	["item_flask"] = true,
	["item_greater_mango"] = true,
	["item_enchanted_mango"] = true,
	["item_tango"] = true,
	["item_faerie_fire"] = true,
	["item_tpscroll"] = true,
	["item_dust"] = true,
}
-------------------------------------------------------------------------
local fastItems = {
	["item_disable_help_custom"] = true,
	["item_mute_custom"] = true,
}
-------------------------------------------------------------------------

function CDOTA_BaseNPC:CheckPersonalCooldown(item)
	local buyerEntIndex = self:GetEntityIndex()
	local itemName = item:GetAbilityName()
	local unique_key = itemName .. "_" .. buyerEntIndex
	local playerID = self:GetPlayerID()

	if not itemsCooldownForPlayer[itemName] or item.isTransfer or not item:CheckMaxItemsForPlayer(unique_key) then return true end

	local playerCanBuyItem = lastTimeBuyItemWithCooldown[unique_key] == nil or ((GameRules:GetGameTime() - lastTimeBuyItemWithCooldown[unique_key]) >= itemsCooldownForPlayer[itemName])

	if playerCanBuyItem then
		lastTimeBuyItemWithCooldown[unique_key] = GameRules:GetGameTime()
		return true
	else
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "display_custom_error", { message = "#fast_buy_items" })
		return false
	end

	return true
end

-------------------------------------------------------------------------

function CDOTA_BaseNPC:IsMaxItemsForPlayer(item)
	local buyerEntIndex = self:GetEntityIndex()
	local itemName = item:GetAbilityName()
	local unique_key = itemName .. "_" .. buyerEntIndex
	local playerID = self:GetPlayerID()
	if not maximumItemsForPlayers[itemName] or item.isTransfer then return true end

	local isPlayerBoughtMaxItems = item:CheckMaxItemsForPlayer(unique_key)

	if isPlayerBoughtMaxItems then
		maximumItemsForPlayersData[unique_key] = maximumItemsForPlayersData[unique_key] + 1
	else
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "display_custom_error", { message = "you_cannot_buy_more_items_this_type" })
		return false
	end

	return true
end

-------------------------------------------------------------------------

function CDOTA_BaseNPC:RefundItem(item)
	self:ModifyGold(item:GetCost(), false, 0)
	UTIL_Remove(item)
end

-------------------------------------------------------------------------

function CDOTA_BaseNPC:DoesHeroHasFreeSlot()
	for i = 0, 15 do
		if self:GetItemInSlot(i) == nil then
			return i
		end
	end
	return false
end

-------------------------------------------------------------------------

function CDOTA_Item:ItemIsFastBuying(playerId)
	return fastItems[self:GetName()] or (Patreons:GetPlayerSettings(playerId).level > 0)
end

-------------------------------------------------------------------------

function CDOTA_Item:TransferToBuyer(unit)
	local buyer = self:GetPurchaser()
	local itemName = self:GetName()

	if notFastItems[itemName] or unit:IsIllusion() or self.isTransfer then
		return true
	end

	if not buyer:DoesHeroHasFreeSlot() then
		buyer:RefundItem(self)
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(buyer:GetPlayerID()), "display_custom_error", { message = "#dota_hud_error_cant_purchase_inventory_full" })
		return false
	end

	self.isTransfer = true

	Timers:CreateTimer(0.0000000000000000000001, function()
		buyer:TakeItem(self)
		local container = self:GetContainer()
		if container then
			UTIL_Remove(container)
		end
		Timers:CreateTimer(0.04, function()
			local dummyInventory = buyer:GetOwner().dummyInventory
			dummyInventory:AddItem(self)
			Timers:CreateTimer(0.2, function()
				for i = 0, 15 do
					local item = dummyInventory:GetItemInSlot(i)
					if item then
						dummyInventory:TakeItem(item)
						Timers:CreateTimer(0.04, function()
							if buyer:DoesHeroHasFreeSlot() then
								buyer:AddItem(item)
							else
								buyer:RefundItem(item)
							end
						end)
					end
				end
			end)
		end)
	end)
	return true
end

-------------------------------------------------------------------------

function CDOTA_Item:CheckMaxItemsForPlayer(unique_key)
	if not maximumItemsForPlayers[self:GetAbilityName()] then return true end
	if not maximumItemsForPlayersData[unique_key] then
		maximumItemsForPlayersData[unique_key] = 1
	end
	return maximumItemsForPlayersData[unique_key] <= maximumItemsForPlayers[self:GetAbilityName()]
end

-------------------------------------------------------------------------
function CreateDummyInventoryForPlayer(playerId, unit)
	if PlayerResource:GetPlayer(playerId).dummyInventory then
		PlayerResource:GetPlayer(playerId).dummyInventory:Kill(nil, nil)
	end
	
	local startPointSpawn = unit:GetAbsOrigin() + (RandomFloat(100, 100))
	local dInventory = CreateUnitByName("npc_dummy_inventory", startPointSpawn, true, unit, unit, PlayerResource:GetTeam(playerId))
	dInventory:SetControllableByPlayer(playerId, true)
	dInventory:AddNewModifier(dInventory, nil, "modifier_dummy_inventory_custom", {duration = -1})
	PlayerResource:GetPlayer(playerId).dummyInventory = dInventory
end
-------------------------------------------------------------------------
