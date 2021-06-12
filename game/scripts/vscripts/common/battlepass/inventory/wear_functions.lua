WearFunc = WearFunc or {}
LinkLuaModifier("modifier_cosmetic_pet", "common/battlepass/inventory/modifiers/modifier_cosmetic_pet", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dummy_caster", "common/battlepass/inventory/modifiers/modifier_dummy_caster", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_cosmetic_pet_flying_visual", "common/battlepass/inventory/modifiers/modifier_cosmetic_pet_flying_visual", LUA_MODIFIER_MOTION_NONE)

function WearFunc:Init()
	self.cooldown_for_kill_effects = {}

	for _, category in pairs(BP_Inventory.categories) do
		WearFunc[category] = {}
	end
	-- Just a crutch
	WearFunc.Masteries = {}
	ListenToGameEvent( "entity_killed", Dynamic_Wrap( self, "OnEntityKilled" ), self )
end

function WearFunc:EquipItemInCategory(player_id, category, item_name)
	if not player_id or not category then return end

	local hero = PlayerResource:GetSelectedHeroEntity(player_id)
	if not hero then return end

	if not WearFunc[category] then return end

	local init_category_for_player = function(t)
		if not WearFunc[category][player_id] then
			WearFunc[category][player_id] = t
			return false
		end
		return true
	end

	if category == CHC_ITEM_TYPE_MASTERIES then
		local itemLevel = BP_Masteries:GetMasteryLevel(player_id, item_name);
		if itemLevel < 1 then return end

		local current_masteries_count = BP_Masteries.players_current_masteries_count[player_id]
		if current_masteries_count >= BP_Masteries.players_masteries_count[player_id] then
			return
		end

		init_category_for_player({})

		BP_Masteries.players_current_masteries_count[player_id] = current_masteries_count + 1
		table.insert(WearFunc[category][player_id], item_name)
		BP_Masteries:EquipMastery(hero, item_name, itemLevel)
		BP_Masteries:UpdateEquippedMastery(player_id)
		return
	end

	if category == CHC_ITEM_TYPE_AURAS then
		if init_category_for_player({}) then
			BP_Inventory:TakeOffItem({ PlayerID = player_id, item_name = WearFunc[category][player_id].item_name })
		end

		local particles = BP_Inventory.item_definitions[item_name].Particles
		WearFunc[category][player_id].item_name = item_name
		WearFunc[category][player_id].equipped_particles = {}
		WearFunc:_CreateParticlesFromConfigList(particles, PlayerResource:GetSelectedHeroEntity(player_id), WearFunc[category][player_id].equipped_particles)
		return
	end

	if category == CHC_ITEM_TYPE_HERO_SKINS then
		if init_category_for_player({}) then
			BP_Inventory:TakeOffItem({ PlayerID = player_id, item_name = WearFunc[category][player_id].item_name })
		end

		WearFunc[category][player_id].item_name = item_name
		hero:AddNewModifier(hero, nil, "modifier_cosmetic_skin_"..item_name, {})
		return
	end

	if category == CHC_ITEM_TYPE_PETS then
		init_category_for_player( { particles = {} })

		local old_pet = WearFunc[category][player_id].unit
		local old_pet_pos
		local old_pet_dir
		local pet_data = BP_Inventory.item_definitions[item_name]
		local pet
		if old_pet then
			old_pet_pos = old_pet:GetAbsOrigin()
			old_pet_dir = old_pet:GetForwardVector()
			old_pet.notRemove = true;
			BP_Inventory:TakeOffItem({ PlayerID = player_id, item_name = WearFunc[category][player_id].item_name})
			pet = old_pet
			pet:StartGesture( ACT_DOTA_SPAWN );
			pet.notRemove = nil;
		else
			pet = CreateUnitByName("npc_cosmetic_pet", old_pet_pos or hero:GetAbsOrigin() + RandomVector(RandomInt(100, 160)), true, hero, hero, hero:GetTeam())
		end

		pet:SetForwardVector(old_pet_dir or hero:GetAbsOrigin())
		pet:AddNewModifier(pet, nil, "modifier_cosmetic_pet", { hero = PlayerResource:GetSelectedHeroEntity(player_id) })
		pet:SetModel(pet_data.Model)
		pet:SetOriginalModel(pet_data.Model)
		pet:SetModelScale(pet_data.ModelScale)

		if pet_data.MaterialGroup then
			pet:SetMaterialGroup(tostring(pet_data.MaterialGroup))
		end

		if pet_data.IsFlying then
			pet:AddNewModifier(pet, nil, "modifier_cosmetic_pet_flying_visual", {})
		end

		if pet_data.Particles then
			WearFunc:_CreateParticlesFromConfigList(pet_data.Particles, pet, WearFunc[category][player_id].particles)
		end
		WearFunc[category][player_id].item_name = item_name
		WearFunc[category][player_id].unit = pet
		return
	end

	if category == CHC_ITEM_TYPE_KILL_EFFECTS then
		if init_category_for_player({}) then
			BP_Inventory:TakeOffItem({ PlayerID = player_id, item_name = WearFunc[category][player_id].item_name })
		end
		WearFunc[category][player_id].item_name = item_name
		WearFunc[category][player_id].particles = BP_Inventory.item_definitions[item_name].Particles
		return
	end

	if category == CHC_ITEM_TYPE_BARRAGES then
		if WearFunc[category][player_id] and WearFunc[category][player_id] ~= item_name then
			BP_Inventory:TakeOffItem({ PlayerID = player_id, item_name = WearFunc[category][player_id] })
		end
		WearFunc[category][player_id] = item_name
		CustomNetTables:SetTableValue("player_settings", "barrageEffects_" .. player_id, { barrageCosmeticEffect = item_name })
		return
	end

	if category == CHC_ITEM_TYPE_COSMETIC_ABILITIES then
		if not hero.dummy_caster then return end

		if WearFunc[category][player_id] and WearFunc[category][player_id] ~= item_name then
			BP_Inventory:TakeOffItem({ PlayerID = player_id, item_name = WearFunc[category][player_id] })
		end
		WearFunc[category][player_id] = item_name

		hero.dummy_caster:RemoveAbility( "default_cosmetic_ability" )
		Cosmetics:AddAbility(hero.dummy_caster, item_name)
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(player_id), "cosmetic_abilities:update_ability", {ability = item_name})
		return
	end

	if category == CHC_ITEM_TYPE_SPRAYS then
		if init_category_for_player({ item_name = item_name }) then
			BP_Inventory:TakeOffItem({ PlayerID = player_id, item_name = WearFunc[category][player_id].item_name})
			WearFunc[category][player_id].item_name = item_name
		end
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(player_id), "cosmetic_abilities:update_spray", {spray = item_name})
		return
	end
end

function WearFunc:TakeOffItemInCategory(player_id, category, item_name)
	if not player_id or not category then return end

	local hero = PlayerResource:GetSelectedHeroEntity(player_id)
	if not hero then return end

	local category_table = WearFunc[category]
	if not category_table then return end

	if not WearFunc[category][player_id] then return end

	if category == CHC_ITEM_TYPE_MASTERIES then
		for _, masteryName in pairs(WearFunc[category][player_id]) do
			BP_Masteries:TakeOffMastery(hero, masteryName)
		end
		BP_Masteries.players_current_masteries_count[player_id] = 0
		WearFunc[category][player_id] = {}
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(player_id), "masteries:take_off_mastery", {})

		CustomGameEventManager:Send_ServerToAllClients("masteries:update_public_masteries", {
			masteries = {[player_id] = {}};
		})

		return
	end

	if category == CHC_ITEM_TYPE_AURAS then
		if WearFunc[category][player_id].equipped_particles then
			for _, particle in pairs(WearFunc[category][player_id].equipped_particles) do
				ParticleManager:DestroyParticle(particle, true)
				ParticleManager:ReleaseParticleIndex( particle )
			end
		end
		WearFunc[category][player_id] = {}
		return
	end

	if category == CHC_ITEM_TYPE_HERO_SKINS then
		if hero then hero:RemoveModifierByName("modifier_cosmetic_skin_"..WearFunc[category][player_id].item_name) end
		WearFunc[category][player_id] = {}
		return
	end
	if category == CHC_ITEM_TYPE_PETS then
		local pet = WearFunc[category][player_id].unit
		if pet then
			local destory_pet_particle = ParticleManager:CreateParticle( "particles/units/heroes/hero_monkey_king/monkey_king_disguise_smoke_top.vpcf", PATTACH_WORLDORIGIN, nil )
			ParticleManager:SetParticleControl( destory_pet_particle, 0, pet:GetAbsOrigin() )
			ParticleManager:ReleaseParticleIndex( destory_pet_particle )
			if not pet.notRemove then
				pet:RemoveNoDraw()
				pet:Destroy()
			end
		end

		if WearFunc[category][player_id].particles then
			for _, particle in pairs(WearFunc[category][player_id].particles) do
				ParticleManager:DestroyParticle(particle, true)
				ParticleManager:ReleaseParticleIndex( particle )
			end
		end

		WearFunc[category][player_id].unit = nil
		return
	end
	if category == CHC_ITEM_TYPE_KILL_EFFECTS then
		WearFunc[category][player_id] = {}
		return
	end
	if category == CHC_ITEM_TYPE_BARRAGES then
		CustomNetTables:SetTableValue("player_settings", "barrageEffects_" .. player_id, { barrageCosmeticEffect = nil })
		return
	end
	if category == CHC_ITEM_TYPE_COSMETIC_ABILITIES then
		hero.dummy_caster:RemoveAbility( WearFunc[category][player_id] )
		Cosmetics:AddAbility(hero.dummy_caster, "default_cosmetic_ability")
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(player_id), "cosmetic_abilities:update_ability", {ability = "default_cosmetic_ability"})
		return
	end
	if category == CHC_ITEM_TYPE_SPRAYS then
		WearFunc[category][player_id].item_name = nil
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(player_id), "cosmetic_abilities:update_spray", {spray = ""})
		return
	end
end


function WearFunc:CreateKilledEffect(killer, killedUnit)
	local category_table = WearFunc[CHC_ITEM_TYPE_KILL_EFFECTS]
	if not category_table then return end
	if not killer or not killer.GetPlayerOwnerID then return end

	local player_id = killer:GetPlayerOwnerID()

	if WearFunc[CHC_ITEM_TYPE_KILL_EFFECTS][player_id]
		and WearFunc[CHC_ITEM_TYPE_KILL_EFFECTS][player_id].particles then
		WearFunc:_CreateParticlesFromConfigList(WearFunc[CHC_ITEM_TYPE_KILL_EFFECTS][player_id].particles, killedUnit)
	end
end

function WearFunc:_CreateParticlesFromConfigList(particles_data, target, save_data)
	for _, partcile_data in pairs(particles_data) do
		local particle = ParticleManager:CreateParticle(partcile_data.ParticleName, _G[partcile_data.ParticleAttach], target)
		if partcile_data.CP then
			for number, cp in pairs(partcile_data.CP) do
				number = tonumber(number)
				ParticleManager:SetParticleControlEnt(particle, number, target, _G[partcile_data.ParticleAttach], cp.attachment, target:GetAbsOrigin(), true)
			end
		end
		if save_data then
			table.insert(save_data, particle)
		else
			ParticleManager:ReleaseParticleIndex(particle)
		end
	end
end

function WearFunc:OnEntityKilled(data)
	local killed_unit = data.entindex_killed and EntIndexToHScript(data.entindex_killed)
	local attacker_unit = data.entindex_attacker and EntIndexToHScript( data.entindex_attacker )

	if attacker_unit and killed_unit then
		if killed_unit.IsRealHero and killed_unit:IsRealHero() then
			self:CreateKilledEffect(attacker_unit, killed_unit)
		else
			local player_id = attacker_unit.GetPlayerOwnerID and attacker_unit:GetPlayerOwnerID()
			if player_id then
				local last_time_kill_effect = self.cooldown_for_kill_effects[player_id]
				local gameTime = GameRules:GetGameTime()

				-- Cooldown for kill effect for NON hero kills
				if not last_time_kill_effect or ((gameTime - last_time_kill_effect) > 10) then
					self.cooldown_for_kill_effects[player_id] = gameTime
					self:CreateKilledEffect(attacker_unit, killed_unit)
				end
			end
		end
	end
end
