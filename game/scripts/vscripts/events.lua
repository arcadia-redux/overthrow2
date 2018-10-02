--[[ events.lua ]]

---------------------------------------------------------------------------
-- Event: Game state change handler
---------------------------------------------------------------------------
function COverthrowGameMode:OnGameRulesStateChange()
	local nNewState = GameRules:State_Get()
	--print( "OnGameRulesStateChange: " .. nNewState )

	if nNewState == DOTA_GAMERULES_STATE_HERO_SELECTION then
		self.heroSelectionStage = 1
	end

	if nNewState == DOTA_GAMERULES_STATE_PRE_GAME then
		self.heroSelectionStage = 5
		local numberOfPlayers = PlayerResource:GetPlayerCount()
		if numberOfPlayers > 16 then
			nCOUNTDOWNTIMER = 1201
		elseif numberOfPlayers > 7 then
			nCOUNTDOWNTIMER = 901
		elseif numberOfPlayers > 4 and numberOfPlayers <= 7 then
			nCOUNTDOWNTIMER = 721
		else
			nCOUNTDOWNTIMER = 601
		end
		if GetMapName() == "forest_solo" then
			self.TEAM_KILLS_TO_WIN = 25
		elseif GetMapName() == "desert_duo" then
			self.TEAM_KILLS_TO_WIN = 30
		elseif GetMapName() == "desert_quintet" then
			self.TEAM_KILLS_TO_WIN = 50
		elseif GetMapName() == "temple_quartet" then
			self.TEAM_KILLS_TO_WIN = 50
		elseif GetMapName() == "desert_octet" then
			self.TEAM_KILLS_TO_WIN = 85
		else
			self.TEAM_KILLS_TO_WIN = 30
		end
		--print( "Kills to win = " .. tostring(self.TEAM_KILLS_TO_WIN) )

		CustomNetTables:SetTableValue( "game_state", "victory_condition", { kills_to_win = self.TEAM_KILLS_TO_WIN } );

		self._fPreGameStartTime = GameRules:GetGameTime()
	end

	if nNewState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		--print( "OnGameRulesStateChange: Game In Progress" )
		self.countdownEnabled = true
		CustomGameEventManager:Send_ServerToAllClients( "show_timer", {} )
		DoEntFire( "center_experience_ring_particles", "Start", "0", 0, self, self  )
	end
end

--------------------------------------------------------------------------------
-- Event: OnNPCSpawned
--------------------------------------------------------------------------------
function COverthrowGameMode:OnNPCSpawned( event )
	local spawnedUnit = EntIndexToHScript( event.entindex )
	if not spawnedUnit:IsRealHero() then return end
	-- Destroys the last hit effects
	local deathEffects = spawnedUnit:Attribute_GetIntValue( "effectsID", -1 )
	if deathEffects ~= -1 then
		ParticleManager:DestroyParticle( deathEffects, true )
		spawnedUnit:DeleteAttribute( "effectsID" )
	end

	local unitTeam = spawnedUnit:GetTeam()
	if not spawnedUnit.firstTimeSpawned then
		spawnedUnit:SetContextThink("AddCourier", function()
			if self.couriers[unitTeam] then return end
			self.couriers[unitTeam] = true
			local firstSlotItem = spawnedUnit:GetItemInSlot(DOTA_ITEM_SLOT_1)
			if firstSlotItem then spawnedUnit:TakeItem(firstSlotItem) end

			local courier = spawnedUnit:AddItemByName("item_courier")
			if courier then
				spawnedUnit:CastAbilityImmediately(courier, spawnedUnit:GetPlayerID())
			end

			if firstSlotItem then
				spawnedUnit:SetContextThink("AddCourierReturnItem", function()
					spawnedUnit:AddItem(firstSlotItem)
				end, 0)
			end
		end, 0)


		spawnedUnit.firstTimeSpawned = true
		spawnedUnit:SetContextThink("HeroFirstSpawn", function()
			local hasBoots = false
			local hasTpScroll = false
			for i = DOTA_ITEM_SLOT_1, DOTA_STASH_SLOT_6 do
				local item = spawnedUnit:GetItemInSlot(i)
				if item then
					local itemName = item:GetAbilityName()
					if itemName == "item_tpscroll" and not hasTpScroll then
						hasTpScroll = true
						item:SetCurrentCharges(item:GetCurrentCharges() - 1)
						if item:GetCurrentCharges() == 0 then
							UTIL_Remove(item)
						end
					end
					if itemName == "item_boots" then
						hasBoots = true
					end
				end
			end

			if GetPlayerPatreonLevel(spawnedUnit:GetPlayerID()) >= 1 then
				if hasBoots then
					spawnedUnit:ModifyGold(500, false, 0)
				else
					spawnedUnit:AddItemByName("item_boots")
				end
			end
		end, 2/30)
	end

	if self.allSpawned == false then
		if GetMapName() == "mines_trio" then
			--print("mines_trio is the map")
			--print("self.allSpawned is " .. tostring(self.allSpawned) )
			local particleSpawn = ParticleManager:CreateParticleForTeam( "particles/addons_gameplay/player_deferred_light.vpcf", PATTACH_ABSORIGIN, spawnedUnit, unitTeam )
			ParticleManager:SetParticleControlEnt( particleSpawn, PATTACH_ABSORIGIN, spawnedUnit, PATTACH_ABSORIGIN, "attach_origin", spawnedUnit:GetAbsOrigin(), true )
		end
	end
end

--------------------------------------------------------------------------------
-- Event: BountyRunePickupFilter
--------------------------------------------------------------------------------
function COverthrowGameMode:BountyRunePickupFilter( filterTable )
      filterTable["xp_bounty"] = 2*filterTable["xp_bounty"]
      filterTable["gold_bounty"] = 2*filterTable["gold_bounty"]
      return true
end

---------------------------------------------------------------------------
-- Event: OnTeamKillCredit, see if anyone won
---------------------------------------------------------------------------
function COverthrowGameMode:OnTeamKillCredit( event )
--	print( "OnKillCredit" )
--	DeepPrint( event )

	local nKillerID = event.killer_userid
	local nTeamID = event.teamnumber
	local nTeamKills = event.herokills
	local nKillsRemaining = self.TEAM_KILLS_TO_WIN - nTeamKills

	local broadcast_kill_event =
	{
		killer_id = event.killer_userid,
		team_id = event.teamnumber,
		team_kills = nTeamKills,
		kills_remaining = nKillsRemaining,
		victory = 0,
		close_to_victory = 0,
		very_close_to_victory = 0,
	}

	if nKillsRemaining <= 0 then
		GameRules:SetCustomVictoryMessage( self.m_VictoryMessages[nTeamID] )
		self:SendMatchResults(nTeamID)
		GameRules:SetGameWinner( nTeamID )
		broadcast_kill_event.victory = 1
	elseif nKillsRemaining == 1 then
		EmitGlobalSound( "ui.npe_objective_complete" )
		broadcast_kill_event.very_close_to_victory = 1
	elseif nKillsRemaining <= self.CLOSE_TO_VICTORY_THRESHOLD then
		EmitGlobalSound( "ui.npe_objective_given" )
		broadcast_kill_event.close_to_victory = 1
	end

	CustomGameEventManager:Send_ServerToAllClients( "kill_event", broadcast_kill_event )
end

---------------------------------------------------------------------------
-- Event: OnEntityKilled
---------------------------------------------------------------------------
function COverthrowGameMode:OnEntityKilled( event )
	local killedUnit = EntIndexToHScript( event.entindex_killed )
	local killedTeam = killedUnit:GetTeam()
	local hero = EntIndexToHScript( event.entindex_attacker )
	local heroTeam = hero:GetTeam()
	local extraTime = 0
	if killedUnit:IsRealHero() then
		self.allSpawned = true
		--print("Hero has been killed")
		--Add extra time if killed by Necro Ult
		if hero:IsRealHero() == true then
			if event.entindex_inflictor ~= nil then
				local inflictor_index = event.entindex_inflictor
				if inflictor_index ~= nil then
					local ability = EntIndexToHScript( event.entindex_inflictor )
					if ability ~= nil then
						if ability:GetAbilityName() ~= nil then
							if ability:GetAbilityName() == "necrolyte_reapers_scythe" then
								print("Killed by Necro Ult")
								extraTime = 20
							end
						end
					end
				end
			end
		end
		if hero:IsRealHero() and heroTeam ~= killedTeam then
			--print("Granting killer xp")
			if killedUnit:GetTeam() == self.leadingTeam and self.isGameTied == false then
				local memberID = hero:GetPlayerID()
				PlayerResource:ModifyGold( memberID, 500, true, 0 )
				hero:AddExperience( 100, 0, false, false )
				local name = hero:GetClassname()
				local victim = killedUnit:GetClassname()
				local kill_alert =
					{
						hero_id = hero:GetClassname()
					}
				CustomGameEventManager:Send_ServerToAllClients( "kill_alert", kill_alert )
			else
				hero:AddExperience( 50, 0, false, false )
			end
		end
		--Granting XP to all heroes who assisted
		local allHeroes = HeroList:GetAllHeroes()
		for _,attacker in pairs( allHeroes ) do
			--print(killedUnit:GetNumAttackers())
			for i = 0, killedUnit:GetNumAttackers() - 1 do
				if attacker == killedUnit:GetAttacker( i ) then
					--print("Granting assist xp")
					attacker:AddExperience( 25, 0, false, false )
				end
			end
		end

		if not killedUnit:IsReincarnating() then
			COverthrowGameMode:SetRespawnTime(killedTeam, killedUnit, extraTime)
		end
	end
end

function COverthrowGameMode:SetRespawnTime(killedTeam, killedUnit, extraTime)
	local units = {killedUnit}
	if killedUnit:GetUnitName() == "npc_dota_hero_meepo" then
		local playerId = killedUnit:GetPlayerID()
		for _, unit in ipairs(Entities:FindAllByName("npc_dota_hero_meepo")) do
			if unit:IsRealHero() and unit ~= killedUnit and unit:GetPlayerID() == playerId then
				table.insert(units, unit)
			end
		end
	end

	local baseTime = 10
	if GetMapName() == "desert_octet" then
		if not self.isGameTied then
			if killedTeam == self.leadingTeam then
				baseTime = 20
			elseif killedTeam == self.runnerupTeam then
				baseTime = 10
			end
		end
		if killedTeam ~= self.leadingTeam and killedTeam ~= self.runnerupTeam then
			baseTime = 5
		end
	else
		if killedTeam == self.leadingTeam and not self.isGameTied then
			baseTime = 20
		end
	end

	for _,unit in ipairs(units) do
		unit:SetTimeUntilRespawn(baseTime + extraTime)
	end
end


--------------------------------------------------------------------------------
-- Event: OnItemPickUp
--------------------------------------------------------------------------------
function COverthrowGameMode:OnItemPickUp( event )
	local item = EntIndexToHScript( event.ItemEntityIndex )
	local owner = EntIndexToHScript( event.HeroEntityIndex )
	r = 300
	--r = RandomInt(200, 400)
	if event.itemname == "item_bag_of_gold" then
		--print("Bag of gold picked up")
		PlayerResource:ModifyGold( owner:GetPlayerID(), r, true, 0 )
		SendOverheadEventMessage( owner, OVERHEAD_ALERT_GOLD, owner, r, nil )
		UTIL_Remove( item ) -- otherwise it pollutes the player inventory
	elseif event.itemname == "item_treasure_chest" then
		--print("Special Item Picked Up")
		DoEntFire( "item_spawn_particle_" .. self.itemSpawnIndex, "Stop", "0", 0, self, self )
		COverthrowGameMode:SpecialItemAdd( event )
		UTIL_Remove( item ) -- otherwise it pollutes the player inventory
	end
end


--------------------------------------------------------------------------------
-- Event: OnNpcGoalReached
--------------------------------------------------------------------------------
function COverthrowGameMode:OnNpcGoalReached( event )
	local npc = EntIndexToHScript( event.npc_entindex )
	if npc:GetUnitName() == "npc_dota_treasure_courier" then
		COverthrowGameMode:TreasureDrop( npc )
	end
end
