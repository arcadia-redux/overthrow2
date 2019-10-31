function CreatePrivateCourier(playerId, owner, pointToSpawn)
	local courier_spawn = pointToSpawn + RandomVector(RandomFloat(100, 100))

	local team = owner:GetTeamNumber()

	local cr = CreateUnitByName("npc_dota_courier", courier_spawn, true, nil, nil, team)
	cr:AddNewModifier(cr, nil, "modifier_patreon_courier", {})
	Timers:CreateTimer(.1, function()
		cr:SetControllableByPlayer(owner:GetPlayerID(), true)
		_G.personalCouriers[playerId] = cr;
	end)
end

function EditFilterToCourier(filterTable, playerId, ability)
	local unit
	if filterTable.units and filterTable.units["0"] then
		unit = EntIndexToHScript(filterTable.units["0"])
	end

	local privateCourier = _G.personalCouriers[playerId]

	if orderType == DOTA_UNIT_ORDER_GIVE_ITEM and target:IsCourier() and target ~= privateCourier and privateCourier:IsAlive() and (not privateCourier:IsStunned())then
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerId), "display_custom_error", { message = "#cannotgiveiteminthiscourier" })
		return false
	end

	for _, unitEntityIndex in pairs(filterTable.units) do
		unit = EntIndexToHScript(unitEntityIndex)
		if unit:IsCourier() and unit ~= privateCourier and privateCourier:IsAlive() and (not privateCourier:IsStunned())then

			for i, x in pairs(filterTable.units) do
				if filterTable.units[i] == unitEntityIndex then
					filterTable.units[i] = privateCourier:GetEntityIndex()
				end
			end

			for i = 0, 20 do
				if filterTable.entindex_ability and privateCourier:GetAbilityByIndex(i) and ability and privateCourier:GetAbilityByIndex(i):GetName() == ability:GetName() then
					filterTable.entindex_ability = privateCourier:GetAbilityByIndex(i):GetEntityIndex()
				end
			end

			local newFocus = {privateCourier:GetEntityIndex()}

			CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerId), "selection_courier_update", { newCourier = newFocus, removeCourier = { unitEntityIndex } })
		end
	end
	return filterTable
end

function BlockToBuyCourier(playerId, hItem)
	if _G.personalCouriers[playerId] then
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerId), "display_custom_error", { message = "#alreadyhaveprivatecourier" })
	else
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerId), "display_custom_error", { message = "#nopatreonerror2" })
	end
	UTIL_Remove(hItem)
end

RegisterCustomEventListener("courier_custom_select", function(data)
	local playerID = data.PlayerID
	if not playerID then return end
	local player = PlayerResource:GetPlayer(playerID)
	local team = player:GetTeamNumber()
	local currentCourier = false

	if _G.personalCouriers[playerID] and _G.personalCouriers[playerID]:IsAlive() then
		currentCourier = { _G.personalCouriers[playerID]:GetEntityIndex() }
	elseif _G.mainTeamCouriers[team]:IsAlive() then
		currentCourier = { _G.mainTeamCouriers[team]:GetEntityIndex() }
	end

	if not currentCourier then return end
	CustomGameEventManager:Send_ServerToPlayer(player, "selection_new", { entities = currentCourier })
end)

function unitMoveToPoint(unit, point)
	ExecuteOrderFromTable({
		UnitIndex = unit:entindex(),
		OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
		Position = point
	})
end

RegisterCustomEventListener("courier_custom_select_deliever_items", function(data)
	local playerID = data.PlayerID
	if not playerID then return end
	local player = PlayerResource:GetPlayer(playerID)
	local team = player:GetTeamNumber()
	local currentCourier = false

	if _G.personalCouriers[playerID] and _G.personalCouriers[playerID]:IsAlive() then
		currentCourier = _G.personalCouriers[playerID]
	elseif _G.mainTeamCouriers[team]:IsAlive() then
		currentCourier = _G.mainTeamCouriers[team]
	end

	if not currentCourier then return end
	if currentCourier:IsStunned() then return end

	local stashHasItems = false

	for i = 9, 14 do
		local item = player:GetAssignedHero():GetItemInSlot(i)
		if item ~= nil then
			stashHasItems = true
		end
	end

	if stashHasItems then
		currentCourier:CastAbilityNoTarget(currentCourier:GetAbilityByIndex(7), playerID)
	else
		unitMoveToPoint(currentCourier, player:GetAssignedHero():GetAbsOrigin())
		currentCourier:CastAbilityNoTarget(currentCourier:GetAbilityByIndex(4), playerID)
	end
end)