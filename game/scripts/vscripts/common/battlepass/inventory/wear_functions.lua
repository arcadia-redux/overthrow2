WearFunc = WearFunc or {}
LinkLuaModifier("modifier_cosmetic_pet", "common/battlepass/inventory/modifiers/modifier_cosmetic_pet", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dummy_caster", "common/battlepass/inventory/modifiers/modifier_dummy_caster", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_cosmetic_pet_flying_visual", "common/battlepass/inventory/modifiers/modifier_cosmetic_pet_flying_visual", LUA_MODIFIER_MOTION_NONE)

function WearFunc:Init()
	for category, _ in pairs(BP_Inventory.categories) do
		WearFunc[category] = {}
	end
	ListenToGameEvent( "entity_killed", Dynamic_Wrap( self, "OnEntityKilled" ), self )
end

function WearFunc:OnEntityKilled(data)
	local hKilledUnit = data.entindex_killed and EntIndexToHScript(data.entindex_killed)
	local hAttackerUnit = data.entindex_attacker and EntIndexToHScript( data.entindex_attacker )
	if hAttackerUnit and hKilledUnit and hKilledUnit.IsRealHero and hKilledUnit:IsRealHero() then
		WearFunc:CreateKilledEffect(hAttackerUnit, hKilledUnit)
	end
end

function WearFunc.Equip_CosmeticAbilities(playerId, itemName)
	if WearFunc.CosmeticAbilities[playerId] and WearFunc.CosmeticAbilities[playerId] ~= itemName then
		BP_Inventory:TakeOffItem({ PlayerID = playerId, itemName = WearFunc.CosmeticAbilities[playerId] })
	end
	WearFunc.CosmeticAbilities[playerId] = itemName

	local hero = PlayerResource:GetSelectedHeroEntity(playerId)
	hero.dummyCaster:RemoveAbility( "default_cosmetic_ability" )
	Cosmetics:AddAbility(hero.dummyCaster, itemName)
	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerId), "cosmetic_abilities:update_ability", {ability = itemName})
end

function WearFunc.TakeOff_CosmeticAbilities(playerId)
	if not WearFunc.CosmeticAbilities[playerId] then return end
	local abilityName = WearFunc.CosmeticAbilities[playerId]
	local hero = PlayerResource:GetSelectedHeroEntity(playerId)
	hero.dummyCaster:RemoveAbility( abilityName )
	Cosmetics:AddAbility(hero.dummyCaster, "default_cosmetic_ability")
	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerId), "cosmetic_abilities:update_ability", {ability = "default_cosmetic_ability"})
end

function WearFunc.Equip_Barrages(playerId, itemName)
	if WearFunc.Barrages[playerId] and WearFunc.Barrages[playerId] ~= itemName then
		BP_Inventory:TakeOffItem({ PlayerID = playerId, itemName = WearFunc.Barrages[playerId] })
	end
	WearFunc.Barrages[playerId] = itemName
	CustomNetTables:SetTableValue("player_settings", "barrageEffects_" .. playerId, { barrageCosmeticEffect = itemName })
end

function WearFunc.TakeOff_Barrages(playerId)
	CustomNetTables:SetTableValue("player_settings", "barrageEffects_" .. playerId, { barrageCosmeticEffect = nil })
end

function WearFunc:CreateKilledEffect(killer, killedUnit)
	if not killer or not killer.GetPlayerOwnerID then return end
	local playerId = killer:GetPlayerOwnerID()
	if not WearFunc.KillEffects[playerId] then return end
	if WearFunc.KillEffects[playerId] and WearFunc.KillEffects[playerId].particles then
		WearFunc:_CreateParticlesFromConfigList(WearFunc.KillEffects[playerId].particles, killedUnit)
	end
end

function WearFunc.Equip_KillEffects(playerId, itemName)
	if not WearFunc.KillEffects[playerId] then
		WearFunc.KillEffects[playerId] = {}
	else
		BP_Inventory:TakeOffItem({ PlayerID = playerId, itemName = WearFunc.KillEffects[playerId].itemName })
	end
	WearFunc.KillEffects[playerId].itemName = itemName
	WearFunc.KillEffects[playerId].particles = BP_Inventory.item_definitions[itemName].Particles
end

function WearFunc.TakeOff_KillEffects(playerId)
	if not WearFunc.KillEffects[playerId] then return end
	WearFunc.KillEffects[playerId] = {}
end

function WearFunc.TakeOff_Auras(playerId)
	if not WearFunc.Auras[playerId] then return end
	if WearFunc.Auras[playerId].equippedParticles then
		for _, particle in pairs(WearFunc.Auras[playerId].equippedParticles) do
			ParticleManager:DestroyParticle(particle, true)
			ParticleManager:ReleaseParticleIndex( particle )
		end
	end
	WearFunc.Auras[playerId] = {}
end

function WearFunc.Equip_Auras(playerId, itemName)
	if not WearFunc.Auras[playerId] then
		WearFunc.Auras[playerId] = {}
	else
		BP_Inventory:TakeOffItem({ PlayerID = playerId, itemName = WearFunc.Auras[playerId].itemName })
	end

	local particles = BP_Inventory.item_definitions[itemName].Particles
	WearFunc.Auras[playerId].itemName = itemName
	WearFunc.Auras[playerId].equippedParticles = {}
	WearFunc:_CreateParticlesFromConfigList(particles, PlayerResource:GetSelectedHeroEntity(playerId), WearFunc.Auras[playerId].equippedParticles)
end

function WearFunc.TakeOff_Pets(playerId)
	if not WearFunc.Pets[playerId] then return end
	local pet = WearFunc.Pets[playerId].unit
	if pet then
		local destoryPetParticle = ParticleManager:CreateParticle( "particles/units/heroes/hero_monkey_king/monkey_king_disguise_smoke_top.vpcf", PATTACH_WORLDORIGIN, nil )
		ParticleManager:SetParticleControl( destoryPetParticle, 0, pet:GetAbsOrigin() )
		ParticleManager:ReleaseParticleIndex( destoryPetParticle )
		if not pet.notRemove then
			pet:RemoveNoDraw()
			pet:Destroy()
		end
	end

	if WearFunc.Pets[playerId].particles then
		for _, particle in pairs(WearFunc.Pets[playerId].particles) do
			ParticleManager:DestroyParticle(particle, true)
			ParticleManager:ReleaseParticleIndex( particle )
		end
	end
	WearFunc.Pets[playerId].unit = nil
end

function WearFunc.Equip_Pets(playerId, itemName)
	if not WearFunc.Pets[playerId] then
		WearFunc.Pets[playerId] = { particles = {} }
	end

	local oldPet = WearFunc.Pets[playerId] and WearFunc.Pets[playerId].unit
	local oldPetPos
	local oldPetDir
	local hero = PlayerResource:GetSelectedHeroEntity(playerId)
	local petData = BP_Inventory.item_definitions[itemName]
	local pet
	if oldPet then
		oldPetPos = oldPet:GetAbsOrigin()
		oldPetDir = oldPet:GetForwardVector()
		oldPet.notRemove = true;
		BP_Inventory:TakeOffItem({ PlayerID = playerId, itemName = WearFunc.Pets[playerId].itemName})
		pet = oldPet
		pet:StartGesture( ACT_DOTA_SPAWN );
		pet.notRemove = nil;
	else
		pet = CreateUnitByName("npc_cosmetic_pet", oldPetPos or hero:GetAbsOrigin() + RandomVector(RandomInt(100, 160)), true, hero, hero, hero:GetTeam())
	end

	pet:SetForwardVector(oldPetDir or hero:GetAbsOrigin())
	pet:AddNewModifier(pet, nil, "modifier_cosmetic_pet", { hero = PlayerResource:GetSelectedHeroEntity(playerId) })
	pet:SetModel(petData.Model)
	pet:SetOriginalModel(petData.Model)
	pet:SetModelScale(petData.ModelScale)

	if petData.MaterialGroup then
		pet:SetMaterialGroup(tostring(petData.MaterialGroup))
	end

	if petData.IsFlying then
		pet:AddNewModifier(pet, nil, "modifier_cosmetic_pet_flying_visual", {})
	end

	if petData.Particles then
		WearFunc:_CreateParticlesFromConfigList(petData.Particles, pet, WearFunc.Pets[playerId].particles)
	end
	WearFunc.Pets[playerId].itemName = itemName
	WearFunc.Pets[playerId].unit = pet
end

function WearFunc.Equip_Sprays( playerId, itemName )
	if not WearFunc.Sprays[playerId] then
		WearFunc.Sprays[playerId] = {
			itemName = itemName
		}
	else
		BP_Inventory:TakeOffItem({ PlayerID = playerId, itemName = WearFunc.Sprays[playerId].itemName})
		WearFunc.Sprays[playerId].itemName = itemName
	end
	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerId), "cosmetic_abilities:update_spray", {spray = itemName})
end

function WearFunc.TakeOff_Sprays(playerId)
	if not WearFunc.Sprays[playerId] then return end
	WearFunc.Sprays[playerId].itemName = nil
	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerId), "cosmetic_abilities:update_spray", {spray = ""})
end

function WearFunc.Equip_Masteries(playerId, itemName)
	local itemLevel = BP_Masteries:GetMasteryLevel(playerId, itemName);
	if itemLevel < 1 then return end
	if not WearFunc.Masteries[playerId] then
		WearFunc.Masteries[playerId] = {
			itemName = itemName
		}
	else
		BP_Inventory:TakeOffItem({ PlayerID = playerId, itemName = WearFunc.Masteries[playerId].itemName})
		WearFunc.Masteries[playerId].itemName = itemName
	end

	local hero = PlayerResource:GetSelectedHeroEntity(playerId)
	BP_Masteries:EquipMastery(hero, itemName, itemLevel)
	BP_Masteries:UpdateEquippedMastery(playerId)
end

function WearFunc.TakeOff_Masteries(playerId)
	if not WearFunc.Masteries[playerId] then return end
	local hero = PlayerResource:GetSelectedHeroEntity(playerId)
	BP_Masteries:TakeOffMastery(hero, WearFunc.Masteries[playerId].itemName)
	WearFunc.Masteries[playerId].itemName = nil
	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerId), "masteries:take_off_mastery", {})
end

function WearFunc:_CreateParticlesFromConfigList(particlesData, target, saveData)
	for _, particleData in pairs(particlesData) do
		local particle = ParticleManager:CreateParticle(particleData.ParticleName, _G[particleData.ParticleAttach], target)
		if particleData.CP then
			for number, cp in pairs(particleData.CP) do
				number = tonumber(number)
				ParticleManager:SetParticleControlEnt(particle, number, target, _G[particleData.ParticleAttach], cp.attachment, target:GetAbsOrigin(), true)
			end
		end
		if saveData then
			table.insert(saveData, particle)
		else
			ParticleManager:ReleaseParticleIndex(particle)
		end
	end
end
