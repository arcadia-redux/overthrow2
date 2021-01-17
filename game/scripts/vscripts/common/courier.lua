_G.trollList = {}

function CreatePrivateCourier(playerId, owner, pointToSpawn)
	local courier_spawn = pointToSpawn + RandomVector(RandomFloat(100, 100))

	local team = owner:GetTeamNumber()

	local cr = CreateUnitByName("npc_dota_courier", courier_spawn, true, nil, nil, team)
	cr:AddNewModifier(cr, nil, "modifier_patreon_courier", {})

	if GetMapName() == "core_quartet" then
		print("I AM PR COURIER AND NEED MORE SPEeD")
		cr:AddNewModifier(cr, nil, "modifier_courier_quartet", nil)
	end

	Timers:CreateTimer(0.1, function()
		cr:SetControllableByPlayer(playerId, true)
		_G.personalCouriers[playerId] = cr;
	end)
end

function EditFilterToCourier(filterTable)
	local unit
	local orderType = filterTable.order_type
	local target = filterTable.entindex_target ~= 0 and EntIndexToHScript(filterTable.entindex_target) or nil
	local ability = filterTable.entindex_ability ~= 0 and EntIndexToHScript(filterTable.entindex_ability) or nil
	local playerId = filterTable.issuer_player_id_const

	if playerId < 0 then return filterTable end
	if not PlayerResource:GetPlayer(playerId):GetAssignedHero() then return filterTable end

	local hasCourierInUnitsTable = false
	for _, unitEntityIndex in pairs(filterTable.units) do
		unit = EntIndexToHScript(unitEntityIndex)
		if unit:IsCourier() then hasCourierInUnitsTable = true end
	end
	if not hasCourierInUnitsTable then return filterTable end

	local currentCourier = SearchCorrectCourier(playerId, PlayerResource:GetPlayer(playerId):GetAssignedHero():GetTeamNumber())

	if orderType == DOTA_UNIT_ORDER_GIVE_ITEM and target and target:IsCourier() and target ~= currentCourier and currentCourier:IsAlive() and (not currentCourier:IsStunned()) then
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerId), "display_custom_error", { message = "#cannotgiveiteminthiscourier" })
		return false
	end

	for _, unitEntityIndex in pairs(filterTable.units) do
		unit = EntIndexToHScript(unitEntityIndex)

		if unit:IsCourier() then
			for i, x in pairs(filterTable.units) do
				if filterTable.units[i] == unitEntityIndex then
					if _G.trollList[playerId] then
						CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerId), "selection_remove", { entities = { unit:GetEntityIndex() } })
						CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerId), "display_custom_error", { message = "#you_cannot_control_courier" })
						filterTable.units[i] = currentCourier
					elseif currentCourier then
						filterTable.units[i] = currentCourier:GetEntityIndex()
					end
				end
			end

			if (not _G.trollList[playerId]) and currentCourier and unit ~= currentCourier and currentCourier:IsAlive() and (not currentCourier:IsStunned()) then
				for i = 0, 20 do
					if filterTable.entindex_ability and currentCourier:GetAbilityByIndex(i) and ability and currentCourier:GetAbilityByIndex(i):GetName() == ability:GetName() then
						filterTable.entindex_ability = currentCourier:GetAbilityByIndex(i):GetEntityIndex()
					end
				end

				local newFocus = { currentCourier:GetEntityIndex() }
				CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerId), "selection_courier_update", { newCourier = newFocus, removeCourier = { unitEntityIndex } })
			end
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

function SearchCorrectCourier(playerID, team)
	local currentCourier
	local supporter_level = Supporters:GetLevel(playerID)
	if _G.trollList[playerID] then
		return {}
	end
	if supporter_level > 1 and _G.personalCouriers[playerID] and _G.personalCouriers[playerID]:IsAlive() and (not _G.personalCouriers[playerID]:IsStunned()) then
		currentCourier = _G.personalCouriers[playerID]
	elseif _G.mainTeamCouriers[team] and _G.mainTeamCouriers[team]:IsAlive() and (not _G.mainTeamCouriers[team]:IsStunned()) then
		currentCourier = _G.mainTeamCouriers[team]
	else
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "display_custom_error", { message = "#allcouriersdie" })
	end

	return currentCourier
end

--RegisterCustomEventListener("courier_custom_select", function(data)
--	local playerID = data.PlayerID
--	if not playerID then return end
--
--	local player = PlayerResource:GetPlayer(playerID)
--	local team = player:GetTeamNumber()
--	local currentCourier = SearchCorrectCourier(playerID, team)
--
--	if currentCourier and (not _G.trollList[playerID]) then
--		CustomGameEventManager:Send_ServerToPlayer(player, "selection_new", { entities = { currentCourier:GetEntityIndex() } })
--	elseif _G.trollList[playerID] then
--		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "display_custom_error", { message = "#you_cannot_control_courier" })
--	end
--end)
--
--function unitMoveToPoint(unit, point)
--	ExecuteOrderFromTable({
--		UnitIndex = unit:entindex(),
--		OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
--		Position = point
--	})
--end
--
--RegisterCustomEventListener("courier_custom_select_deliever_items", function(data)
--	local playerID = data.PlayerID
--	if not playerID then return end
--	local player = PlayerResource:GetPlayer(playerID)
--	local team = player:GetTeamNumber()
--	local currentCourier = SearchCorrectCourier(playerID, team)
--
--	if currentCourier and (not _G.trollList[playerID]) then
--		local stashHasItems = false
--		for i = 10, 15 do
--			local item = player:GetAssignedHero():GetItemInSlot(i)
--			if item ~= nil then
--				stashHasItems = true
--			end
--		end
--
--		if stashHasItems then
--			currentCourier:CastAbilityNoTarget(currentCourier:GetAbilityByIndex(7), playerID)
--		else
--			unitMoveToPoint(currentCourier, player:GetAssignedHero():GetAbsOrigin())
--			currentCourier:CastAbilityNoTarget(currentCourier:GetAbilityByIndex(4), playerID)
--		end
--	elseif _G.trollList[playerID] then
--		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "display_custom_error", { message = "#you_cannot_control_courier" })
--	end
--end)
