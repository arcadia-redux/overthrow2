item_treasure_chest = class({})

treasure_chest_channel = class({})

function treasure_chest_channel:IsHiddenAbilityCastable()
	return true
end

function treasure_chest_channel:OnSpellStart()
	if IsServer() then
		self:GetCaster():EmitSound("Treasure.ChannelLoop")
	end
end

function treasure_chest_channel:GetChannelAnimation()
	return ACT_DOTA_GENERIC_CHANNEL_1
end

function treasure_chest_channel:OnChannelFinish(interrupted)
	if IsServer() then
		local caster = self:GetCaster()
		if not interrupted then

			local success_pfx = ParticleManager:CreateParticle("particles/treasure_courier_death.vpcf", PATTACH_CUSTOMORIGIN, nil)
			ParticleManager:SetParticleControl(success_pfx, 0, caster:GetAbsOrigin())
			ParticleManager:SetParticleControlOrientation(success_pfx, 0, caster:GetForwardVector(), caster:GetRightVector(), caster:GetUpVector())

			caster:EmitSound("Treasure.ChannelEnd")

			CustomGameEventManager:Send_ServerToAllClients("OnPickedUpItem", {position = caster:GetAbsOrigin(), itemName = "item_treasure_chest_notification_dummy", tier = 5})

			COverthrowGameMode:SpecialItemAdd(caster)

			local hero_list = HeroList:GetAllHeroes()
			for _, hero in pairs(hero_list) do
				if hero ~= caster and hero.channeling_treasure == caster.channeling_treasure then
					hero:InterruptChannel()
				end
			end

			if COverthrowGameMode.treasure_chest_spawns[caster.channeling_treasure] and COverthrowGameMode.treasure_chest_spawns[caster.channeling_treasure]:GetContainer() then
				COverthrowGameMode.treasure_chest_spawns[caster.channeling_treasure]:GetContainer():Destroy()
				COverthrowGameMode.treasure_chest_spawns[caster.channeling_treasure]:Destroy()
			end
		end

		caster:StopSound("Treasure.ChannelLoop")
		caster.channeling_treasure = nil
		self:Destroy()	
	end
end