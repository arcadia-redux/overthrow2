    function OnStartTouch(trigger)
			local heroHandle = trigger.activator
			local player = heroHandle:GetPlayerID()
            local point = Entities:FindByName( nil, "gy_teleport_spot_dire" ):GetAbsOrigin()
            FindClearSpaceForUnit(heroHandle, point, true)
			local tpEffects = ParticleManager:CreateParticle( "particles/econ/events/fall_major_2015/teleport_end_fallmjr_2015_ground_flash.vpcf", PATTACH_ABSORIGIN, heroHandle )
			ParticleManager:SetParticleControlEnt( tpEffects, PATTACH_ABSORIGIN, heroHandle, PATTACH_ABSORIGIN, "attach_origin", heroHandle:GetAbsOrigin(), true )
			heroHandle:Attribute_SetIntValue( "effectsID", tpEffects )
			DoEntFire( "teleport_particle_radiant", "Start", "", 0, self, self )
			
            trigger.activator:Stop()
			
			PlayerResource:SetCameraTarget( player, heroHandle )
			StartSoundEvent( "Portal.Hero_Appear", heroHandle )
			heroHandle:SetContextThink( "KillSetCameraTarget", function() return PlayerResource:SetCameraTarget( player, nil ) end, 0.2 )
			heroHandle:SetContextThink( "KillTPEffects", function() return ParticleManager:DestroyParticle( tpEffects, true ) end, 3 )
    end
