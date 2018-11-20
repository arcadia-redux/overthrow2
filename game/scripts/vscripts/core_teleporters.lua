function OnStartTouch(args)
	local unit = args.activator
	if not unit:IsControllableByAnyPlayer() or unit:IsCourier() then return end

	local teamId = args.caller:GetName():gsub("gy_teleport_", "")
	local timeOfDay = GameRules:IsDaytime() and "day" or "night"
	local position = Entities:FindByName(nil, "teleport_" .. teamId .. "_" .. timeOfDay):GetAbsOrigin()
	local triggerPosition = args.caller:GetAbsOrigin()

	EmitSoundOnLocationWithCaster(triggerPosition, "Portal.Hero_Appear", unit)
	local startParticleId = ParticleManager:CreateParticle("particles/econ/events/fall_major_2015/teleport_end_fallmjr_2015_ground_flash.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(startParticleId, 0, triggerPosition)

	FindClearSpaceForUnit(unit, position, true)
	unit:Stop()

	unit:EmitSound("Portal.Hero_Appear")
	local endParticleId = ParticleManager:CreateParticle("particles/econ/events/fall_major_2015/teleport_end_fallmjr_2015_ground_flash.vpcf", PATTACH_ABSORIGIN, unit)
	ParticleManager:SetParticleControlEnt(endParticleId, 0, unit, PATTACH_ABSORIGIN, "attach_origin", unit:GetAbsOrigin(), true)

	local playerId = unit:GetPlayerOwnerID()
	local isMainHero = PlayerResource:GetSelectedHeroEntity(playerId) == unit
	if isMainHero then
		PlayerResource:SetCameraTarget(playerId, unit)
		unit:SetContextThink("CoreTeleportUnlockCamera", function() return PlayerResource:SetCameraTarget(playerId, nil) end, 0.1)
	end

	unit:AddNewModifier(unit, nil, "modifier_core_spawn_movespeed", { duration = 10 })
	if isMainHero then
		local xpGranterAbility
		for _, v in ipairs(Entities:FindAllByClassname("npc_dota_creature")) do
			if v:GetUnitName():starts("npc_dota_xp_granter") then
				xpGranterAbility = v:GetAbilityByIndex(0)
				break
			end
		end
		if xpGranterAbility then
			unit:AddNewModifier(unit, xpGranterAbility, "modifier_get_xp", { duration = 10 })
		end
	end
end
