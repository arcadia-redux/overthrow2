MAX_NEUTRAL_ITEMS_FOR_PLAYER = 2

function DropItem(data)
	if not IsServer() then return end
	local item = EntIndexToHScript( data.item )
	local itemName = item:GetName()
	local player = PlayerResource:GetPlayer(data.PlayerID)
	local team = player:GetTeam()
	local teamTower
	local towers = Entities:FindAllByName("npc_dota_tower")
	
	for _, tower in pairs(towers) do
		if tower:GetTeam() == PlayerResource:GetTeam(data.PlayerID) then
			teamTower = tower
		end
	end
	if not teamTower then return end
	local getRandomValue = function()
		return (RandomInt(0, 1) * 2 - 1) * ( 50 + RandomInt(0, 120 - 50 ) )
	end
	local pos_item =  teamTower:GetAbsOrigin() + Vector(getRandomValue(), getRandomValue(), 0)
	CreateItemOnPositionSync(pos_item, item)
	item.neutralDropInBase = true
	CustomGameEventManager:Send_ServerToTeam(team, "neutral_item_dropped", { item = data.item, itemName = itemName})
	Timers:CreateTimer(15,function() -- !!! You should put here time from function NeutralItemDropped from neutral_items.js - Schelude
		local container = item:GetContainer()
		if container then
			local dummyInventory = player.dummyInventory
			if not dummyInventory then return end
			UTIL_Remove(container)
			dummyInventory:AddItem(item)
			ExecuteOrderFromTable({
				UnitIndex = dummyInventory:entindex(),
				OrderType = 37,
				AbilityIndex = data.item,
			})
		end
		return nil
	end)
end
function CheckNeutralItemForUnit(unit)
	local count = 0
	if unit and unit:HasInventory() then
		for i = 0, 20 do
			local item = unit:GetItemInSlot(i)
			if item then
				if ItemIsNeutral(item:GetAbilityName()) then count = count + 1 end
			end
		end
	end
	return count
end

function CheckCountOfNeutralItemsForPlayer(playerId)
	local hero = PlayerResource:GetSelectedHeroEntity(playerId)
	local neutralItemsForPlayer = CheckNeutralItemForUnit(hero)
	if neutralItemsForPlayer >= MAX_NEUTRAL_ITEMS_FOR_PLAYER then return neutralItemsForPlayer end
	local playersCourier
	local couriers = Entities:FindAllByName("npc_dota_courier")
	for _, courier in pairs(couriers) do
		if courier:GetPlayerOwnerID() == playerId then
			playersCourier = courier
		end
	end
	if playersCourier then
		neutralItemsForPlayer = neutralItemsForPlayer + CheckNeutralItemForUnit(playersCourier)
	end
	return neutralItemsForPlayer
end

function NotificationToAllPlayerOnTeam(data)
	for id = 0, 24 do
		if PlayerResource:GetTeam( data.PlayerID ) == PlayerResource:GetTeam( id ) then
			CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer( id ), "neutral_item_taked", { item = data.item, player = data.PlayerID } )
		end
	end
end

function CDOTA_BaseNPC:IsHeroHasFreeSlotForNeutralItem()
	for i = 6, 14 do
		if self:GetItemInSlot(i) == nil then
			return i
		end
	end
	if self:GetItemInSlot(16) == nil then
		return 16
	end
	return false
end

RegisterCustomEventListener( "neutral_item_take", function( data )
	if CheckCountOfNeutralItemsForPlayer(data.PlayerID) >= MAX_NEUTRAL_ITEMS_FOR_PLAYER then
		DisplayError(data.PlayerID, "#player_still_have_a_lot_of_neutral_items")
		return
	end
	local item = EntIndexToHScript( data.item )
	local hero = PlayerResource:GetSelectedHeroEntity( data.PlayerID )
	local freeSlot = hero:IsHeroHasFreeSlotForNeutralItem()

	if freeSlot then
		if item.neutralDropInBase then
			item.neutralDropInBase = false
			local container = item:GetContainer()
			UTIL_Remove( container )
			hero:AddItem( item )
			NotificationToAllPlayerOnTeam(data)
		end
	else
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(data.PlayerID), "display_custom_error", { message = "#inventory_full_custom_message" })
	end
end )

function ItemIsNeutral(_itemName)
	local result = false
	for _, itemsList in pairs(NEUTRAL_ITEMS) do
		for _, itemName in pairs(itemsList) do
			if itemName == _itemName then
				result = true
			end
		end
	end
	return result
end
