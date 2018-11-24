function OnStartTouch(args)
	local unit = args.activator
	if not unit:IsControllableByAnyPlayer() or unit:IsCourier() then return end

	local teamId = args.caller:GetName():gsub("gy_teleport_", "")
	local position = COverthrowGameMode:GetCoreTeleportTarget(tonumber(teamId))
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

	unit:RemoveModifierByName("modifier_core_spawn_movespeed")
	unit:AddNewModifier(unit, nil, "modifier_core_spawn_movespeed", { xp = isMainHero })
	unit:AddNewModifier(unit, xpGranterAbility, "modifier_invisible", { duration = 15 })
end
