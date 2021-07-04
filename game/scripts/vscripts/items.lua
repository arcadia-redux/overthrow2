DROP_GOLD = 0
DROP_NEUTRAL_ITEM = 1
LinkLuaModifier("capture_point_area", 'capture_points/capture_point_area', LUA_MODIFIER_MOTION_BOTH)

function COverthrowGameMode:ThinkGoldDrop()
	local r = RandomInt( 1, 100 )
	if r > ( 100 - self.m_GoldDropPercent ) then
		self:SpawnDropInMiddle(DROP_GOLD)
	else
		r = RandomInt( 1, 100 )
		if r > ( 100 - self.m_NeutralItemDropPercent ) then
			self:SpawnDropInMiddle(DROP_NEUTRAL_ITEM)
		end
	end
end

function COverthrowGameMode:SpawnDropInMiddle(nType)
	local overBoss = Entities:FindByName( nil, "@overboss" )
	local throwCoin
	local throwCoin2
	if overBoss then
		throwCoin = overBoss:FindAbilityByName( 'dota_ability_throw_coin' )
		throwCoin2 = overBoss:FindAbilityByName( 'dota_ability_throw_coin_long' )
	end

	overBoss.nDropType = nType
	if throwCoin2 and RandomInt( 1, 100 ) > 80 then
		overBoss:CastAbilityNoTarget( throwCoin2, -1 )
	elseif throwCoin then
		overBoss:CastAbilityNoTarget( throwCoin, -1 )
	else
		self:ForceSpawnDropInMiddle(nType)
	end
end

function COverthrowGameMode:ForceSpawnDropInMiddle(nType)
	if nType == DROP_GOLD then
		self:SpawnGoldEntity( Vector( 0, 0, 0 ) )
	end
	if nType == DROP_NEUTRAL_ITEM then
		self:SpawnNeutralItem(INIT_POSITION_FOR_ITEM)
	end
end

function COverthrowGameMode:SpawnGoldEntity( spawnPoint )
	EmitGlobalSound("Item.PickUpGemWorld")
	local newItem = CreateItem( "item_bag_of_gold", nil, nil )
	local drop = CreateItemOnPositionForLaunch( spawnPoint, newItem )
	local dropRadius = RandomFloat( self.m_GoldRadiusMin, self.m_GoldRadiusMax )
	newItem:LaunchLootInitialHeight( false, 0, 500, 0.75, spawnPoint + RandomVector( dropRadius ) )
	newItem:SetContextThink( "KillLoot", function() return self:KillLoot( newItem, drop ) end, 20 )
end

function COverthrowGameMode:SpawnNeutralItem( spawnPoint )
	EmitGlobalSound("Item.PickUpGemWorld")
	local hCapturePointUnit = CreateUnitByName("npc_dummy_capture", spawnPoint, true, nil, nil, DOTA_TEAM_NEUTRALS)
	hCapturePointUnit:SetForwardVector(Vector( 0, 1, 0 ))
	hCapturePointUnit:AddNewModifier(hCapturePointUnit, nil, "capture_point_area", {duration = -1})
end

--Removes Bags of Gold after they expire
function COverthrowGameMode:KillLoot( item, drop )

	if drop:IsNull() then
		return
	end

	local nFXIndex = ParticleManager:CreateParticle( "particles/items2_fx/veil_of_discord.vpcf", PATTACH_CUSTOMORIGIN, drop )
	ParticleManager:SetParticleControl( nFXIndex, 0, drop:GetOrigin() )
	ParticleManager:SetParticleControl( nFXIndex, 1, Vector( 35, 35, 25 ) )
	ParticleManager:ReleaseParticleIndex( nFXIndex )
	EmitGlobalSound("Item.PickUpWorld")

	UTIL_Remove( item )
	UTIL_Remove( drop )
end

function COverthrowGameMode:AddGoldenCoin(owner)
	local gold = 300
	local goblinsGreed = owner:FindAbilityByName("alchemist_goblins_greed_custom")
	if goblinsGreed and goblinsGreed:GetLevel() > 0 then
		local bonusGold = gold * (goblinsGreed:GetSpecialValueFor("gold_coin_multiplier") - 1)
		gold = gold + bonusGold
		goblinsGreed.coinBonusGold = (goblinsGreed.coinBonusGold or 0) + bonusGold
	end
	PlayerResource:ModifyGold(owner:GetPlayerOwnerID(), gold, true, 0)
	SendOverheadEventMessage(owner, OVERHEAD_ALERT_GOLD, owner, gold, nil)
end

function COverthrowGameMode:SpecialItemAdd(owner)

	-- All available perks
	local all_perks = {
		"mp_regen",
		"hp_regen",
		"bonus_movespeed",
		"bonus_agi",
		"bonus_str",
		"bonus_int",
		"bonus_all_stats",
		"attack_range",
		"bonus_hp_pct",
		"cast_range",
		"cooldown_reduction",
		"damage",
		"evasion",
		"lifesteal",
		"mag_resist",
		"spell_amp",
		"spell_lifesteal",
		"status_resistance",
		"outcomming_heal_amplify",
		"cleave",
		"cd_after_death",
		"manaburn"
	}

	-- Pick 3 random perks among the ones the hero doesn't have yet
	local valid_perks = {}

	for _, perk_name in pairs(all_perks) do
		if not (owner:HasModifier(perk_name.."_t0") or owner:HasModifier(perk_name.."_t1") or owner:HasModifier(perk_name.."_t2")) then
			table.insert(valid_perks, perk_name)
		end
	end

	valid_perks = table.shuffled(valid_perks)

	local ownerTeam = owner:GetTeamNumber()
	local sortedTeams = self:GetSortedTeams()

	local item_tier = 0

	for i = 1, #sortedTeams do
		if sortedTeams[i].team == ownerTeam then

			-- last third bonus
			if i > math.floor(2 * #sortedTeams / 3) then
				item_tier = item_tier + 1
			end

			-- middle of the pack bonus
			if i > math.floor(#sortedTeams / 3) then
				item_tier = item_tier + 1
			end
		end
	end

	-- Present item choices to the player
	local perk_choices = {}
	for i = 1, 3 do
		table.insert(perk_choices, table.remove(valid_perks))
		perk_choices[i] = perk_choices[i].."_t"..item_tier
	end

	-- Gold choice
	table.insert(perk_choices, "bonus_gold".."_t"..item_tier)

	self:StartItemPick(owner, perk_choices)
end

function COverthrowGameMode:StartItemPick(owner, choices)
	if (not owner:IsRealHero()) and owner:GetOwnerEntity() then
		owner = owner:GetOwnerEntity()
	end

	local player_id = owner:GetPlayerID()
	if PlayerResource:IsValidPlayer(player_id) then
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(player_id), "overthrow_item_choice", choices)
	end

	COverthrowGameMode.current_treasure_chest_rewards[player_id] = choices
end

function COverthrowGameMode:FinishItemPick(keys)
	local owner = EntIndexToHScript(keys.owner_entindex)
	local player_id = owner:GetPlayerID()
	local hero = owner:GetClassname()

	local perk = COverthrowGameMode.current_treasure_chest_rewards[player_id][tonumber(keys.slot)]

	-- Add the chosen perk
	print("chosen perk:")
	print(perk)
	if perk == "bonus_gold_t0" then
		owner:ModifyGold(1000, false, DOTA_ModifyGold_HeroKill)
		SendOverheadEventMessage(nil, OVERHEAD_ALERT_GOLD, owner, 1000, nil)
	elseif perk == "bonus_gold_t1" then
		owner:ModifyGold(1500, false, DOTA_ModifyGold_HeroKill)
		SendOverheadEventMessage(nil, OVERHEAD_ALERT_GOLD, owner, 1500, nil)
	elseif perk == "bonus_gold_t2" then
		owner:ModifyGold(2000, false, DOTA_ModifyGold_HeroKill)
		SendOverheadEventMessage(nil, OVERHEAD_ALERT_GOLD, owner, 2000, nil)
	else
		owner:AddNewModifier(owner, nil, perk, {duration = -1})
	end

	EmitGlobalSound("powerup_04")

	local overthrow_item_drop = {
		hero_id = hero,
		dropped_item = perk,
		player_id = player_id
	}

	CustomGameEventManager:Send_ServerToAllClients( "overthrow_item_drop", overthrow_item_drop)
end

function COverthrowGameMode:ThinkSpecialItemDrop()
	-- Stop spawning items after 15
	if self.nNextSpawnItemNumber >= 15 then
		return
	end
	-- Don't spawn if the game is about to end
	if nCOUNTDOWNTIMER < 20 then
		return
	end
	local t = GameRules:GetDOTATime( false, false )
	local tSpawn = ( self.spawnTime * self.nNextSpawnItemNumber )
	local tWarn = tSpawn - 15

	if not self.hasWarnedSpawn and t >= tWarn then
		-- warn the item is about to spawn
		self:WarnItem()
		self.hasWarnedSpawn = true
	elseif t >= tSpawn then
		-- spawn the item
		self:SpawnItem()
		self.nNextSpawnItemNumber = self.nNextSpawnItemNumber + 1
		self.hasWarnedSpawn = false
	end
end

function COverthrowGameMode:PlanNextSpawn()
	local missingSpawnPoint =
	{
		origin = "0 0 384",
		targetname = "item_spawn_missing"
	}

	local r = RandomInt( 1, 8 )
	if GetMapName() == "desert_quintet" or GetMapName() == "desert_octet" or GetMapName() == "core_quartet" then
		r = RandomInt( 1, 6 )
	elseif GetMapName() == "temple_quartet" then
		r = RandomInt( 1, 4 )
	end
	local path_track = "item_spawn_" .. r
	local spawnPoint = Vector( 0, 0, 700 )
	local spawnLocation = Entities:FindByName( nil, path_track )

	if spawnLocation == nil then
		spawnLocation = SpawnEntityFromTableSynchronous( "path_track", missingSpawnPoint )
		spawnLocation:SetAbsOrigin(spawnPoint)
	end

	self.itemSpawnLocation = spawnLocation
	self.itemSpawnIndex = r
end

function COverthrowGameMode:WarnItem()
	-- find the spawn point
	self:PlanNextSpawn()

	local spawnLocation = self.itemSpawnLocation:GetAbsOrigin();

	-- notify everyone
	CustomGameEventManager:Send_ServerToAllClients( "item_will_spawn", { spawn_location = spawnLocation } )
	EmitGlobalSound( "powerup_03" )

	-- fire the destination particles
	DoEntFire( "item_spawn_particle_" .. self.itemSpawnIndex, "Start", "0", 0, self, self )

	-- Give vision to the spawn area (unit is on goodguys, but shared vision)
	local visionRevealer = CreateUnitByName( "npc_vision_revealer", spawnLocation, false, nil, nil, DOTA_TEAM_GOODGUYS )
	visionRevealer:SetContextThink( "KillVisionRevealer", function() return visionRevealer:RemoveSelf() end, 35 )
	local trueSight = ParticleManager:CreateParticle( "particles/econ/wards/f2p/f2p_ward/f2p_ward_true_sight_ambient.vpcf", PATTACH_ABSORIGIN, visionRevealer )
	ParticleManager:SetParticleControlEnt( trueSight, PATTACH_ABSORIGIN, visionRevealer, PATTACH_ABSORIGIN, "attach_origin", visionRevealer:GetAbsOrigin(), true )
	visionRevealer:SetContextThink( "KillVisionParticle", function() return trueSight:RemoveSelf() end, 35 )
end

function COverthrowGameMode:SpawnItem()
	-- notify everyone
	CustomGameEventManager:Send_ServerToAllClients( "item_has_spawned", {} )
	EmitGlobalSound( "powerup_05" )

	-- spawn the item
	local startLocation = Vector( 0, 0, 700 )
	local treasureCourier = CreateUnitByName( "npc_dota_treasure_courier" , startLocation, true, nil, nil, DOTA_TEAM_NEUTRALS )
	local treasureAbility = treasureCourier:FindAbilityByName( "dota_ability_treasure_courier" )
	treasureAbility:SetLevel( 1 )
    --print ("Spawning Treasure")
    targetSpawnLocation = self.itemSpawnLocation
    treasureCourier:SetInitialGoalEntity(targetSpawnLocation)
    local particleTreasure = ParticleManager:CreateParticle( "particles/items_fx/black_king_bar_avatar.vpcf", PATTACH_ABSORIGIN, treasureCourier )
	ParticleManager:SetParticleControlEnt( particleTreasure, PATTACH_ABSORIGIN, treasureCourier, PATTACH_ABSORIGIN, "attach_origin", treasureCourier:GetAbsOrigin(), true )
	treasureCourier:Attribute_SetIntValue( "particleID", particleTreasure )
end

function COverthrowGameMode:ForceSpawnItem()
	self:WarnItem()
	self:SpawnItem()
end

function COverthrowGameMode:KnockBackFromTreasure( center, radius, knockback_duration, knockback_distance, knockback_height )
	local targetType = bit.bor( DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_HERO )
	local knockBackUnits = FindUnitsInRadius( DOTA_TEAM_NOTEAM, center, nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, targetType, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false )

	local modifierKnockback =
	{
		center_x = center.x,
		center_y = center.y,
		center_z = center.z,
		duration = knockback_duration,
		knockback_duration = knockback_duration,
		knockback_distance = knockback_distance,
		knockback_height = knockback_height,
	}

	for _,unit in pairs(knockBackUnits) do
--		print( "knock back unit: " .. unit:GetName() )
		unit:AddNewModifier( unit, nil, "modifier_knockback", modifierKnockback );
	end
end


function COverthrowGameMode:TreasureDrop( treasureCourier )
	--Create the death effect for the courier
	local spawnPoint = treasureCourier:GetInitialGoalEntity():GetAbsOrigin()
	spawnPoint.z = 400
	local fxPoint = treasureCourier:GetInitialGoalEntity():GetAbsOrigin()
	fxPoint.z = 400
	local deathEffects = ParticleManager:CreateParticle( "particles/treasure_courier_death.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl( deathEffects, 0, fxPoint )
	ParticleManager:SetParticleControlOrientation( deathEffects, 0, treasureCourier:GetForwardVector(), treasureCourier:GetRightVector(), treasureCourier:GetUpVector() )
	EmitGlobalSound( "lockjaw_Courier.Impact" )
	EmitGlobalSound( "lockjaw_Courier.gold_big" )

	--Spawn the treasure chest at the selected item spawn location
	local newItem = CreateItem( "item_treasure_chest", nil, nil )
	local drop = CreateItemOnPositionForLaunch( spawnPoint, newItem )
	drop:SetForwardVector( treasureCourier:GetRightVector() ) -- oriented differently
	newItem:LaunchLootInitialHeight( false, 0, 50, 0.25, spawnPoint )

	COverthrowGameMode.current_chest = COverthrowGameMode.current_chest + 1
	COverthrowGameMode.treasure_chest_spawns[COverthrowGameMode.current_chest] = newItem
	newItem.spawn_number = COverthrowGameMode.current_chest

	--Stop the particle effect
	DoEntFire( "item_spawn_particle_" .. self.itemSpawnIndex, "stopplayendcap", "0", 0, self, self )

	--Knock people back from the treasure
	self:KnockBackFromTreasure( spawnPoint, 375, 0.25, 400, 100 )

	--Destroy the courier
	UTIL_Remove( treasureCourier )
end

function COverthrowGameMode:ForceSpawnGold()
	self:SpawnDropInMiddle(DROP_GOLD)
end

function COverthrowGameMode:ThinkPumpkins()
	local now = GameRules:GetDOTATime(false, false)
	for _, spawner in ipairs(self.pumpkin_spawns) do
		if not spawner.itemIndex and now >= spawner.nextSpawn then
			local item = CreateItem("item_core_pumpkin", nil, nil)
			spawner.itemIndex = item:GetEntityIndex()
			local container = CreateItemOnPositionForLaunch(spawner.position, item)
			ParticleManager:CreateParticle("particles/items3_fx/fish_bones_active.vpcf", PATTACH_ABSORIGIN, container)
			item:LaunchLootInitialHeight(false, 0, 0, 0.5, spawner.position)
		end
	end
end
