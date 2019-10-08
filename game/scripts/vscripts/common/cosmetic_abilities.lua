local abilitiyPatreonLevel = {
	["high_five"] = 0,
	["seasonal_ti9_banner"] = 1,
	["seasonal_summon_cny_balloon"] = 1,
	["seasonal_summon_dragon"] = 1,
	["seasonal_summon_cny_tree"] = 1,
	["seasonal_firecrackers"] = 1,
	["seasonal_ti9_shovel"] = 1,
	["seasonal_ti9_instruments"] = 1,
	["seasonal_ti9_monkey"] = 1,
	["seasonal_summon_ti9_balloon"] = 1,
	["seasonal_throw_snowball"] = 1,
	["seasonal_festive_firework"] = 1,
	["seasonal_decorate_tree"] = 1,
	["seasonal_summon_snowman"] = 1,
}

local abilitiesCantBeRemoved = {
	["high_five"] = true,
	["seasonal_ti9_banner"] = true
}

local startingAbilities = {
	"high_five",
	"seasonal_ti9_banner"
}

local MAX_COSMETIC_ABILITIES = 6

Cosmetics = Cosmetics or {
	playerHeroEffects = {},
	playerPetEffects = {},
	playerWardEffects = {},

	playerHeroColors = {},
	playerPetColors = {},
	teamCourierColors = {},
	playerWardColors = {},

	playerKillEffects = {},
	playerPets = {},
}

function Cosmetics:Precache( context )
	print( "Cosmetics precache start" )

	for _, effect in pairs( self.heroEffects ) do
		if effect.resource then
			PrecacheResource( "particle_folder", effect.resource, context )
		end
	end

	for _, p in pairs( self.petsData.particles ) do
		PrecacheResource( "particle", p.particle, context )
	end

	for _, c in pairs( self.petsData.couriers ) do
		PrecacheModel( c.model, context )

		for _, p in pairs( c.particles ) do
			if type( p ) == "string" then
				PrecacheResource( "particle", p, context )
			end
		end
	end

	print( "Cosmetics precache end" )
end

function Cosmetics:Init()
	LinkLuaModifier( "modifier_cosmetic_pet", "common/modifier_cosmetic_pet", LUA_MODIFIER_MOTION_NONE )
	LinkLuaModifier( "modifier_cosmetic_pet_invisible", "common/modifier_cosmetic_pet_invisible", LUA_MODIFIER_MOTION_NONE )

	ListenToGameEvent( "npc_spawned", Dynamic_Wrap( self, "OnNPCSpawned" ), self )
	ListenToGameEvent( "entity_killed", Dynamic_Wrap( self, "OnEntityKilled" ), self )

	RegisterCustomEventListener( "cosmetics_add_ability", Dynamic_Wrap( self, "AddAbility" ) )
	RegisterCustomEventListener( "cosmetics_remove_ability", Dynamic_Wrap( self, "RemvoeAbility" ) )
	RegisterCustomEventListener( "cosmetics_set_hero_effect", Dynamic_Wrap( self, "SetHeroEffect" ) )
	RegisterCustomEventListener( "cosmetics_remove_hero_effect", Dynamic_Wrap( self, "RemoveHeroEffect" ) )
	RegisterCustomEventListener( "cosmetics_set_effect_color", Dynamic_Wrap( self, "SetEffectColor" ) )
	RegisterCustomEventListener( "cosmetics_remove_effect_color", Dynamic_Wrap( self, "RemoveEffectColor" ) )
	RegisterCustomEventListener( "cosmetics_set_kill_effect", Dynamic_Wrap( self, "SetKillEffect" ) )
	RegisterCustomEventListener( "cosmetics_remove_kill_effect", Dynamic_Wrap( self, "RemoveKillEffect" ) )
	RegisterCustomEventListener( "cosmetics_select_pet", Dynamic_Wrap( self, "SelectPet" ) )
	RegisterCustomEventListener( "cosmetics_remove_pet", Dynamic_Wrap( self, "DeletePet" ) )
	RegisterCustomEventListener( "cosmetics_save", Dynamic_Wrap( self, "Save" ) )

	GameRules:GetGameModeEntity():SetContextThink( "cosmetics_think", function()
		self:OnThink()

		return  0.1
	end, 0.4 )
end

local function HidePet( pet, time )
	pet:AddNoDraw()
	pet.isHidden = true
	pet.unhideTime = GameRules:GetDOTATime( false, false ) + time

	local particle = ParticleManager:CreateParticle( "particles/units/heroes/hero_monkey_king/monkey_king_disguise_smoke_top.vpcf", PATTACH_WORLDORIGIN, nil )
	ParticleManager:SetParticleControl( particle, 0, pet:GetAbsOrigin() )
	ParticleManager:ReleaseParticleIndex( particle )
end

local function UnhidePet( pet )
	pet:RemoveNoDraw()
	pet.isHidden = false

	local particle = ParticleManager:CreateParticle( "particles/units/heroes/hero_monkey_king/monkey_king_disguise_smoke_top.vpcf", PATTACH_WORLDORIGIN, nil )
	ParticleManager:SetParticleControl( particle, 0, pet:GetAbsOrigin() )
	ParticleManager:ReleaseParticleIndex( particle )
end

local function CreateEffect( unit, effect, color )
	local attaches = {
		renderorigin_follow = PATTACH_RENDERORIGIN_FOLLOW,
		absorigin_follow = PATTACH_ABSORIGIN_FOLLOW,
		customorigin = PATTACH_CUSTOMORIGIN,
		point_follow = PATTACH_POINT_FOLLOW
	}

	local p = ParticleManager:CreateParticle( effect.system, attaches[effect.attach_type], unit )

	for _, cp in pairs( effect.control_points or {} ) do
		ParticleManager:SetParticleControlEnt( p, cp.control_point_index, unit, attaches[cp.attach_type], cp.attachment, unit:GetAbsOrigin(), true )
	end

	local c = effect.default_color

	if c then
		ParticleManager:SetParticleControl( p, 15, color or Vector( c.r, c.g, c.b ) )
		ParticleManager:SetParticleControl( p, 16, Vector( 1, 0, 0 ) )
	end

	return p
end

function Cosmetics:OnThink()
	local now = GameRules:GetDOTATime( false, false )

	for _, petData in pairs( self.playerPets ) do
		local pet = petData.unit
		local owner = pet:GetOwner()
		local owner_pos = owner:GetAbsOrigin()
		local pet_pos = pet:GetAbsOrigin()
		local distance = ( owner_pos - pet_pos ):Length2D()
		local owner_dir = owner:GetForwardVector()
		local spawn_ability = pet:FindAbilityByName( "cosmetic_pet_spawn_anim" )
		local dir = owner_dir * RandomInt( 110, 140 )

		if owner:IsInvisible() and not pet:HasModifier( "modifier_cosmetic_pet_invisible" ) then
			pet:AddNewModifier( pet, nil, "modifier_cosmetic_pet_invisible", {} )
		elseif not owner:IsInvisible() and pet:HasModifier( "modifier_cosmetic_pet_invisible" ) then
			pet:RemoveModifierByName( "modifier_cosmetic_pet_invisible" )
		end

		if pet.isHidden and pet.unhideTime <= now then
			UnhidePet( pet )
		end

		local enemy_dis
		local near = FindUnitsInRadius(
			owner:GetTeam(),
			pet:GetAbsOrigin(),
			nil,
			300,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO,
			DOTA_UNIT_TARGET_FLAG_NO_INVIS,
			FIND_CLOSEST,
			false
		)[1]

		if near and ( near:GetAbsOrigin() - pet_pos ):Length2D() < 70 then
			HidePet( pet, 100 )
		end

		if distance > 900 then
			if not pet.isHidden then
				HidePet( pet, 0.35 )
			end

			local a = RandomInt( 60, 120 )

			if RandomInt( 1, 2 ) == 1 then
				a = a * -1
			end

			local r = RotatePosition( Vector( 0, 0, 0 ), QAngle( 0, a, 0 ), dir )

			pet:SetAbsOrigin( owner_pos + r )
			pet:SetForwardVector( owner_dir )
		elseif distance > 150 then
			local right = RotatePosition( Vector( 0, 0, 0 ), QAngle( 0, RandomInt( 70, 110 ) * -1, 0 ), dir ) + owner_pos
			local left = RotatePosition( Vector( 0, 0, 0 ), QAngle( 0, RandomInt( 70, 110 ), 0 ), dir ) + owner_pos

			if enemy_dis and enemy_dis < 300 and distance < 400 then
				pet:Stop()
			else
				if ( pet_pos - right ):Length2D() > ( pet_pos - left ):Length2D() then
					pet:MoveToPosition( left )
				else
					pet:MoveToPosition( right )
				end
			end
		elseif distance < 90 then
			pet:MoveToPosition( owner_pos + ( pet_pos - owner_pos ):Normalized() * RandomInt( 110, 140 ) )
		elseif near and ( near:GetAbsOrigin() - pet_pos ):Length2D() < 110 then
			pet:MoveToPosition( pet_pos + ( pet_pos - near:GetAbsOrigin() ):Normalized() * RandomInt( 100, 150 ) )
		end
	end
end

function Cosmetics:OnNPCSpawned( keys )
	local unit = EntIndexToHScript( keys.entindex )
	local n = unit:GetUnitName()

	if unit:IsRealHero() and not unit.cosmeticsLoaded then
		local id = unit:GetPlayerID()
		--[[
		WebApi:Send(
			"path", -- ???
			data,
			function( keys )
				for _, ability in pairs( keys.abilities ) do
					if not unit:FindAbilityByName( ability_name ) then
						local ability = unit:AddAbility( ability_name )

						ability:SetLevel( 1 )
						ability:SetHidden( false )

						local patreon = Patreons:GetPlayerSettings( id )

						if patreon and patreon.level < abilitiyPatreonLevel[ability_name] then
							ability:SetActivated( false )
						end
					else
						break
					end
				end

				if keys.hero_effect ~= -1 then
					self.SetHeroEffect( { PlayerID = id, index = keys.hero_effect, type = "hero" } )
				end
				if keys.pet_effect ~= -1 then
					self.SetHeroEffect( { PlayerID = id, index = keys.pet_effect, type = "pet" } )
				end
				if keys.wards_effect ~= -1 then
					self.SetHeroEffect( { PlayerID = id, index = keys.wards_effect, type = "wards" } )
				end

				if keys.hero_color ~= -1 then
					self.SetEffectColor( { PlayerID = id, index = keys.hero_color, type = "hero" } )
				end
				if keys.pet_color ~= -1 then
					self.SetEffectColor( { PlayerID = id, index = keys.pet_color, type = "pet" } )
				end
				if keys.wards_color ~= -1 then
					self.SetEffectColor( { PlayerID = id, index = keys.wards_color, type = "wards" } )
				end

				if keys.kill_effect ~= -1 then
					self.SetKillEffect( { PlayerID = id, index = keys.kill_effect } )
				end

				if keys.pet ~= -1 then
					self.SelectPet( { PlayerID = id, index = keys.pet } )
				end
			end,
			function() end
		)
		]]

		for _, ability_name in pairs( startingAbilities ) do
			if not unit:FindAbilityByName( ability_name ) then
				local ability = unit:AddAbility( ability_name )

				ability:SetLevel( 1 )
				ability:SetHidden( false )

				local patreon = Patreons:GetPlayerSettings( id )

				if patreon and patreon.level < abilitiyPatreonLevel[ability_name] then
					ability:SetActivated( false )
				end
			else
				break
			end
		end

		unit.cosmeticsLoaded = true
	elseif n == "npc_dota_observer_wards" or n == "npc_dota_sentry_wards" then
		local id = unit:GetOwner():GetPlayerID()

		if self.playerWardEffects[id] then
			if self.playerWardEffects[id].effect then
				local c = self.playerWardColors[id]
				unit.cosmeticEffect = CreateEffect( unit, self.playerWardEffects[id].effect, c and c.color or nil )
			end

			table.insert( self.playerWardEffects[id].wards, unit )
		else
			self.playerWardEffects[id] = {
				wards = { unit }
			}
		end
	end
end

function Cosmetics:OnEntityKilled( keys )
	local victim = EntIndexToHScript( keys.entindex_killed )
	local killer = EntIndexToHScript( keys.entindex_attacker or -1 )

	if killer then
		local id = killer:GetPlayerOwnerID()

		if Cosmetics.playerKillEffects[id] then
			Cosmetics.playerKillEffects[id].effect( killer, victim )
		end
	end
end

function Cosmetics.AddAbility( keys )
	local unit = EntIndexToHScript( keys.unit )
	local patreon = Patreons:GetPlayerSettings( keys.PlayerID )

	if not unit:IsRealHero() then
		return
	elseif unit:GetMainControllingPlayer() ~= keys.PlayerID then
		return
	elseif unit:FindAbilityByName( keys.ability ) then
		return
	elseif not IsInToolsMode() and patreon.level < abilitiyPatreonLevel[keys.ability] then
		CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer( id ), "display_custom_error", { message = "#nopatreonerror" } )
		return
	end

	local count = 0

	for i = 0, unit:GetAbilityCount() - 1 do
		local ability = unit:GetAbilityByIndex( i )

		if ability and abilitiyPatreonLevel[ability:GetAbilityName()] then
			count = count + 1
		end
	end

	if count >= MAX_COSMETIC_ABILITIES then
		return
	end

	local ability = unit:AddAbility( keys.ability )

	ability:SetLevel( 1 )
	ability:SetHidden( false )

	CustomGameEventManager:Send_ServerToAllClients( "cosmetics_reload_abilities", nil )
end

function Cosmetics.RemvoeAbility( keys )
	local unit = EntIndexToHScript( keys.unit )

	if unit:GetMainControllingPlayer() ~= keys.PlayerID then
		return
	elseif not abilitiyPatreonLevel[keys.ability] then
		return
	elseif abilitiesCantBeRemoved[keys.ability] then
		return
	end

	unit:RemoveAbility( keys.ability )
	CustomGameEventManager:Send_ServerToAllClients( "cosmetics_reload_abilities", nil )
end

function Cosmetics.TryCastAbility( keys )
	local patreon = Patreons:GetPlayerSettings( keys.PlayerID )

	if patreon.level < abilitiyPatreonLevel[keys.ability] then
		CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer( id ), "display_custom_error", { message = "#nopatreonerror" } )
	end
end

function Cosmetics.SetHeroEffect( keys )
	local id = keys.PlayerID
	local index = tonumber( keys.index )
	local effect = Cosmetics.heroEffects[index]
	local patreon = Patreons:GetPlayerSettings( id )

	if not effect then
		return
	elseif not IsInToolsMode() and patreon.level < 1 then
		CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer( id ), "display_custom_error", { message = "#nopatreonerror" } )
		return
	end

	if keys.type == "hero" then
		local data = Cosmetics.playerHeroEffects[id]

		if data and data.index == index then
			return
		end

		if data then
			ParticleManager:DestroyParticle( data.particle, true )
			ParticleManager:ReleaseParticleIndex( data.particle )
		end

		local hero = PlayerResource:GetPlayer( id ):GetAssignedHero()
		local c = Cosmetics.playerHeroColors[id]

		Cosmetics.playerHeroEffects[id] = {
			particle = CreateEffect( hero, effect, c and c.color or nil ),
			index = index
		}
	elseif keys.type == "pet" then
		local pet = Cosmetics.playerPets[id].unit
		local pet_effect = Cosmetics.playerPetEffects[id]

		if pet_effect then
			ParticleManager:DestroyParticle( pet_effect.particle, true )
			ParticleManager:ReleaseParticleIndex( pet_effect.particle )
		end

		if pet then
			local c = Cosmetics.playerPetColors[id]

			Cosmetics.playerPetEffects[id] = {
				particle = CreateEffect( pet, effect, c and c.color or nil ),
				index = index
			}
		end
	elseif keys.type == "courier" then
		local team = PlayerResource:GetTeam( id )

		for i = 0, PlayerResource:GetNumCouriersForTeam( team ) - 1 do
			local courier = PlayerResource:GetNthCourierForTeam( i, team )

			if courier.cosmeticEffect then
				ParticleManager:DestroyParticle( courier.cosmeticEffect, true )
				ParticleManager:ReleaseParticleIndex( courier.cosmeticEffect )
			end

			local c = Cosmetics.teamCourierColors[team]
			courier.cosmeticEffect = CreateEffect( courier, effect, c and c.color or nil )
		end

		local t = CustomNetTables:GetTableValue( "cosmetics", "team_" .. tostring( team ) ) or {}
		t[keys.type .. "_effect"] = index
		CustomNetTables:SetTableValue( "cosmetics", "team_" .. tostring( team ), t )
	elseif keys.type == "wards" then
		if Cosmetics.playerWardEffects[id] then
			for _, ward in pairs( Cosmetics.playerWardEffects[id].wards ) do
				if ward.cosmeticEffect then
					ParticleManager:DestroyParticle( ward.cosmeticEffect, true )
					ParticleManager:ReleaseParticleIndex( ward.cosmeticEffect )
				end

				local c = Cosmetics.playerWardColors[id]
				ward.cosmeticEffect = CreateEffect( ward, effect, c and c.color or nil )
			end

			Cosmetics.playerWardEffects[id].index = index
			Cosmetics.playerWardEffects[id].effect = effect
		else
			Cosmetics.playerWardEffects[id] = {
				wards = {},
				index = index,
				effect = effect
			}
		end
	else
		return
	end

	if keys.type ~= "courier" then
		local t = CustomNetTables:GetTableValue( "cosmetics", tostring( id ) ) or {}
		t[keys.type .. "_effect"] = index
		t.saved = 0
		CustomNetTables:SetTableValue( "cosmetics", tostring( id ), t )
	end
end

function Cosmetics.RemoveHeroEffect( keys )
	local id = keys.PlayerID
	local data = Cosmetics.playerHeroEffects[id]

	if data then
		ParticleManager:DestroyParticle( data.particle, true )
		ParticleManager:ReleaseParticleIndex( data.particle )

		Cosmetics.playerHeroEffects[id] = nil

		local t = CustomNetTables:GetTableValue( "cosmetics", tostring( id ) ) or {}
		t.hero_effects = nil
		t.saved = 0
		CustomNetTables:SetTableValue( "cosmetics", tostring( id ), t )
	end

	if keys.type == "hero" then
		local data = Cosmetics.playerHeroEffects[id]

		if data then
			ParticleManager:DestroyParticle( data.particle, true )
			ParticleManager:ReleaseParticleIndex( data.particle )

			Cosmetics.playerHeroEffects[id] = nil
		end
	elseif keys.type == "pet" then
		local pet_effect = Cosmetics.playerPetEffects[id]

		if pet_effect then
			ParticleManager:DestroyParticle( pet_effect.particle, true )
			ParticleManager:ReleaseParticleIndex( pet_effect.particle )
		end

		Cosmetics.playerPetEffects[id] = nil
	elseif keys.type == "courier" then
		local team = PlayerResource:GetTeam( id )

		for i = 0, PlayerResource:GetNumCouriersForTeam( team ) - 1 do
			local courier = PlayerResource:GetNthCourierForTeam( i, team )

			if courier.cosmeticEffect then
				ParticleManager:DestroyParticle( courier.cosmeticEffect, true )
				ParticleManager:ReleaseParticleIndex( courier.cosmeticEffect )
			end
		end

		local t = CustomNetTables:GetTableValue( "cosmetics", "team_" .. tostring( team ) ) or {}
		t[keys.type .. "_effect"] = nil
		CustomNetTables:SetTableValue( "cosmetics", "team_" .. tostring( team ), t )
	elseif keys.type == "wards" then
		if Cosmetics.playerWardEffects[id] then
			for _, ward in pairs( Cosmetics.playerWardEffects[id].wards ) do
				if ward.cosmeticEffect then
					ParticleManager:DestroyParticle( ward.cosmeticEffect, true )
					ParticleManager:ReleaseParticleIndex( ward.cosmeticEffect )
				end
			end
		end

		Cosmetics.playerWardEffects[id].index = nil
		Cosmetics.playerWardEffects[id].effect = nil
	end

	if keys.type ~= "courier" then
		local t = CustomNetTables:GetTableValue( "cosmetics", tostring( id ) ) or {}
		t[keys.type .. "_effect"] = nil
		t.saved = 0
		CustomNetTables:SetTableValue( "cosmetics", tostring( id ), t )
	end
end

function Cosmetics.SetEffectColor( keys )
	local id = keys.PlayerID
	local index = tonumber( keys.index )
	local color = Cosmetics.prismaticColors[index]
	local patreon = Patreons:GetPlayerSettings( id )

	if not color then
		return
	elseif not IsInToolsMode() and patreon.level < 1 then
		CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer( id ), "display_custom_error", { message = "#nopatreonerror" } )
		return
	end

	if keys.type == "hero" then
		local data = Cosmetics.playerHeroEffects[id]

		if data then
			ParticleManager:SetParticleControl( data.particle, 15, color )
			ParticleManager:SetParticleControl( data.particle, 16, Vector( 1, 0, 0 ) )
		end

		Cosmetics.playerHeroColors[id] = {
			color = color,
			index = index
		}
	elseif keys.type == "pet" then
		local data = Cosmetics.playerPetEffects[id]

		if data then
			ParticleManager:SetParticleControl( data.particle, 15, color )
			ParticleManager:SetParticleControl( data.particle, 16, Vector( 1, 0, 0 ) )
		end

		Cosmetics.playerPetColors[id] = {
			color = color,
			index = index
		}
	elseif keys.type == "courier" then
		local team = PlayerResource:GetTeam( id )

		for i = 0, PlayerResource:GetNumCouriersForTeam( team ) - 1 do
			local courier = PlayerResource:GetNthCourierForTeam( i, team )

			if courier.cosmeticEffect then
				ParticleManager:SetParticleControl( courier.cosmeticEffect, 15, color )
				ParticleManager:SetParticleControl( courier.cosmeticEffect, 16, Vector( 1, 0, 0 ) )
			end
		end

		Cosmetics.teamCourierColors[team] = {
			index = index,
			color = color
		}

		local t = CustomNetTables:GetTableValue( "cosmetics", "team_" .. tostring( team ) ) or {}
		t.courier_color = index
		CustomNetTables:SetTableValue( "cosmetics", "team_" .. tostring( team ), t )
	elseif keys.type == "wards" then
		if Cosmetics.playerWardEffects[id] then
			for _, ward in pairs( Cosmetics.playerWardEffects[id].wards ) do
				if ward.cosmeticEffect then
					ParticleManager:SetParticleControl( ward.cosmeticEffect, 15, color )
					ParticleManager:SetParticleControl( ward.cosmeticEffect, 16, Vector( 1, 0, 0 ) )
				end
			end
		end

		Cosmetics.playerWardColors[id] = {
			index = index,
			color = color
		}
	else
		return
	end

	if keys.type ~= "courier" then
		local t = CustomNetTables:GetTableValue( "cosmetics", tostring( id ) ) or {}
		t[keys.type .. "_color"] = index
		t.saved = 0
		CustomNetTables:SetTableValue( "cosmetics", tostring( id ), t )
	end
end

function Cosmetics.RemoveEffectColor( keys )
	local id = keys.PlayerID

	if keys.type == "hero" then
		local data = Cosmetics.playerHeroEffects[id]

		if data then
			ParticleManager:SetParticleControl( data.particle, 15, Vector( 255, 255, 255 ) )
			ParticleManager:SetParticleControl( data.particle, 16, Vector( 0, 0, 0 ) )
		end

		Cosmetics.playerHeroColors[id] = nil
	elseif keys.type == "pet" then
		local data = Cosmetics.playerPetEffects[id]

		if data then
			ParticleManager:SetParticleControl( data.particle, 15, Vector( 255, 255, 255 ) )
			ParticleManager:SetParticleControl( data.particle, 16, Vector( 0, 0, 0 ) )
		end

		Cosmetics.playerPetColors[id] = nil
	elseif keys.type == "courier" then
		local team = PlayerResource:GetTeam( id )

		for i = 0, PlayerResource:GetNumCouriersForTeam( team ) - 1 do
			local courier = PlayerResource:GetNthCourierForTeam( i, team )

			if courier.cosmeticEffect then
				ParticleManager:SetParticleControl( courier.cosmeticEffect, 15, Vector( 255, 255, 255 ) )
				ParticleManager:SetParticleControl( courier.cosmeticEffect, 16, Vector( 0, 0, 0 ) )
			end
		end

		Cosmetics.teamCourierColors[team] = nil

		local t = CustomNetTables:GetTableValue( "cosmetics", "team_" .. tostring( team ) ) or {}
		t.courier_color = nil
		CustomNetTables:SetTableValue( "cosmetics", "team_" .. tostring( team ), t )
	elseif keys.type == "wards" then
		if Cosmetics.playerWardEffects[id] then
			for _, ward in pairs( Cosmetics.playerWardEffects[id].wards ) do
				if ward.cosmeticEffect then
					ParticleManager:SetParticleControl( ward.cosmeticEffect, 15, Vector( 255, 255, 255 ) )
					ParticleManager:SetParticleControl( ward.cosmeticEffect, 16, Vector( 0, 0, 0 ) )
				end
			end
		end

		Cosmetics.playerWardColors[id] = nil
	else
		return
	end

	if keys.type ~= "courier" then
		local t = CustomNetTables:GetTableValue( "cosmetics", tostring( id ) ) or {}
		t[keys.type .. "_color"] = nil
		t.saved = 0
		CustomNetTables:SetTableValue( "cosmetics", tostring( id ), t )
	end
end

function Cosmetics.SetKillEffect( keys )
	local id = keys.PlayerID
	local effect = Cosmetics["kill_effect_" .. keys.effect_name]
	local patreon = Patreons:GetPlayerSettings( id )

	if not effect then
		return
	elseif effect == Cosmetics.playerKillEffects[id] then
		return
	elseif not IsInToolsMode() and patreon.level < 1 then
		CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer( id ), "display_custom_error", { message = "#nopatreonerror" } )
		return
	end

	Cosmetics.playerKillEffects[id] = {
		effect = effect,
		name = keys.effect_name
	}

	local t = CustomNetTables:GetTableValue( "cosmetics", tostring( id ) ) or {}
	t.kill_effects = keys.effect_name
	t.saved = 0
	CustomNetTables:SetTableValue( "cosmetics", tostring( id ), t )
end

function Cosmetics.RemoveKillEffect( keys )
	local id = keys.PlayerID

	if not Cosmetics.playerKillEffects[id] then
		return
	end

	Cosmetics.playerKillEffects[id] = nil

	local t = CustomNetTables:GetTableValue( "cosmetics", tostring( id ) ) or {}
	t.kill_effects = nil
	t.saved = 0
	CustomNetTables:SetTableValue( "cosmetics", tostring( id ), t )
end

function Cosmetics.SelectPet( keys )
	local id = keys.PlayerID
	local old_pet = Cosmetics.playerPets[id]
	local old_pet_pos
	local old_pet_dir
	local hero = PlayerResource:GetPlayer( id ):GetAssignedHero()
	local pet_data = Cosmetics.petsData.couriers[keys.index]
	local patreon = Patreons:GetPlayerSettings( id )

	if not pet_data then
		return
	elseif not IsInToolsMode() and patreon.level < 2 then
		CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer( id ), "display_custom_error", { message = "#nopatreonerror" } )
		return
	end

	if old_pet then
		old_pet_pos = old_pet.unit:GetAbsOrigin()
		old_pet_dir = old_pet.unit:GetForwardVector()

		old_pet.unit:Destroy()
	end

	local pet = CreateUnitByName( "npc_cosmetic_pet", old_pet_pos or hero:GetAbsOrigin() + RandomVector( RandomInt( 75, 150 ) ), true, hero, hero, hero:GetTeam() )

	pet:SetForwardVector( old_pet_dir or hero:GetAbsOrigin() )
	pet:AddNewModifier( pet, nil, "modifier_cosmetic_pet", {} )
	UnhidePet( pet )

	pet:SetModel( pet_data.model )
	pet:SetOriginalModel( pet_data.model )

	if pet_data.skin then
		pet:SetMaterialGroup( tostring( pet_data.skin ) )
	end

	local attach_types = {
		customorigin = PATTACH_CUSTOMORIGIN,
		point_follow = PATTACH_POINT_FOLLOW,
		absorigin_follow = PATTACH_ABSORIGIN_FOLLOW
	}

	for _, p in pairs( pet_data.particles ) do
		if type( p ) == "number" then
			local particle_data =  Cosmetics.petsData.particles[p]
			local mat = attach_types[particle_data.attach_type] or PATTACH_POINT_FOLLOW

			local particle = ParticleManager:CreateParticle( particle_data.particle, mat, pet )

			for _, control in pairs( particle_data.control_points or {} ) do
				local pat = attach_types[control.attach_type] or PATTACH_POINT_FOLLOW

				ParticleManager:SetParticleControlEnt( particle, control.control_point_index, pet, pat, control.attachment, pet:GetAbsOrigin(), true )
			end
		else
			ParticleManager:CreateParticle( p, PATTACH_POINT_FOLLOW, pet )
		end
	end

	local e = Cosmetics.playerPetEffects[id]
	local c = Cosmetics.playerPetColors[id]
	
	if e then
		e.particle = CreateEffect( pet, Cosmetics.heroEffects[e.index], c and c.color or nil )
	end

	Cosmetics.playerPets[id] = {
		unit = pet,
		index =  keys.index
	}
	local t = CustomNetTables:GetTableValue( "cosmetics", tostring( id ) ) or {}
	t.pet = keys.index
	t.saved = 0
	CustomNetTables:SetTableValue( "cosmetics", tostring( id ), t )
end

function Cosmetics.DeletePet( keys )
	local id = keys.PlayerID

	if not Cosmetics.playerPets[id] then
		return
	end

	HidePet( Cosmetics.playerPets[id].unit, 0 )

	Cosmetics.playerPets[id].unit:Destroy()
	Cosmetics.playerPets[id] = nil

	local t = CustomNetTables:GetTableValue( "cosmetics", tostring( id ) ) or {}
	t.pet = nil
	t.saved = 0
	CustomNetTables:SetTableValue( "cosmetics", tostring( id ), t )
end

function Cosmetics.Save( keys )
	local id = keys.PlayerID
	local player = PlayerResource:GetPlayer( id )
	local hero = player:GetAssignedHero()
	local patreon = Patreons:GetPlayerSettings( id )
	local t = CustomNetTables:GetTableValue( "cosmetics", tostring( id ) ) or {}

	if not IsInToolsMode() and patreon.level < 1 then
		return
	elseif t.saved ~= 0 then
		return
	end

	local a = Cosmetics.playerPets[id]
	local b = Cosmetics.playerHeroEffects[id]
	local c = Cosmetics.playerHeroColors[id]
	local d = Cosmetics.playerPetEffects[id]
	local e = Cosmetics.playerPetColors[id]
	local f = Cosmetics.playerWardEffects[id]
	local g = Cosmetics.playerWardColors[id]
	local h = Cosmetics.playerKillEffects[id]

	local data = {
		steam_id = PlayerResource:GetSteamID( id ),
		pet = a and a.index or -1,

		hero_effect = b and b.index or -1,
		hero_color = c and c.index or -1,

		pet_effect = d and d.index or -1,
		pet_color = e and e.index or -1,

		wards_effect = f and f.index or -1,
		wards_color = g and g.index or -1,

		kill_effect = h and h.index or -1,
		abilities = {},
	}

	for i = 0, hero:GetAbilityCount() - 1 do
		local ability = hero:GetAbilityByIndex( i )

		if ability and abilitiyPatreonLevel[ability:GetAbilityName()] then
			table.insert( data.abilities, ability:GetAbilityName() )
		end
	end

	t.saved = 1
	CustomNetTables:SetTableValue( "cosmetics", tostring( id ), t )

	--[[
	WebApi:Send(
		"path", -- ???
		data,
		function()
			local t = CustomNetTables:GetTableValue( "cosmetics", tostring( id ) ) or {}
			t.saved = 2
			CustomNetTables:SetTableValue( "cosmetics", tostring( id ), t )
		end,
		function() end
	)
	]]
end

function Cosmetics.kill_effect_firework( killer, victim )
	local particle = ParticleManager:CreateParticle(
		"particles/econ/items/gyrocopter/hero_gyrocopter_gyrotechnics/gyro_calldown_explosion_fireworks.vpcf",
		PATTACH_WORLDORIGIN,
		nil
	)

	ParticleManager:SetParticleControl( particle, 3, victim:GetAbsOrigin() )
	EmitSoundOnLocationWithCaster( victim:GetAbsOrigin(), "FrostivusConsumable.Fireworks.Explode", killer )
end

function Cosmetics.kill_effect_tombstone( killer, victim )
	local tombs = {
		"models/heroes/phantom_assassin/arcana_tombstone.vmdl",
		"models/heroes/phantom_assassin/arcana_tombstone2.vmdl",
		"models/heroes/phantom_assassin/arcana_tombstone3.vmdl"
	}

	local pos = victim:GetAbsOrigin()
	pos.z = GetGroundHeight( victim:GetAbsOrigin(), victim )

	local tomb = SpawnEntityFromTableSynchronous( "prop_dynamic", { origin = pos, model = tombs[RandomInt( 1, #tombs )] } )
	tomb:SetForwardVector( Vector( 0, RandomInt( 250, 290 ), 0 ) )
end

Cosmetics.heroEffects = {
	[1] = {
		attach_entity = "parent",
		resource = "particles/econ/courier/courier_trail_ember",
		attach_type = "renderorigin_follow",
		default_color = {
			b = 33,
			g = 52,
			r = 54
		},
		system = "particles/econ/courier/courier_trail_ember/courier_trail_ember.vpcf"
	},
	[2] = {
		attach_entity = "parent",
		resource = "particles/econ/courier/courier_trail_hw_2013",
		attach_type = "renderorigin_follow",
		default_color = {
			b = 57,
			g = 142,
			r = 133
		},
		system = "particles/econ/courier/courier_trail_hw_2013/courier_trail_hw_2013.vpcf"
	},
	[3] = {
		attach_entity = "parent",
		resource = "particles/econ/courier/courier_trail_international_2013",
		attach_type = "renderorigin_follow",
		default_color = {
			b = 21,
			g = 165,
			r = 21
		},
		system = "particles/econ/courier/courier_trail_international_2013/courier_international_2013.vpcf"
	},
	[4] = {
		attach_entity = "parent",
		resource = "particles/econ/courier/courier_trail_fireworks",
		attach_type = "renderorigin_follow",
		default_color = {
			b = 35,
			g = 1,
			r = 202
		},
		system = "particles/econ/courier/courier_trail_fireworks/courier_trail_fireworks.vpcf"
	},
	[5] = {
		attach_entity = "parent",
		resource = "particles/econ/courier/courier_trail_cursed",
		attach_type = "renderorigin_follow",
		default_color = {
			b = 6,
			g = 6,
			r = 6
		},
		system = "particles/econ/courier/courier_trail_cursed/courier_cursed_ambient.vpcf"
	},
	[6] = {
		attach_entity = "parent",
		attach_type = "absorigin_follow",
		resource = "particles/econ/courier/courier_trail_02",
		system = "particles/econ/courier/courier_trail_02/courier_trail_02.vpcf"
	},
	[7] = {
		attach_entity = "parent",
		attach_type = "renderorigin_follow",
		resource = "particles/econ/courier/courier_trail_spirit",
		system = "particles/econ/courier/courier_trail_spirit/courier_trail_spirit.vpcf"
	},
	[8] = {
		attach_entity = "parent",
		resource = "particles/econ/courier/courier_trail_ruby",
		attach_type = "absorigin_follow",
		default_color = {
			b = 161,
			g = 31,
			r = 209
		},
		system = "particles/econ/courier/courier_trail_ruby/courier_trail_ruby.vpcf"
	},
	[9] = {
		attach_entity = "parent",
		resource = "particles/econ/courier/courier_trail_04",
		attach_type = "absorigin_follow",
		default_color = {
			b = 0,
			g = 66,
			r = 255
		},
		system = "particles/econ/courier/courier_trail_04/courier_trail_04.vpcf"
	},
	[10] = {
		attach_entity = "parent",
		resource = "particles/econ/courier/courier_trail_05",
		attach_type = "absorigin_follow",
		default_color = {
			b = 188,
			g = 238,
			r = 255
		},
		system = "particles/econ/courier/courier_trail_05/courier_trail_05.vpcf"
	},
	[11] = {
		attach_entity = "parent",
		resource = "particles/econ/courier/courier_trail_lava",
		attach_type = "absorigin_follow",
		default_color = {
			b = 51,
			g = 61,
			r = 208
		},
		system = "particles/econ/courier/courier_trail_lava/courier_trail_lava.vpcf"
	},
	[12] = {
		attach_entity = "parent",
		resource = "particles/econ/courier/courier_trail_int_2012",
		attach_type = "customorigin",
		default_color = {
			b = 254,
			g = 125,
			r = 80
		},
		control_points = {
			[1] = {
				attachment = "attach_eye_l",
				attach_type = "point_follow",
				control_point_index = 1
			},
			[0] = {
				attachment = "attach_eye_r",
				attach_type = "point_follow",
				control_point_index = 0
			}
		},
		system = "particles/econ/courier/courier_trail_int_2012/courier_trail_international_2012.vpcf"
	},
	[13] = {
		attach_entity = "parent",
		resource = "particles/econ/courier/courier_trail_winter_2012",
		attach_type = "absorigin_follow",
		default_color = {
			b = 208,
			g = 202,
			r = 148
		},
		system = "particles/econ/courier/courier_trail_winter_2012/courier_trail_winter_2012.vpcf"
	},
	[14] = {
		attach_entity = "parent",
		resource = "particles/econ/courier/courier_trail_fungal",
		attach_type = "renderorigin_follow",
		default_color = {
			b = 91,
			g = 110,
			r = 98
		},
		system = "particles/econ/courier/courier_trail_fungal/courier_trail_fungal.vpcf"
	},
	[15] = {
		attach_entity = "parent",
		resource = "particles/econ/courier/courier_trail_blossoms",
		attach_type = "renderorigin_follow",
		default_color = {
			b = 146,
			g = 96,
			r = 215
		},
		system = "particles/econ/courier/courier_trail_blossoms/courier_trail_blossoms.vpcf"
	},
	[16] = {
		attach_entity = "parent",
		resource = "particles/econ/courier/courier_trail_03",
		attach_type = "absorigin_follow",
		default_color = {
			b = 0,
			g = 66,
			r = 255
		},
		system = "particles/econ/courier/courier_trail_03/courier_trail_03.vpcf"
	},
	[17] = {
		attach_entity = "parent",
		resource = "particles/econ/courier/courier_trail_international_2014",
		attach_type = "renderorigin_follow",
		default_color = {
			b = 195,
			g = 72,
			r = 127
		},
		system = "particles/econ/courier/courier_trail_international_2014/courier_international_2014.vpcf"
	},
	[18] = {
		attach_entity = "parent",
		attach_type = "renderorigin_follow",
		resource = "particles/econ/courier/courier_trail_earth",
		system = "particles/econ/courier/courier_trail_earth/courier_trail_earth.vpcf"
	},
	[19] = {
		attach_entity = "parent",
		attach_type = "absorigin_follow",
		resource = "particles/econ/courier/courier_trail_01",
		system = "particles/econ/courier/courier_trail_01/courier_trail_01.vpcf"
	},
	[20] = {
		attach_entity = "parent",
		resource = "particles/econ/courier/courier_trail_hw_2012",
		attach_type = "renderorigin_follow",
		default_color = {
			b = 89,
			g = 255,
			r = 161
		},
		system = "particles/econ/courier/courier_trail_hw_2012/courier_trail_hw_2012.vpcf"
	},
	[21] = {
		attach_entity = "parent",
		resource = "particles/econ/courier/courier_trail_divine",
		attach_type = "renderorigin_follow",
		default_color = {
			b = 255,
			g = 242,
			r = 220
		},
		system = "particles/econ/courier/courier_trail_divine/courier_divine_ambient.vpcf"
	},
	[22] = {
		attach_entity = "parent",
		attach_type = "renderorigin_follow",
		resource = "particles/econ/courier/courier_trail_orbit",
		system = "particles/econ/courier/courier_trail_orbit/courier_trail_orbit.vpcf"
	}
}

Cosmetics.prismaticColors = {
	[1] = Vector( 25, 25, 112 ),
	[2] = Vector( 188, 221, 179 ),
	[3] = Vector( 192, 192, 192 ),
	[4] = Vector( 207, 171, 49 ),
	[5] = Vector( 127, 72, 195 ),
	[6] = Vector( 220, 242, 255 ),
	[7] = Vector( 255, 238, 188 ),
	[8] = Vector( 255, 193, 220 ),
	[9] = Vector( 130, 50, 207 ),
	[10] = Vector( 50, 171, 220 ),
	[11] = Vector( 255, 120, 50 ),
	[12] = Vector( 90, 195, 85 ),
	[13] = Vector( 255, 60, 40 ),
	[14] = Vector( 202, 1, 35 ),
	[15] = Vector( 21, 165, 21 ),
	[16] = Vector( 213, 227, 245 ),
	[17] = Vector( 128, 128, 0 ),
	[18] = Vector( 161, 255, 89 ),
	[19] = Vector( 240, 230, 140 ),
	[20] = Vector( 130, 50, 237 ),
	[21] = Vector( 123, 104, 238 ),
	[22] = Vector( 61, 104, 196 ),
	[23] = Vector( 81, 179, 80 ),
	[24] = Vector( 189, 183, 107 ),
	[25] = Vector( 6, 6, 6 ),
	[26] = Vector( 255, 198, 4 ),
	[27] = Vector( 255, 202, 21 ),
	[28] = Vector( 55, 134, 77 ),
	[29] = Vector( 98, 110, 91 ),
	[30] = Vector( 208, 119, 51 ),
	[31] = Vector( 26, 61, 133 ),
	[32] = Vector( 0, 151, 206 ),
	[33] = Vector( 148, 202, 208 ),
	[34] = Vector( 255, 66, 0 ),
	[35] = Vector( 215, 96, 146 ),
	[36] = Vector( 208, 61, 51 ),
	[37] = Vector( 80, 125, 254 ),
	[38] = Vector( 74, 183, 141 ),
	[39] = Vector( 183, 207, 51 ),
	[40] = Vector( 255, 175, 0 ),
	[41] = Vector( 247, 157, 0 ),
	[42] = Vector( 209, 31, 161 )
}

Cosmetics.petsData = {
	particles = {
		[1] = {
			attach_entity = "self",
			control_points = {
				[1] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 2
				},
				[0] = {
					attachment = "attach_head",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[3] = {
					attachment = "attach_hitlock",
					attach_type = "point_follow",
					control_point_index = 4
				},
				[2] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 3
				}
			},
			particle = "particles/econ/courier/courier_beetlejaw_gold/courier_beetlejaw_gold_ambient.vpcf",
			attach_type = "customorigin"
		},
		[2] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_shell_high",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_g1_octopus/courier_g1_octopus/courier_inky_ambient.vpcf",
			attach_type = "customorigin"
		},
		[3] = {
			particle = "particles/econ/courier/courier_roshan_ti8/courier_roshan_ti8_flying.vpcf"
		},
		[4] = {
			particle = "particles/econ/courier/courier_roshan_ti8/courier_roshan_ti8.vpcf"
		},
		[5] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_hyeonmu_ambient/courier_hyeonmu_eye_glow_blue.vpcf",
			attach_type = "customorigin"
		},
		[6] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_hyeonmu_ambient/courier_hyeonmu_eye_glow_blue.vpcf",
			attach_type = "customorigin"
		},
		[7] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_hyeonmu_ambient/courier_hyeonmu_eye_glow_blue.vpcf",
			attach_type = "customorigin"
		},
		[8] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_hyeonmu_ambient/courier_hyeonmu_eye_glow_blue.vpcf",
			attach_type = "customorigin"
		},
		[9] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_hyeonmu_ambient/courier_hyeonmu_ambient_green.vpcf",
			attach_type = "absorigin_follow"
		},
		[10] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_hyeonmu_ambient/courier_hyeonmu_eye_glow_blue.vpcf",
			attach_type = "customorigin"
		},
		[11] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_hyeonmu_ambient/courier_hyeonmu_eye_glow_gold.vpcf",
			attach_type = "customorigin"
		},
		[12] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_hyeonmu_ambient/courier_hyeonmu_ambient_blue.vpcf",
			attach_type = "absorigin_follow"
		},
		[13] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_hyeonmu_ambient/courier_hyeonmu_eye_glow_gold.vpcf",
			attach_type = "customorigin"
		},
		[14] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_hyeonmu_ambient/courier_hyeonmu_ambient_blue.vpcf",
			attach_type = "absorigin_follow"
		},
		[15] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_hyeonmu_ambient/courier_hyeonmu_eye_glow_gold.vpcf",
			attach_type = "customorigin"
		},
		[16] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_hyeonmu_ambient/courier_hyeonmu_ambient_blue.vpcf",
			attach_type = "absorigin_follow"
		},
		[17] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_hyeonmu_ambient/courier_hyeonmu_ambient_blue_plus.vpcf",
			attach_type = "absorigin_follow"
		},
		[18] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_hyeonmu_ambient/courier_hyeonmu_eye_glow_gold.vpcf",
			attach_type = "customorigin"
		},
		[19] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_hyeonmu_ambient/courier_hyeonmu_eye_glow_green.vpcf",
			attach_type = "customorigin"
		},
		[20] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_hyeonmu_ambient/courier_hyeonmu_ambient_red.vpcf",
			attach_type = "absorigin_follow"
		},
		[21] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_hyeonmu_ambient/courier_hyeonmu_eye_glow_green.vpcf",
			attach_type = "customorigin"
		},
		[22] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_hyeonmu_ambient/courier_hyeonmu_ambient_red.vpcf",
			attach_type = "absorigin_follow"
		},
		[23] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_hyeonmu_ambient/courier_hyeonmu_ambient_red.vpcf",
			attach_type = "absorigin_follow"
		},
		[24] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_hyeonmu_ambient/courier_hyeonmu_eye_glow_green.vpcf",
			attach_type = "customorigin"
		},
		[25] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_hyeonmu_ambient/courier_hyeonmu_eye_glow_green.vpcf",
			attach_type = "customorigin"
		},
		[26] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_hyeonmu_ambient/courier_hyeonmu_ambient_red_plus.vpcf",
			attach_type = "absorigin_follow"
		},
		[27] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_hyeonmu_ambient/courier_hyeonmu_ambient_gold.vpcf",
			attach_type = "absorigin_follow"
		},
		[28] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_hyeonmu_ambient/courier_hyeonmu_eye_glow_blue.vpcf",
			attach_type = "customorigin"
		},
		[29] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 1
				}
			},
			particle = "particles/econ/courier/courier_flopjaw_gold/courier_flopjaw_ambient_gold.vpcf",
			attach_type = "absorigin_follow"
		},
		[30] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_nostril_2",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_nostril_1",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_otter_dragon/courier_otter_dragon_ambient.vpcf",
			attach_type = "customorigin"
		},
		[31] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_angel_head",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_dc/dccourier_angel_flame.vpcf",
			attach_type = "rootbone_follow"
		},
		[32] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_devil_head",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_dc/dccourier_devil_flame.vpcf",
			attach_type = "rootbone_follow"
		},
		[33] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_shuriken",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_huntling/courier_huntling_ambient_flying.vpcf",
			attach_type = "customorigin"
		},
		[34] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attach_type = "absorigin_follow",
					control_point_index = 0
				},
				[2] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 2
				}
			},
			particle = "particles/econ/courier/courier_jade_horn/courier_jade_horn_ambient.vpcf",
			attach_type = "customorigin"
		},
		[35] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attach_type = "absorigin_follow",
					control_point_index = 0
				},
				[2] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 2
				}
			},
			particle = "particles/econ/courier/courier_jade_horn/courier_jade_horn_ambient_flying.vpcf",
			attach_type = "customorigin"
		},
		[36] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_smoke_2",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_smoke_1",
					attach_type = "point_follow",
					control_point_index = 0
				},
				[2] = {
					attachment = "attach_smoke_3",
					attach_type = "point_follow",
					control_point_index = 2
				}
			},
			particle = "particles/econ/courier/courier_wmachine/courier_warmachine_ambient.vpcf",
			attach_type = "customorigin"
		},
		[37] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_wing_l",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attach_type = "renderorigin_follow",
					control_point_index = 0
				},
				[3] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 3
				},
				[2] = {
					attachment = "attach_wing_r",
					attach_type = "point_follow",
					control_point_index = 2
				},
				[5] = {
					attachment = "attach_lantern",
					attach_type = "point_follow",
					control_point_index = 5
				},
				[4] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 4
				}
			},
			particle = "particles/econ/courier/courier_wyrmeleon/courier_wrymeleon_ambient.vpcf",
			attach_type = "renderorigin_follow"
		},
		[38] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_potion",
					attach_type = "point_follow",
					control_point_index = 2
				},
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 1
				}
			},
			particle = "particles/econ/courier/courier_shibe/courier_shibe_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[39] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_potion",
					attach_type = "point_follow",
					control_point_index = 2
				},
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[2] = {
					attachment = "attach_halo",
					attach_type = "point_follow",
					control_point_index = 3
				}
			},
			particle = "particles/econ/courier/courier_shibe/courier_shibe_ambient_flying.vpcf",
			attach_type = "absorigin_follow"
		},
		[40] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_light",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_golden_skipper/golden_skipper_head_light.vpcf",
			attach_type = "customorigin"
		},
		[41] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_mouth",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_golden_skipper/golden_skipper_bubbles.vpcf",
			attach_type = "customorigin"
		},
		[42] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_trapjaw/courier_trapjaw_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[43] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_mouth_l",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_mouth_r",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_trapjaw/courier_trapjaw_mouth.vpcf",
			attach_type = "customorigin"
		},
		[44] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_weapon",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attach_type = "absorigin_follow",
					control_point_index = 0
				},
				[2] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 2
				}
			},
			particle = "particles/econ/courier/courier_minipudge/courier_minipudge_lvl2_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[45] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_weapon",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attach_type = "absorigin_follow",
					control_point_index = 0
				},
				[2] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 2
				}
			},
			particle = "particles/econ/courier/courier_minipudge/courier_minipudge_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[46] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attach_type = "renderorigin_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_smeevil/courier_smeevil_red_ambient.vpcf",
			attach_type = "renderorigin_follow"
		},
		[47] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attach_type = "renderorigin_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_smeevil/courier_smeevil_yellow_ambient.vpcf",
			attach_type = "renderorigin_follow"
		},
		[48] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attach_type = "renderorigin_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_smeevil/courier_smeevil_purple_ambient.vpcf",
			attach_type = "renderorigin_follow"
		},
		[49] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attach_type = "renderorigin_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_smeevil/courier_smeevil_mammoth_ambient.vpcf",
			attach_type = "renderorigin_follow"
		},
		[50] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attach_type = "renderorigin_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_smeevil/courier_smeevil_bird_ambient.vpcf",
			attach_type = "renderorigin_follow"
		},
		[51] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attach_type = "renderorigin_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_smeevil/courier_smeevil_crab_ambient.vpcf",
			attach_type = "renderorigin_follow"
		},
		[52] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attach_type = "renderorigin_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_smeevil/courier_smeevil_crab_ambient.vpcf",
			attach_type = "renderorigin_follow"
		},
		[53] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attach_type = "renderorigin_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_smeevil/courier_smeevil_ambient.vpcf",
			attach_type = "renderorigin_follow"
		},
		[54] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_exhaust",
					attach_type = "point_follow",
					control_point_index = 2
				},
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[3] = {
					attachment = "attach_wheel_R",
					attach_type = "point_follow",
					control_point_index = 4
				},
				[2] = {
					attachment = "attach_wheel_L",
					attach_type = "point_follow",
					control_point_index = 3
				}
			},
			particle = "particles/econ/courier/courier_mechjaw/courier_mechjaw_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[55] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_devourling/courier_devourling_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[56] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				},
				[3] = {
					attachment = "attach_wing_l",
					attach_type = "point_follow",
					control_point_index = 3
				},
				[2] = {
					attachment = "attach_beard",
					attach_type = "point_follow",
					control_point_index = 2
				},
				[4] = {
					attachment = "attach_wing_r",
					attach_type = "point_follow",
					control_point_index = 4
				}
			},
			particle = "particles/econ/courier/courier_sappling/courier_sappling_ambient_fly_lvl1.vpcf",
			attach_type = "absorigin_follow"
		},
		[57] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				},
				[2] = {
					attachment = "attach_beard",
					attach_type = "point_follow",
					control_point_index = 2
				}
			},
			particle = "particles/econ/courier/courier_sappling/courier_sappling_ambient_lvl1.vpcf",
			attach_type = "absorigin_follow"
		},
		[58] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				},
				[3] = {
					attachment = "attach_wing_l",
					attach_type = "point_follow",
					control_point_index = 3
				},
				[2] = {
					attachment = "attach_beard",
					attach_type = "point_follow",
					control_point_index = 2
				},
				[4] = {
					attachment = "attach_wing_r",
					attach_type = "point_follow",
					control_point_index = 4
				}
			},
			particle = "particles/econ/courier/courier_sappling/courier_sappling_ambient_fly_lvl2.vpcf",
			attach_type = "absorigin_follow"
		},
		[59] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				},
				[2] = {
					attachment = "attach_beard",
					attach_type = "point_follow",
					control_point_index = 2
				}
			},
			particle = "particles/econ/courier/courier_sappling/courier_sappling_ambient_lvl2.vpcf",
			attach_type = "absorigin_follow"
		},
		[60] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				},
				[3] = {
					attachment = "attach_wing_l",
					attach_type = "point_follow",
					control_point_index = 3
				},
				[2] = {
					attachment = "attach_beard",
					attach_type = "point_follow",
					control_point_index = 2
				},
				[4] = {
					attachment = "attach_wing_r",
					attach_type = "point_follow",
					control_point_index = 4
				}
			},
			particle = "particles/econ/courier/courier_sappling/courier_sappling_ambient_fly_lvl3.vpcf",
			attach_type = "absorigin_follow"
		},
		[61] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				},
				[2] = {
					attachment = "attach_beard",
					attach_type = "point_follow",
					control_point_index = 2
				}
			},
			particle = "particles/econ/courier/courier_sappling/courier_sappling_ambient_lvl3.vpcf",
			attach_type = "absorigin_follow"
		},
		[62] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_rotor",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_mok/mok_prop.vpcf",
			attach_type = "customorigin"
		},
		[63] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 2
				},
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[3] = {
					attachment = "attach_back",
					attach_type = "point_follow",
					control_point_index = 4
				},
				[2] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 3
				}
			},
			particle = "particles/econ/courier/courier_beetlejaw/courier_beetlejaw_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[64] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_dolfrat_and_roshinante/courier_dolfrat_and_roshinante_a.vpcf",
			attach_type = "absorigin_follow"
		},
		[65] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attach_type = "absorigin_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_zombie_hopper/courier_zombie_hopper_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[66] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_donkey_unicorn/courier_donkey_unicorn_ambient.vpcf",
			attach_type = "customorigin"
		},
		[67] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_lantern_glow",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_xianhe_stork_lantern/courier_xianhe_stork_lantern.vpcf",
			attach_type = "customorigin"
		},
		[68] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_lantern_glow",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_xianhe_stork_lantern/courier_xianhe_stork_lantern.vpcf",
			attach_type = "customorigin"
		},
		[69] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 1
				}
			},
			particle = "particles/econ/courier/courier_devourling_gold/courier_devourling_gold_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[70] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_head",
					attach_type = "point_follow",
					control_point_index = 3
				},
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 1
				}
			},
			particle = "particles/econ/courier/courier_krobeling_gold/courier_krobeling_gold_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[71] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 1
				}
			},
			particle = "particles/econ/courier/courier_flopjaw/courier_flopjaw_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[72] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 1
				}
			},
			particle = "particles/econ/courier/courier_huntling_gold/courier_huntling_gold_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[73] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_shuriken",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_huntling_gold/courier_huntling_gold_ambient_flying.vpcf",
			attach_type = "customorigin"
		},
		[74] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_box",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_pot",
					attach_type = "point_follow",
					control_point_index = 0
				},
				[2] = {
					attach_type = "absorigin_follow",
					control_point_index = 2
				}
			},
			particle = "particles/econ/courier/courier_frull_ambient/courier_frull_ambient_flying.vpcf",
			attach_type = "absorigin_follow"
		},
		[75] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_box",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_pot",
					attach_type = "point_follow",
					control_point_index = 0
				},
				[2] = {
					attach_type = "absorigin_follow",
					control_point_index = 2
				}
			},
			particle = "particles/econ/courier/courier_frull_ambient/courier_frull_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[76] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_drill",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_exhaust",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_boris_baumhauer/courier_boris_baumhauer_ambient.vpcf",
			attach_type = "customorigin"
		},
		[77] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_bottle",
					attach_type = "point_follow",
					control_point_index = 2
				},
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[3] = {
					attachment = "attach_ear_base_l",
					attach_type = "point_follow",
					control_point_index = 4
				},
				[2] = {
					attachment = "attach_tail",
					attach_type = "point_follow",
					control_point_index = 3
				},
				[5] = {
					attachment = "attach_scroll",
					attach_type = "point_follow",
					control_point_index = 6
				},
				[4] = {
					attachment = "attach_ear_base_r",
					attach_type = "point_follow",
					control_point_index = 5
				}
			},
			particle = "particles/econ/courier/courier_wabbit/courier_wabbit_ambient_lvl1.vpcf",
			attach_type = "absorigin_follow"
		},
		[78] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_bottle",
					attach_type = "point_follow",
					control_point_index = 2
				},
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[3] = {
					attachment = "attach_ear_base_l",
					attach_type = "point_follow",
					control_point_index = 4
				},
				[2] = {
					attachment = "attach_tail",
					attach_type = "point_follow",
					control_point_index = 3
				},
				[5] = {
					attachment = "attach_scroll",
					attach_type = "point_follow",
					control_point_index = 6
				},
				[4] = {
					attachment = "attach_ear_base_r",
					attach_type = "point_follow",
					control_point_index = 5
				}
			},
			particle = "particles/econ/courier/courier_wabbit/courier_wabbit_ambient_lvl2.vpcf",
			attach_type = "absorigin_follow"
		},
		[79] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_bottle",
					attach_type = "point_follow",
					control_point_index = 2
				},
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[3] = {
					attachment = "attach_ear_base_l",
					attach_type = "point_follow",
					control_point_index = 4
				},
				[2] = {
					attachment = "attach_tail",
					attach_type = "point_follow",
					control_point_index = 3
				},
				[5] = {
					attachment = "attach_scroll",
					attach_type = "point_follow",
					control_point_index = 6
				},
				[4] = {
					attachment = "attach_ear_base_r",
					attach_type = "point_follow",
					control_point_index = 5
				},
				[6] = {
					attachment = "attach_pendant",
					attach_type = "point_follow",
					control_point_index = 7
				}
			},
			particle = "particles/econ/courier/courier_wabbit/courier_wabbit_ambient_lvl3.vpcf",
			attach_type = "absorigin_follow"
		},
		[80] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_bottle",
					attach_type = "point_follow",
					control_point_index = 2
				},
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[3] = {
					attachment = "attach_ear_base_l",
					attach_type = "point_follow",
					control_point_index = 4
				},
				[2] = {
					attachment = "attach_tail",
					attach_type = "point_follow",
					control_point_index = 3
				},
				[5] = {
					attachment = "attach_scroll",
					attach_type = "point_follow",
					control_point_index = 6
				},
				[4] = {
					attachment = "attach_ear_base_r",
					attach_type = "point_follow",
					control_point_index = 5
				}
			},
			particle = "particles/econ/courier/courier_wabbit/courier_wabbit_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[81] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_candle_l",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_candle_r",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_bookwyrm/courier_bookwyrm.vpcf",
			attach_type = "customorigin"
		},
		[82] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 2
				},
				[2] = {
					attachment = "attach_tail",
					attach_type = "point_follow",
					control_point_index = 3
				}
			},
			particle = "particles/econ/courier/courier_redhoof_ambient/redhoof_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[83] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_jet",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_nilbog/courier_nilbog.vpcf",
			attach_type = "customorigin"
		},
		[84] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_drodo/courier_drodo_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[85] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_jet",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_tinkbot/courier_tinkbot_flying_ambient.vpcf",
			attach_type = "customorigin"
		},
		[86] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				},
				[2] = {
					attachment = "attach_tail",
					attach_type = "point_follow",
					control_point_index = 2
				}
			},
			particle = "particles/econ/courier/courier_grillhound/courier_grillhound_ambient.vpcf",
			attach_type = "customorigin"
		},
		[87] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_wing_l",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_weapon",
					attach_type = "point_follow",
					control_point_index = 0
				},
				[2] = {
					attachment = "attach_wing_r",
					attach_type = "point_follow",
					control_point_index = 2
				}
			},
			particle = "particles/econ/courier/courier_doomling/courier_doomling_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[88] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_carpet_2",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_carpet_1",
					attach_type = "point_follow",
					control_point_index = 0
				},
				[3] = {
					attachment = "attach_carpet_4",
					attach_type = "point_follow",
					control_point_index = 3
				},
				[2] = {
					attachment = "attach_carpet_3",
					attach_type = "point_follow",
					control_point_index = 2
				}
			},
			particle = "particles/econ/courier/courier_smeevil_flying_carpet/courier_smeevil_flying_carpet_ambient.vpcf",
			attach_type = "customorigin"
		},
		[89] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_mouth",
					attach_type = "point_follow",
					control_point_index = 2
				},
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 1
				}
			},
			particle = "particles/econ/courier/courier_venoling/courier_venoling_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[90] = {
			attach_entity = "parent",
			particle = "particles/econ/courier/courier_snail/courier_snail_trail.vpcf",
			attach_type = "absorigin_follow"
		},
		[91] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_jetpack_r",
					attach_type = "point_follow",
					control_point_index = 2
				},
				[0] = {
					attachment = "attach_jetpack_l",
					attach_type = "point_follow",
					control_point_index = 1
				}
			},
			particle = "particles/econ/courier/courier_snail/courier_snail_ambient_flying.vpcf",
			attach_type = "absorigin_follow"
		},
		[92] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_wing_l",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_weapon",
					attach_type = "point_follow",
					control_point_index = 0
				},
				[2] = {
					attachment = "attach_wing_r",
					attach_type = "point_follow",
					control_point_index = 2
				}
			},
			particle = "particles/econ/courier/courier_golden_doomling/courier_golden_doomling_ambient.vpcf",
			attach_type = "absorigin"
		},
		[93] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_mouth",
					attach_type = "point_follow",
					control_point_index = 2
				},
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 1
				}
			},
			particle = "particles/econ/courier/courier_venoling_gold/courier_venoling_ambient_gold.vpcf",
			attach_type = "absorigin_follow"
		},
		[94] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attach_type = "absorigin_follow",
					control_point_index = 0
				},
				[2] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 2
				}
			},
			particle = "particles/econ/courier/courier_red_horn/courier_red_horn_ambient.vpcf",
			attach_type = "customorigin"
		},
		[95] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attach_type = "absorigin_follow",
					control_point_index = 0
				},
				[2] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 2
				}
			},
			particle = "particles/econ/courier/courier_red_horn/courier_red_horn_ambient_flying.vpcf",
			attach_type = "customorigin"
		},
		[96] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 2
				},
				[0] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[3] = {
					attach_type = "absorigin_follow",
					control_point_index = 0
				},
				[2] = {
					attachment = "attach_tail",
					attach_type = "point_follow",
					control_point_index = 3
				}
			},
			particle = "particles/econ/courier/courier_jadehoof_ambient/jadehoof_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[97] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_fx",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_wyvern_hatchling/courier_wyvern_hatchling_tail_fire.vpcf",
			attach_type = "absorigin_follow"
		},
		[98] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_wyvern_hatchling/courier_wyvern_hatchling_fire.vpcf",
			attach_type = "absorigin_follow"
		},
		[99] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_fx",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_wyvern_hatchling/courier_wyvern_hatchling_tail_gold.vpcf",
			attach_type = "absorigin_follow"
		},
		[100] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_wyvern_hatchling/courier_wyvern_hatchling_gold.vpcf",
			attach_type = "absorigin_follow"
		},
		[101] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_fx",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_wyvern_hatchling/courier_wyvern_hatchling_tail_ice.vpcf",
			attach_type = "absorigin_follow"
		},
		[102] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_wyvern_hatchling/courier_wyvern_hatchling_ice.vpcf",
			attach_type = "absorigin_follow"
		},
		[103] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 1
				}
			},
			particle = "particles/econ/courier/courier_seekling_gold/courier_seekling_gold_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[104] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_rocket_r",
					attach_type = "point_follow",
					control_point_index = 2
				},
				[0] = {
					attachment = "attach_rocket_l",
					attach_type = "point_follow",
					control_point_index = 1
				}
			},
			particle = "particles/econ/courier/courier_cluckles/courier_cluckles_ambient_flying.vpcf",
			attach_type = "rootbone_follow"
		},
		[105] = {
			attach_entity = "parent",
			particle = "particles/econ/courier/courier_cluckles/courier_cluckles_ambient.vpcf",
			attach_type = "rootbone_follow"
		},
		[106] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_bag",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_backpack",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_hwytty/courier_hwytty_ambient.vpcf",
			attach_type = "customorigin"
		},
		[107] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attach_type = "absorigin_follow",
					control_point_index = 0
				},
				[2] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 2
				}
			},
			particle = "particles/econ/courier/courier_gold_horn/courier_gold_horn_ambient.vpcf",
			attach_type = "customorigin"
		},
		[108] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attach_type = "absorigin_follow",
					control_point_index = 0
				},
				[2] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 2
				}
			},
			particle = "particles/econ/courier/courier_gold_horn/courier_gold_horn_ambient_flying.vpcf",
			attach_type = "customorigin"
		},
		[109] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_cloud",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_jade_dragon/courier_jade_dragon_ambient_flying.vpcf",
			attach_type = "customorigin"
		},
		[110] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_onibi/courier_onibi_green_lvl0_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[111] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_onibi/courier_onibi_green_lvl2_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[112] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_onibi/courier_onibi_green_lvl3_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[113] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_onibi/courier_onibi_green_lvl4_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[114] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				},
				[2] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 2
				}
			},
			particle = "particles/econ/courier/courier_onibi/courier_onibi_blue_lvl5_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[115] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				},
				[2] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 2
				}
			},
			particle = "particles/econ/courier/courier_onibi/courier_onibi_blue_lvl6_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[116] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				},
				[2] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 2
				}
			},
			particle = "particles/econ/courier/courier_onibi/courier_onibi_blue_lvl7_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[117] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				},
				[2] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 2
				}
			},
			particle = "particles/econ/courier/courier_onibi/courier_onibi_blue_lvl8_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[118] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				},
				[2] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 2
				}
			},
			particle = "particles/econ/courier/courier_onibi/courier_onibi_blue_lvl9_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[119] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				},
				[2] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 2
				}
			},
			particle = "particles/econ/courier/courier_onibi/courier_onibi_pink_lvl10_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[120] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				},
				[2] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 2
				}
			},
			particle = "particles/econ/courier/courier_onibi/courier_onibi_pink_lvl11_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[121] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				},
				[2] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 2
				}
			},
			particle = "particles/econ/courier/courier_onibi/courier_onibi_pink_lvl12_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[122] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				},
				[2] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 2
				}
			},
			particle = "particles/econ/courier/courier_onibi/courier_onibi_pink_lvl13_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[123] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				},
				[2] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 2
				}
			},
			particle = "particles/econ/courier/courier_onibi/courier_onibi_pink_lvl14_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[124] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				},
				[2] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 2
				}
			},
			particle = "particles/econ/courier/courier_onibi/courier_onibi_yellow_lvl15_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[125] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				},
				[2] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 2
				}
			},
			particle = "particles/econ/courier/courier_onibi/courier_onibi_yellow_lvl16_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[126] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				},
				[2] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 2
				}
			},
			particle = "particles/econ/courier/courier_onibi/courier_onibi_yellow_lvl17_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[127] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				},
				[2] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 2
				}
			},
			particle = "particles/econ/courier/courier_onibi/courier_onibi_yellow_lvl18_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[128] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				},
				[2] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 2
				}
			},
			particle = "particles/econ/courier/courier_onibi/courier_onibi_yellow_lvl19_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[129] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				},
				[2] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 2
				}
			},
			particle = "particles/econ/courier/courier_onibi/courier_onibi_yellow_lvl20_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[130] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				},
				[2] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 2
				}
			},
			particle = "particles/econ/courier/courier_onibi/courier_onibi_black_lvl21_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[131] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_onibi/courier_onibi_green_lvl0_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[132] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_master_chocobo/courier_master_chocobo_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[133] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attach_type = "absorigin_follow",
					control_point_index = 0
				},
				[3] = {
					attachment = "attach_gearbox",
					attach_type = "point_follow",
					control_point_index = 3
				},
				[2] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 2
				},
				[5] = {
					attachment = "attach_pipe_b",
					attach_type = "point_follow",
					control_point_index = 5
				},
				[4] = {
					attachment = "attach_pipe_c",
					attach_type = "point_follow",
					control_point_index = 4
				},
				[7] = {
					attachment = "attach_foot_front_l",
					attach_type = "point_follow",
					control_point_index = 7
				},
				[6] = {
					attachment = "attach_pipe_a",
					attach_type = "point_follow",
					control_point_index = 6
				},
				[9] = {
					attachment = "attach_foot_back_l",
					attach_type = "point_follow",
					control_point_index = 9
				},
				[8] = {
					attachment = "attach_foot_front_r",
					attach_type = "point_follow",
					control_point_index = 8
				},
				[10] = {
					attachment = "attach_front_back_r",
					attach_type = "point_follow",
					control_point_index = 10
				}
			},
			particle = "particles/econ/courier/courier_staglift/courier_staglift_ambient.vpcf",
			attach_type = "customorigin"
		},
		[134] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attach_type = "absorigin_follow",
					control_point_index = 0
				},
				[3] = {
					attachment = "attach_gearbox",
					attach_type = "point_follow",
					control_point_index = 3
				},
				[2] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 2
				},
				[5] = {
					attachment = "attach_pipe_b",
					attach_type = "point_follow",
					control_point_index = 5
				},
				[4] = {
					attachment = "attach_pipe_c",
					attach_type = "point_follow",
					control_point_index = 4
				},
				[7] = {
					attachment = "attach_foot_front_l",
					attach_type = "point_follow",
					control_point_index = 7
				},
				[6] = {
					attachment = "attach_pipe_a",
					attach_type = "point_follow",
					control_point_index = 6
				},
				[9] = {
					attachment = "attach_foot_back_l",
					attach_type = "point_follow",
					control_point_index = 9
				},
				[8] = {
					attachment = "attach_foot_front_r",
					attach_type = "point_follow",
					control_point_index = 8
				},
				[10] = {
					attachment = "attach_foot_back_r",
					attach_type = "point_follow",
					control_point_index = 10
				}
			},
			particle = "particles/econ/courier/courier_staglift/courier_staglift_ambient_flying.vpcf",
			attach_type = "customorigin"
		},
		[135] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_jet",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_vigilante_fox/courier_vigilante_fox.vpcf",
			attach_type = "customorigin"
		},
		[136] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_head",
					attach_type = "point_follow",
					control_point_index = 3
				}
			},
			particle = "particles/econ/courier/courier_krobeling/courier_krobeling_ambient_hair.vpcf",
			attach_type = "absorigin_follow"
		},
		[137] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_mega_greevil/courier_mega_greevil_ambient.vpcf",
			attach_type = "customorigin"
		},
		[138] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_cloud",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_bajie/courier_bajie.vpcf",
			attach_type = "customorigin"
		},
		[139] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_cloud",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_bajie/courier_bajie.vpcf",
			attach_type = "customorigin"
		},
		[140] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_eye",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_f2p/courier_f2p_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[141] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_head",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attach_type = "absorigin_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_axolotl_ambient/courier_axolotl_ambient_lvl2.vpcf",
			attach_type = "customorigin"
		},
		[142] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_head",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attach_type = "absorigin_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_axolotl_ambient/courier_axolotl_ambient_lvl3.vpcf",
			attach_type = "customorigin"
		},
		[143] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_head",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attach_type = "absorigin_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_axolotl_ambient/courier_axolotl_ambient_lvl4.vpcf",
			attach_type = "customorigin"
		},
		[144] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_weapon_particles",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_faceless_rex/cour_rex_weapon_glow.vpcf",
			attach_type = "customorigin"
		},
		[145] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_flying_particles",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_faceless_rex/cour_rex_flying.vpcf",
			attach_type = "customorigin"
		},
		[146] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_cloud",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_mei_nei_rabbit/courier_mei_nei_rabbit.vpcf",
			attach_type = "customorigin"
		},
		[147] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attach_type = "absorigin_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_oculopus/courier_oculopus_ambient.vpcf",
			attach_type = "absorigin"
		},
		[148] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_r_rocket",
					attach_type = "point_follow",
					control_point_index = 2
				},
				[0] = {
					attachment = "attach_l_rocket",
					attach_type = "point_follow",
					control_point_index = 1
				}
			},
			particle = "particles/econ/courier/courier_snapjaw/courier_snapjaw_ambient_flying.vpcf",
			attach_type = "rootbone_follow"
		},
		[149] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_r_rocket",
					attach_type = "point_follow",
					control_point_index = 2
				},
				[0] = {
					attachment = "attach_l_rocket",
					attach_type = "point_follow",
					control_point_index = 1
				}
			},
			particle = "particles/econ/courier/courier_snapjaw/courier_snapjaw_ambient_flying.vpcf",
			attach_type = "rootbone_follow"
		},
		[150] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_kunkka_parrot/courier_kunkka_parrot_row_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[151] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_kunkka_parrot/courier_kunkka_parrot_row_ambient_flying.vpcf",
			attach_type = "absorigin_follow"
		},
		[152] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_kunkka_parrot/courier_kunkka_parrot_sail_ambient_flying.vpcf",
			attach_type = "absorigin_follow"
		},
		[153] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_kunkka_parrot/courier_kunkka_parrot_sail_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[154] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_kunkka_parrot/courier_kunkka_parrot_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[155] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_jaw",
					attach_type = "point_follow",
					control_point_index = 0
				},
				[0] = {
					attachment = "attach_tongue",
					attach_type = "point_follow",
					control_point_index = 1
				}
			},
			particle = "particles/econ/courier/courier_butch/courier_butch_ambient.vpcf",
			attach_type = "customorigin"
		},
		[156] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_lockjaw/courier_lockjaw_ambient.vpcf",
			attach_type = "absorigin_follow"
		},
		[157] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_flipper_fl",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_murrissey_the_smeevil/courier_murrissey_the_smeevil_fl.vpcf",
			attach_type = "absorigin_follow"
		},
		[158] = {
			attach_entity = "parent",
			control_points = {
				[0] = {
					attachment = "attach_flipper_fr",
					attach_type = "point_follow",
					control_point_index = 0
				}
			},
			particle = "particles/econ/courier/courier_murrissey_the_smeevil/courier_murrissey_the_smeevil_fr.vpcf",
			attach_type = "absorigin_follow"
		},
		[159] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_m",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				},
				[3] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 3
				},
				[2] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 2
				},
				[5] = {
					attachment = "attach_wing_l",
					attach_type = "point_follow",
					control_point_index = 5
				},
				[4] = {
					attach_type = "absorigin_follow",
					control_point_index = 4
				},
				[6] = {
					attachment = "attach_wing_r",
					attach_type = "point_follow",
					control_point_index = 6
				}
			},
			particle = "particles/econ/courier/courier_roshan_darkmoon/courier_roshan_darkmoon_flying.vpcf",
			attach_type = "absorigin_follow"
		},
		[160] = {
			attach_entity = "parent",
			control_points = {
				[1] = {
					attachment = "attach_eye_m",
					attach_type = "point_follow",
					control_point_index = 1
				},
				[0] = {
					attachment = "attach_eye_l",
					attach_type = "point_follow",
					control_point_index = 0
				},
				[3] = {
					attachment = "attach_hitloc",
					attach_type = "point_follow",
					control_point_index = 3
				},
				[2] = {
					attachment = "attach_eye_r",
					attach_type = "point_follow",
					control_point_index = 2
				},
				[5] = {
					attachment = "attach_wing_l",
					attach_type = "point_follow",
					control_point_index = 5
				},
				[4] = {
					attach_type = "absorigin_follow",
					control_point_index = 4
				},
				[6] = {
					attachment = "attach_wing_r",
					attach_type = "point_follow",
					control_point_index = 6
				}
			},
			particle = "particles/econ/courier/courier_roshan_darkmoon/courier_roshan_darkmoon.vpcf",
			attach_type = "absorigin_follow"
		}
	},
	couriers = {
		[1] = {
			model = "models/courier/beetlejaws/mesh/beetlejaws.vmdl",
			particles = {
				[1] = 1
			},
			skin = 1
		},
		[2] = {
			particles = {},
			model = "models/courier/juggernaut_dog/juggernaut_dog.vmdl"
		},
		[3] = {
			particles = {},
			model = "models/courier/yak/yak.vmdl"
		},
		[4] = {
			particles = {
				[1] = 2
			},
			model = "models/items/courier/g1_courier/g1_courier.vmdl"
		},
		[5] = {
			model = "models/courier/baby_rosh/babyroshan.vmdl",
			particles = {
				[1] = 3
			},
			skin = 5
		},
		[6] = {
			particles = {},
			model = "models/items/courier/raiq/raiq.vmdl"
		},
		[7] = {
			particles = {},
			model = "models/items/courier/coco_the_courageous/coco_the_courageous.vmdl"
		},
		[8] = {
			model = "models/items/courier/nexon_turtle_02_grey/nexon_turtle_02_grey.vmdl",
			particles = {},
			skin = 0
		},
		[9] = {
			model = "models/items/courier/nexon_turtle_03_grey/nexon_turtle_03_grey.vmdl",
			particles = {},
			skin = 0
		},
		[10] = {
			model = "models/items/courier/nexon_turtle_03_grey/nexon_turtle_03_grey.vmdl",
			particles = {
				[1] = 5
			},
			skin = 0
		},
		[11] = {
			model = "models/items/courier/nexon_turtle_05_green/nexon_turtle_05_green.vmdl",
			particles = {
				[1] = 6
			},
			skin = 0
		},
		[12] = {
			model = "models/items/courier/nexon_turtle_06_green/nexon_turtle_06_green.vmdl",
			particles = {
				[1] = 7
			},
			skin = 0
		},
		[13] = {
			model = "models/items/courier/nexon_turtle_07_green/nexon_turtle_07_green.vmdl",
			particles = {
				[1] = 8
			},
			skin = 0
		},
		[14] = {
			model = "models/items/courier/nexon_turtle_07_green/nexon_turtle_07_green.vmdl",
			particles = {
				[1] = 9,
				[2] = 10
			},
			skin = 0
		},
		[15] = {
			model = "models/items/courier/nexon_turtle_09_blue/nexon_turtle_09_blue.vmdl",
			particles = {
				[1] = 11,
				[2] = 12
			},
			skin = 0
		},
		[16] = {
			model = "models/items/courier/nexon_turtle_10_blue/nexon_turtle_10_blue.vmdl",
			particles = {
				[1] = 13,
				[2] = 14
			},
			skin = 0
		},
		[17] = {
			model = "models/items/courier/nexon_turtle_11_blue/nexon_turtle_11_blue.vmdl",
			particles = {
				[1] = 15,
				[2] = 16
			},
			skin = 0
		},
		[18] = {
			model = "models/items/courier/nexon_turtle_11_blue/nexon_turtle_11_blue.vmdl",
			particles = {
				[1] = 17,
				[2] = 18
			},
			skin = 0
		},
		[19] = {
			model = "models/items/courier/nexon_turtle_13_red/nexon_turtle_13_red.vmdl",
			particles = {
				[1] = 19,
				[2] = 20
			},
			skin = 0
		},
		[20] = {
			model = "models/items/courier/nexon_turtle_14_red/nexon_turtle_14_red.vmdl",
			particles = {
				[1] = 21,
				[2] = 22
			},
			skin = 0
		},
		[21] = {
			model = "models/items/courier/nexon_turtle_15_red/nexon_turtle_15_red.vmdl",
			particles = {
				[1] = 23,
				[2] = 24
			},
			skin = 0
		},
		[22] = {
			model = "models/items/courier/nexon_turtle_15_red/nexon_turtle_15_red.vmdl",
			particles = {
				[1] = 25,
				[2] = 26
			},
			skin = 0
		},
		[23] = {
			model = "models/items/courier/nexon_turtle_17_gold/nexon_turtle_17_gold.vmdl",
			particles = {
				[1] = 27,
				[2] = 28
			},
			skin = 0
		},
		[24] = {
			model = "models/items/courier/nexon_turtle_01_grey/nexon_turtle_01_grey.vmdl",
			particles = {},
			skin = 0
		},
		[25] = {
			particles = {},
			model = "models/items/courier/guardians_of_justice_enix/guardians_of_justice_enix.vmdl"
		},
		[26] = {
			model = "models/courier/flopjaw/flopjaw.vmdl",
			particles = {
				[1] = 29
			},
			skin = 1
		},
		[27] = {
			particles = {},
			model = "models/items/courier/shagbark/shagbark.vmdl"
		},
		[28] = {
			particles = {},
			model = "models/items/courier/mlg_courier_wraith/mlg_courier_wraith.vmdl"
		},
		[29] = {
			particles = {},
			model = "models/items/courier/basim/basim.vmdl"
		},
		[30] = {
			particles = {
				[1] = 30
			},
			model = "models/courier/otter_dragon/otter_dragon.vmdl"
		},
		[31] = {
			particles = {},
			model = "models/items/courier/white_the_crystal_courier/white_the_crystal_courier.vmdl"
		},
		[32] = {
			particles = {
				[1] = 31,
				[2] = 32
			},
			model = "models/items/courier/dc_demon/dc_demon.vmdl"
		},
		[33] = {
			particles = {
				[1] = 33
			},
			model = "models/courier/huntling/huntling.vmdl"
		},
		[34] = {
			particles = {},
			model = "models/items/courier/gnomepig/gnomepig.vmdl"
		},
		[35] = {
			model = "models/courier/ram/ram.vmdl",
			particles = {
				[1] = 34,
				[2] = 35
			},
			skin = 1
		},
		[36] = {
			particles = {
				[1] = 36
			},
			model = "models/items/courier/deathripper/deathripper.vmdl"
		},
		[37] = {
			particles = {
				[1] = 37
			},
			model = "models/items/courier/premier_league_wyrmeleon/premier_league_wyrmeleon.vmdl"
		},
		[38] = {
			particles = {
				[1] = 38,
				[2] = 39
			},
			model = "models/items/courier/shibe_dog_cat/shibe_dog_cat.vmdl"
		},
		[39] = {
			particles = {
				[1] = 40,
				[2] = 41
			},
			model = "models/items/courier/lgd_golden_skipper/lgd_golden_skipper.vmdl"
		},
		[40] = {
			model = "models/courier/juggernaut_dog/juggernaut_dog.vmdl",
			particles = {},
			skin = 1
		},
		[41] = {
			particles = {
				[1] = 42,
				[2] = 43
			},
			model = "models/courier/trapjaw/trapjaw.vmdl"
		},
		[42] = {
			particles = {},
			model = "models/courier/mighty_boar/mighty_boar.vmdl"
		},
		[43] = {
			model = "models/courier/minipudge/minipudge.vmdl",
			particles = {
				[1] = 44
			},
			skin = 1
		},
		[44] = {
			model = "models/courier/minipudge/minipudge.vmdl",
			particles = {
				[1] = 45
			},
			skin = 0
		},
		[45] = {
			particles = {},
			model = "models/items/courier/courier_faun/courier_faun.vmdl"
		},
		[46] = {
			particles = {},
			model = "models/items/courier/sltv_10_courier/sltv_10_courier.vmdl"
		},
		[47] = {
			model = "models/courier/smeevil/smeevil.vmdl",
			particles = {
				[1] = 46
			},
			skin = 1
		},
		[48] = {
			model = "models/courier/smeevil/smeevil.vmdl",
			particles = {
				[1] = 47
			},
			skin = 2
		},
		[49] = {
			model = "models/courier/smeevil/smeevil.vmdl",
			particles = {
				[1] = 48
			},
			skin = 3
		},
		[50] = {
			particles = {
				[1] = 49
			},
			model = "models/courier/smeevil_mammoth/smeevil_mammoth.vmdl"
		},
		[51] = {
			particles = {
				[1] = 50
			},
			model = "models/courier/smeevil_bird/smeevil_bird.vmdl"
		},
		[52] = {
			model = "models/courier/smeevil_crab/smeevil_crab.vmdl",
			particles = {
				[1] = 51
			},
			skin = 0
		},
		[53] = {
			model = "models/courier/smeevil_crab/smeevil_crab.vmdl",
			particles = {
				[1] = 52
			},
			skin = 1
		},
		[54] = {
			model = "models/courier/smeevil/smeevil.vmdl",
			particles = {
				[1] = 53
			},
			skin = 0
		},
		[55] = {
			model = "models/courier/baby_rosh/babyroshan_ti9.vmdl",
			particles = {
				[1] = "particles/econ/courier/courier_babyroshan_ti9/courier_babyroshan_ti9_ambient.vpcf"
			},
			skin = 6
		},
		[56] = {
			particles = {
				[1] = 54
			},
			model = "models/courier/mechjaw/mechjaw.vmdl"
		},
		[57] = {
			particles = {},
			model = "models/items/courier/lilnova/lilnova.vmdl"
		},
		[58] = {
			particles = {
				[1] = 55
			},
			model = "models/items/courier/devourling/devourling.vmdl"
		},
		[59] = {
			particles = {},
			model = "models/courier/donkey_trio/mesh/donkey_trio.vmdl"
		},
		[60] = {
			model = "models/items/courier/little_sappling_style1/little_sappling_style1.vmdl",
			particles = {
				[1] = 56,
				[2] = 57
			},
			skin = 1
		},
		[61] = {
			model = "models/items/courier/little_sappling_style1/little_sappling_style1.vmdl",
			particles = {
				[1] = 58,
				[2] = 59
			},
			skin = 2
		},
		[62] = {
			model = "models/items/courier/little_sappling_style1/little_sappling_style1.vmdl",
			particles = {
				[1] = 60,
				[2] = 61
			},
			skin = 3
		},
		[63] = {
			particles = {},
			model = "models/items/courier/babka_bewitcher_blue/babka_bewitcher_blue.vmdl"
		},
		[64] = {
			particles = {},
			model = "models/items/courier/snaggletooth_red_panda/snaggletooth_red_panda.vmdl"
		},
		[65] = {
			model = "models/props_gameplay/donkey.vmdl",
			particles = {},
			skin = 1
		},
		[66] = {
			particles = {},
			model = "models/courier/badger/courier_badger.vmdl"
		},
		[67] = {
			particles = {},
			model = "models/items/courier/boooofus_courier/boooofus_courier.vmdl"
		},
		[68] = {
			particles = {
				[1] = 62
			},
			model = "models/items/courier/mok/mok.vmdl"
		},
		[69] = {
			particles = {},
			model = "models/items/courier/snowl/snowl.vmdl"
		},
		[70] = {
			particles = {
				[1] = 63
			},
			model = "models/courier/beetlejaws/mesh/beetlejaws.vmdl"
		},
		[71] = {
			particles = {},
			model = "models/items/courier/snaggletooth_red_panda/snaggletooth_red_panda.vmdl"
		},
		[72] = {
			particles = {},
			model = "models/items/courier/shroomy/shroomy.vmdl"
		},
		[73] = {
			particles = {},
			model = "models/courier/navi_courier/navi_courier.vmdl"
		},
		[74] = {
			particles = {
				[1] = 64
			},
			model = "models/courier/sw_donkey/sw_donkey.vmdl"
		},
		[75] = {
			model = "models/items/courier/bearzky_v2/bearzky_v2.vmdl",
			particles = {},
			skin = 1
		},
		[76] = {
			model = "models/items/courier/bearzky/bearzky.vmdl",
			particles = {},
			skin = 0
		},
		[77] = {
			particles = {
				[1] = 65
			},
			model = "models/items/courier/pw_zombie/pw_zombie.vmdl"
		},
		[78] = {
			particles = {},
			model = "models/items/courier/jilling_ben_courier/jilling_ben_courier.vmdl"
		},
		[79] = {
			particles = {
				[1] = 66
			},
			model = "models/courier/donkey_unicorn/donkey_unicorn.vmdl"
		},
		[80] = {
			model = "models/items/courier/xianhe_stork/xianhe_stork.vmdl",
			particles = {
				[1] = 67
			},
			skin = 1
		},
		[81] = {
			model = "models/items/courier/xianhe_stork/xianhe_stork.vmdl",
			particles = {
				[1] = 68
			},
			skin = 0
		},
		[82] = {
			particles = {},
			model = "models/items/courier/hermit_crab/hermit_crab_boot.vmdl"
		},
		[83] = {
			particles = {},
			model = "models/items/courier/hermit_crab/hermit_crab_shield.vmdl"
		},
		[84] = {
			particles = {
				[1] = "particles/econ/courier/courier_hermit_crab/hermit_crab_necro_ambient.vpcf"
			},
			model = "models/items/courier/hermit_crab/hermit_crab_necro.vmdl"
		},
		[85] = {
			particles = {
				[1] = "particles/econ/courier/courier_hermit_crab/hermit_crab_bot_ambient.vpcf"
			},
			model = "models/items/courier/hermit_crab/hermit_crab_travelboot.vmdl"
		},
		[86] = {
			particles = {
				[1] = "particles/econ/courier/courier_hermit_crab/hermit_crab_lotus_ambient.vpcf"
			},
			model = "models/items/courier/hermit_crab/hermit_crab_lotus.vmdl"
		},
		[87] = {
			particles = {
				[1] = "particles/econ/courier/courier_hermit_crab/hermit_crab_octarine_ambient.vpcf"
			},
			model = "models/items/courier/hermit_crab/hermit_crab_octarine.vmdl"
		},
		[88] = {
			particles = {
				[1] = "particles/econ/courier/courier_hermit_crab/hermit_crab_skady_ambient.vpcf"
			},
			model = "models/items/courier/hermit_crab/hermit_crab_skady.vmdl"
		},
		[89] = {
			particles = {
				[1] = "particles/econ/courier/courier_hermit_crab/hermit_crab_aegis_ambient.vpcf"
			},
			model = "models/items/courier/hermit_crab/hermit_crab_aegis.vmdl"
		},
		[90] = {
			particles = {},
			model = "models/items/courier/hermit_crab/hermit_crab.vmdl"
		},
		[91] = {
			particles = {},
			model = "models/items/courier/hermit_crab/hermit_crab.vmdl"
		},
		[92] = {
			model = "models/items/courier/devourling/devourling.vmdl",
			particles = {
				[1] = 69
			},
			skin = 1
		},
		[93] = {
			particles = {},
			model = "models/items/courier/royal_griffin_cub/royal_griffin_cub.vmdl"
		},
		[94] = {
			particles = {
				[1] = "particles/econ/courier/courier_donkey_ti7/courier_donkey_ti7_ambient.vpcf"
			},
			model = "models/courier/donkey_ti7/donkey_ti7.vmdl"
		},
		[95] = {
			particles = {
				[1] = 70
			},
			model = "models/items/courier/krobeling_gold/krobeling_gold.vmdl"
		},
		[96] = {
			model = "models/courier/flopjaw/flopjaw.vmdl",
			particles = {
				[1] = 71
			},
			skin = 0
		},
		[97] = {
			particles = {},
			model = "models/items/courier/scribbinsthescarab/scribbinsthescarab.vmdl"
		},
		[98] = {
			model = "models/courier/huntling/huntling.vmdl",
			particles = {
				[1] = 72,
				[2] = 73
			},
			skin = 1
		},
		[99] = {
			model = "models/courier/baby_rosh/babyroshan.vmdl",
			particles = {},
			skin = 1
		},
		[100] = {
			particles = {},
			model = "models/courier/seekling/seekling.vmdl"
		},
		[101] = {
			particles = {},
			model = "models/items/courier/livery_llama_courier/livery_llama_courier.vmdl"
		},
		[102] = {
			particles = {
				[1] = 74,
				[2] = 75
			},
			model = "models/courier/frull/frull_courier.vmdl"
		},
		[103] = {
			particles = {
				[1] = 76
			},
			model = "models/items/courier/boris_baumhauer/boris_baumhauer.vmdl"
		},
		[104] = {
			model = "models/items/courier/wabbit_the_mighty_courier_of_heroes/wabbit_the_mighty_courier_of_heroes.vmdl",
			particles = {
				[1] = 77
			},
			skin = 1
		},
		[105] = {
			model = "models/items/courier/wabbit_the_mighty_courier_of_heroes/wabbit_the_mighty_courier_of_heroes.vmdl",
			particles = {
				[1] = 78
			},
			skin = 2
		},
		[106] = {
			model = "models/items/courier/wabbit_the_mighty_courier_of_heroes/wabbit_the_mighty_courier_of_heroes.vmdl",
			particles = {
				[1] = 79
			},
			skin = 3
		},
		[107] = {
			model = "models/items/courier/wabbit_the_mighty_courier_of_heroes/wabbit_the_mighty_courier_of_heroes.vmdl",
			particles = {
				[1] = 80
			},
			skin = 0
		},
		[108] = {
			particles = {
				[1] = 81
			},
			model = "models/items/courier/bookwyrm/bookwyrm.vmdl"
		},
		[109] = {
			particles = {},
			model = "models/items/courier/waldi_the_faithful/waldi_the_faithful.vmdl"
		},
		[110] = {
			particles = {
				[1] = "particles/econ/courier/courier_amaterasu/courier_amaterasu_ambient.vpcf"
			},
			model = "models/items/courier/amaterasu/amaterasu.vmdl"
		},
		[111] = {
			particles = {},
			model = "models/items/courier/corsair_ship/corsair_ship.vmdl"
		},
		[112] = {
			particles = {},
			model = "models/courier/baby_rosh/babyroshan.vmdl"
		},
		[113] = {
			model = "models/courier/baby_rosh/babyroshan.vmdl",
			particles = {},
			skin = 2
		},
		[114] = {
			particles = {},
			model = "models/items/courier/captain_bamboo/captain_bamboo.vmdl"
		},
		[115] = {
			particles = {},
			model = "models/items/courier/bts_chirpy/bts_chirpy.vmdl"
		},
		[116] = {
			particles = {},
			model = "models/items/courier/flightless_dod/flightless_dod.vmdl"
		},
		[117] = {
			particles = {
				[1] = 82
			},
			model = "models/courier/godhorse/godhorse.vmdl"
		},
		[118] = {
			particles = {
				[1] = 83
			},
			model = "models/items/courier/nilbog/nilbog.vmdl"
		},
		[119] = {
			particles = {},
			model = "models/items/courier/billy_bounceback/billy_bounceback.vmdl"
		},
		[120] = {
			particles = {
				[1] = 84
			},
			model = "models/courier/drodo/drodo.vmdl"
		},
		[121] = {
			particles = {},
			model = "models/courier/sillydragon/sillydragon.vmdl"
		},
		[122] = {
			particles = {
				[1] = 85
			},
			model = "models/items/courier/tinkbot/tinkbot.vmdl"
		},
		[123] = {
			particles = {
				[1] = 86
			},
			model = "models/items/courier/starladder_grillhound/starladder_grillhound.vmdl"
		},
		[124] = {
			particles = {},
			model = "models/items/courier/ig_dragon/ig_dragon.vmdl"
		},
		[125] = {
			particles = {},
			model = "models/courier/defense3_sheep/defense3_sheep.vmdl"
		},
		[126] = {
			particles = {},
			model = "models/items/courier/duskie/duskie.vmdl"
		},
		[127] = {
			model = "models/items/courier/virtus_werebear_t2/virtus_werebear_t2.vmdl",
			particles = {},
			skin = 0
		},
		[128] = {
			model = "models/items/courier/virtus_werebear_t3/virtus_werebear_t3.vmdl",
			particles = {},
			skin = 0
		},
		[129] = {
			model = "models/items/courier/virtus_werebear_t1/virtus_werebear_t1.vmdl",
			particles = {},
			skin = 0
		},
		[130] = {
			particles = {},
			model = "models/items/courier/jumo_dire/jumo_dire.vmdl"
		},
		[131] = {
			particles = {
				[1] = "particles/econ/courier/courier_babyroshan_winter18/courier_babyroshan_winter18_ambient.vpcf"
			},
			model = "models/courier/baby_rosh/babyroshan_winter18.vmdl"
		},
		[132] = {
			particles = {
				[1] = 87
			},
			model = "models/courier/doom_demihero_courier/doom_demihero_courier.vmdl"
		},
		[133] = {
			particles = {
				[1] = 88
			},
			model = "models/courier/smeevil_magic_carpet/smeevil_magic_carpet.vmdl"
		},
		[134] = {
			model = "models/courier/baby_rosh/babyroshan.vmdl",
			particles = {
				[1] = "particles/econ/courier/courier_roshan_desert_sands/baby_roshan_desert_sands_ambient_flying_loadout.vpcf",
				[2] = "particles/econ/courier/courier_roshan_desert_sands/baby_roshan_desert_sands_ambient_flying.vpcf"
			},
			skin = 4
		},
		[135] = {
			particles = {
				[1] = 89
			},
			model = "models/courier/venoling/venoling.vmdl"
		},
		[136] = {
			particles = {},
			model = "models/items/courier/carty/carty.vmdl"
		},
		[137] = {
			particles = {
				[1] = 90,
				[2] = 91
			},
			model = "models/items/courier/snail/courier_snail.vmdl"
		},
		[138] = {
			particles = {},
			model = "models/items/courier/throe/throe.vmdl"
		},
		[139] = {
			model = "models/courier/doom_demihero_courier/doom_demihero_courier.vmdl",
			particles = {
				[1] = 92
			},
			skin = 1
		},
		[140] = {
			particles = {},
			model = "models/items/courier/dokkaebi_nexon_courier/dokkaebi_nexon_courier.vmdl"
		},
		[141] = {
			particles = {},
			model = "models/courier/greevil/gold_greevil.vmdl"
		},
		[142] = {
			particles = {},
			model = "models/items/courier/alphid_of_lecaciida/alphid_of_lecaciida.vmdl"
		},
		[143] = {
			particles = {},
			model = "models/items/courier/atrophic_skitterwing/atrophic_skitterwing.vmdl"
		},
		[144] = {
			particles = {
				[1] = "particles/econ/courier/courier_nian/courier_nian_ambient.vpcf"
			},
			model = "models/items/courier/nian_courier/nian_courier.vmdl"
		},
		[145] = {
			particles = {},
			model = "models/items/courier/gama_brothers/gama_brothers.vmdl"
		},
		[146] = {
			particles = {},
			model = "models/items/courier/frostivus2018_courier_serac_the_seal/frostivus2018_courier_serac_the_seal.vmdl"
		},
		[147] = {
			model = "models/courier/venoling/venoling.vmdl",
			particles = {
				[1] = 93
			},
			skin = 1
		},
		[148] = {
			model = "models/courier/baby_rosh/babyroshan_elemental.vmdl",
			particles = {},
			skin = 2
		},
		[149] = {
			particles = {},
			model = "models/items/courier/vaal_the_animated_constructdire/vaal_the_animated_constructdire.vmdl"
		},
		[150] = {
			particles = {},
			model = "models/items/courier/raidcall_ems_one_turtle/raidcall_ems_one_turtle.vmdl"
		},
		[151] = {
			particles = {},
			model = "models/items/courier/kupu_courier/kupu_courier.vmdl"
		},
		[152] = {
			particles = {
				[1] = 94,
				[2] = 95
			},
			model = "models/courier/ram/ram.vmdl"
		},
		[153] = {
			model = "models/courier/godhorse/godhorse.vmdl",
			particles = {
				[1] = 96
			},
			skin = 1
		},
		[154] = {
			model = "models/courier/baby_winter_wyvern/baby_winter_wyvern.vmdl",
			particles = {
				[1] = 97,
				[2] = 98
			},
			skin = 1
		},
		[155] = {
			model = "models/courier/baby_winter_wyvern/baby_winter_wyvern.vmdl",
			particles = {
				[1] = 99,
				[2] = 100
			},
			skin = 2
		},
		[156] = {
			model = "models/courier/baby_winter_wyvern/baby_winter_wyvern.vmdl",
			particles = {
				[1] = 101,
				[2] = 102
			},
			skin = 0
		},
		[157] = {
			model = "models/courier/seekling/seekling.vmdl",
			particles = {
				[1] = 103
			},
			skin = 1
		},
		[158] = {
			particles = {
				[1] = 104,
				[2] = 105
			},
			model = "models/items/courier/mighty_chicken/mighty_chicken.vmdl"
		},
		[159] = {
			particles = {},
			model = "models/items/courier/weta_automaton/weta_automaton.vmdl"
		},
		[160] = {
			particles = {},
			model = "models/items/courier/azuremircourierfinal/azuremircourierfinal.vmdl"
		},
		[161] = {
			particles = {
				[1] = 106
			},
			model = "models/courier/donkey_crummy_wizard_2014/donkey_crummy_wizard_2014.vmdl"
		},
		[162] = {
			model = "models/courier/ram/ram.vmdl",
			particles = {
				[1] = 107,
				[2] = 108
			},
			skin = 2
		},
		[163] = {
			particles = {
				[1] = 109
			},
			model = "models/items/courier/green_jade_dragon/green_jade_dragon.vmdl"
		},
		[164] = {
			particles = {
				[1] = "particles/econ/courier/courier_squire/courier_squire_ambient_flying.vpcf",
				[2] = "particles/econ/courier/courier_squire/courier_squire_ambient_flying_loadout.vpcf"
			},
			model = "models/items/courier/pangolier_squire/pangolier_squire.vmdl"
		},
		[165] = {
			model = "models/items/courier/onibi_lvl_01/onibi_lvl_01.vmdl",
			particles = {
				[1] = 110
			},
			skin = 0
		},
		[166] = {
			model = "models/items/courier/onibi_lvl_02/onibi_lvl_02.vmdl",
			particles = {
				[1] = 111
			},
			skin = 0
		},
		[167] = {
			model = "models/items/courier/onibi_lvl_03/onibi_lvl_03.vmdl",
			particles = {
				[1] = 112
			},
			skin = 0
		},
		[168] = {
			model = "models/items/courier/onibi_lvl_03/onibi_lvl_03.vmdl",
			particles = {
				[1] = 113
			},
			skin = 0
		},
		[169] = {
			model = "models/items/courier/onibi_lvl_05/onibi_lvl_05.vmdl",
			particles = {
				[1] = 114
			},
			skin = 0
		},
		[170] = {
			model = "models/items/courier/onibi_lvl_06/onibi_lvl_06.vmdl",
			particles = {
				[1] = 115
			},
			skin = 0
		},
		[171] = {
			model = "models/items/courier/onibi_lvl_07/onibi_lvl_07.vmdl",
			particles = {
				[1] = 116
			},
			skin = 0
		},
		[172] = {
			model = "models/items/courier/onibi_lvl_09/onibi_lvl_09.vmdl",
			particles = {
				[1] = 117
			},
			skin = 0
		},
		[173] = {
			model = "models/items/courier/onibi_lvl_09/onibi_lvl_09.vmdl",
			particles = {
				[1] = 118
			},
			skin = 0
		},
		[174] = {
			model = "models/items/courier/onibi_lvl_10/onibi_lvl_10.vmdl",
			particles = {
				[1] = 119
			},
			skin = 0
		},
		[175] = {
			model = "models/items/courier/onibi_lvl_11/onibi_lvl_11.vmdl",
			particles = {
				[1] = 120
			},
			skin = 0
		},
		[176] = {
			model = "models/items/courier/onibi_lvl_12/onibi_lvl_12.vmdl",
			particles = {
				[1] = 121
			},
			skin = 0
		},
		[177] = {
			model = "models/items/courier/onibi_lvl_13/onibi_lvl_13.vmdl",
			particles = {
				[1] = 122
			},
			skin = 0
		},
		[178] = {
			model = "models/items/courier/onibi_lvl_13/onibi_lvl_13.vmdl",
			particles = {
				[1] = 123
			},
			skin = 0
		},
		[179] = {
			model = "models/items/courier/onibi_lvl_15/onibi_lvl_15.vmdl",
			particles = {
				[1] = 124
			},
			skin = 0
		},
		[180] = {
			model = "models/items/courier/onibi_lvl_16/onibi_lvl_16.vmdl",
			particles = {
				[1] = 125
			},
			skin = 0
		},
		[181] = {
			model = "models/items/courier/onibi_lvl_16/onibi_lvl_16.vmdl",
			particles = {
				[1] = 126
			},
			skin = 0
		},
		[182] = {
			model = "models/items/courier/onibi_lvl_16/onibi_lvl_16.vmdl",
			particles = {
				[1] = 127
			},
			skin = 0
		},
		[183] = {
			model = "models/items/courier/onibi_lvl_19/onibi_lvl_19.vmdl",
			particles = {
				[1] = 128
			},
			skin = 0
		},
		[184] = {
			model = "models/items/courier/onibi_lvl_20/onibi_lvl_20.vmdl",
			particles = {
				[1] = 129
			},
			skin = 0
		},
		[185] = {
			model = "models/items/courier/onibi_lvl_21/onibi_lvl_21.vmdl",
			particles = {
				[1] = 130
			},
			skin = 0
		},
		[186] = {
			model = "models/items/courier/onibi_lvl_00/onibi_lvl_00.vmdl",
			particles = {
				[1] = 131
			},
			skin = 0
		},
		[187] = {
			particles = {
				[1] = 132
			},
			model = "models/items/courier/chocobo/chocobo.vmdl"
		},
		[188] = {
			particles = {
				[1] = 133,
				[2] = 134
			},
			model = "models/courier/mech_donkey/mech_donkey.vmdl"
		},
		[189] = {
			particles = {},
			model = "models/items/courier/coral_furryfish/coral_furryfish.vmdl"
		},
		[190] = {
			model = "models/items/courier/mole_messenger/mole_messenger_lvl2.vmdl",
			particles = {
				[1] = "particles/econ/courier/courier_mole_messenger_ti8/mole_propeller_ambient.vpcf",
				[2] = "particles/econ/courier/courier_mole_messenger_ti8/mole_rocket_ambient.vpcf"
			},
			skin = 1
		},
		[191] = {
			model = "models/items/courier/mole_messenger/mole_messenger_lvl3.vmdl",
			particles = {
				[1] = "particles/econ/courier/courier_mole_messenger_ti8/mole_rocket_ambient.vpcf",
				[2] = "particles/econ/courier/courier_mole_messenger_ti8/mole_drill_ambient.vpcf",
				[3] = "particles/econ/courier/courier_mole_messenger_ti8/mole_propeller_ambient.vpcf"
			},
			skin = 2
		},
		[192] = {
			model = "models/items/courier/mole_messenger/mole_messenger_lvl4.vmdl",
			particles = {
				[1] = "particles/econ/courier/courier_mole_messenger_ti8/mole_candle_ambient.vpcf",
				[2] = "particles/econ/courier/courier_mole_messenger_ti8/mole_thrusters_ambient.vpcf",
				[3] = "particles/econ/courier/courier_mole_messenger_ti8/mole_rocket_ambient.vpcf",
				[4] = "particles/econ/courier/courier_mole_messenger_ti8/mole_drill_ambient.vpcf"
			},
			skin = 3
		},
		[193] = {
			model = "models/items/courier/mole_messenger/mole_messenger_lvl5.vmdl",
			particles = {
				[1] = "particles/econ/courier/courier_mole_messenger_ti8/mole_thrusters_ambient.vpcf",
				[2] = "particles/econ/courier/courier_mole_messenger_ti8/mole_headlight_ambient.vpcf",
				[3] = "particles/econ/courier/courier_mole_messenger_ti8/mole_drill_ambient.vpcf",
				[4] = "particles/econ/courier/courier_mole_messenger_ti8/mole_rocket_ambient.vpcf"
			},
			skin = 4
		},
		[194] = {
			model = "models/items/courier/mole_messenger/mole_messenger_lvl6.vmdl",
			particles = {
				[1] = "particles/econ/courier/courier_mole_messenger_ti8/mole_jadedrill_ambient.vpcf",
				[2] = "particles/econ/courier/courier_mole_messenger_ti8/mole_headlight_ambient.vpcf",
				[3] = "particles/econ/courier/courier_mole_messenger_ti8/mole_drill_ambient.vpcf",
				[4] = "particles/econ/courier/courier_mole_messenger_ti8/mole_thrusters_ambient.vpcf",
				[5] = "particles/econ/courier/courier_mole_messenger_ti8/mole_rocket_ambient.vpcf"
			},
			skin = 5
		},
		[195] = {
			model = "models/items/courier/mole_messenger/mole_messenger_lvl7.vmdl",
			particles = {
				[1] = "particles/econ/courier/courier_mole_messenger_ti8/mole_thrusters_ambient.vpcf",
				[2] = "particles/econ/courier/courier_mole_messenger_ti8/mole_rocket_ambient.vpcf",
				[3] = "particles/econ/courier/courier_mole_messenger_ti8/mole_jadedrill_ambient.vpcf",
				[4] = "particles/econ/courier/courier_mole_messenger_ti8/mole_headlight_ambient.vpcf"
			},
			skin = 6
		},
		[196] = {
			model = "models/items/courier/mole_messenger/mole_messenger.vmdl",
			particles = {
				[1] = "particles/econ/courier/courier_mole_messenger_ti8/mole_propeller_ambient.vpcf"
			},
			skin = 0
		},
		[197] = {
			particles = {},
			model = "models/items/courier/blotto_and_stick/blotto.vmdl"
		},
		[198] = {
			particles = {},
			model = "models/items/courier/itsy/itsy.vmdl"
		},
		[199] = {
			particles = {
				[1] = 135
			},
			model = "models/items/courier/vigilante_fox_red/vigilante_fox_red.vmdl"
		},
		[200] = {
			particles = {},
			model = "models/items/courier/deathbringer/deathbringer.vmdl"
		},
		[201] = {
			particles = {},
			model = "models/courier/courier_mech/courier_mech.vmdl"
		},
		[202] = {
			particles = {
				[1] = 136
			},
			model = "models/items/courier/krobeling/krobeling.vmdl"
		},
		[203] = {
			model = "models/courier/baby_rosh/babyroshan_elemental.vmdl",
			particles = {},
			skin = 1
		},
		[204] = {
			particles = {
				[1] = 137
			},
			model = "models/courier/mega_greevil_courier/mega_greevil_courier.vmdl"
		},
		[205] = {
			model = "models/items/courier/bajie_pig/bajie_pig.vmdl",
			particles = {
				[1] = 138
			},
			skin = 1
		},
		[206] = {
			model = "models/items/courier/bajie_pig/bajie_pig.vmdl",
			particles = {
				[1] = 139
			},
			skin = 0
		},
		[207] = {
			particles = {},
			model = "models/props_gameplay/donkey_dire.vmdl"
		},
		[208] = {
			particles = {
				[1] = 140
			},
			model = "models/courier/f2p_courier/f2p_courier.vmdl"
		},
		[209] = {
			model = "models/items/courier/axolotl/axolotl.vmdl",
			particles = {
				[1] = 141
			},
			skin = 1
		},
		[210] = {
			model = "models/items/courier/axolotl/axolotl.vmdl",
			particles = {
				[1] = 142
			},
			skin = 2
		},
		[211] = {
			model = "models/items/courier/axolotl/axolotl.vmdl",
			particles = {
				[1] = 143
			},
			skin = 3
		},
		[212] = {
			model = "models/items/courier/axolotl/axolotl.vmdl",
			particles = {
				[1] = "particles/econ/courier/courier_axolotl_ambient/courier_axolotl_ambient_lvl1.vpcf"
			},
			skin = 0
		},
		[213] = {
			particles = {
				[1] = 144,
				[2] = 145
			},
			model = "models/items/courier/faceless_rex/faceless_rex.vmdl"
		},
		[214] = {
			particles = {},
			model = "models/items/courier/kanyu_shark/kanyu_shark.vmdl"
		},
		[215] = {
			particles = {},
			model = "models/items/courier/courier_mvp_redkita/courier_mvp_redkita.vmdl"
		},
		[216] = {
			particles = {
				[1] = 146
			},
			model = "models/items/courier/mei_nei_rabbit/mei_nei_rabbit.vmdl"
		},
		[217] = {
			particles = {},
			model = "models/items/courier/jin_yin_black_fox/jin_yin_black_fox.vmdl"
		},
		[218] = {
			particles = {
				[1] = 147
			},
			model = "models/courier/octopus/octopus.vmdl"
		},
		[219] = {
			particles = {
				[1] = 148
			},
			model = "models/items/courier/snapjaw/snapjaw.vmdl"
		},
		[220] = {
			particles = {},
			model = "models/items/courier/defense4_dire/defense4_dire.vmdl"
		},
		[221] = {
			particles = {},
			model = "models/items/courier/courier_janjou/courier_janjou.vmdl"
		},
		[222] = {
			particles = {
				[1] = 149
			},
			model = "models/items/courier/snapjaw/snapjaw.vmdl"
		},
		[223] = {
			particles = {},
			model = "models/items/courier/arneyb_rabbit/arneyb_rabbit.vmdl"
		},
		[224] = {
			particles = {},
			model = "models/items/courier/little_fraid_the_courier_of_simons_retribution/little_fraid_the_courier_of_simons_retribution.vmdl"
		},
		[225] = {
			particles = {},
			model = "models/items/courier/teron/teron.vmdl"
		},
		[226] = {
			model = "models/courier/baby_rosh/babyroshan_alt.vmdl",
			particles = {
				[1] = "particles/econ/courier/courier_babyrosh_alt_ti8/courier_babyrosh_alt_ti8.vpcf"
			},
			skin = 2
		},
		[227] = {
			model = "models/items/courier/beaverknight_s1/beaverknight_s1.vmdl",
			particles = {},
			skin = 0
		},
		[228] = {
			model = "models/items/courier/beaverknight_s2/beaverknight_s2.vmdl",
			particles = {},
			skin = 0
		},
		[229] = {
			model = "models/items/courier/beaverknight/beaverknight.vmdl",
			particles = {},
			skin = 0
		},
		[230] = {
			particles = {},
			model = "models/items/courier/shagbark/shagbark.vmdl"
		},
		[231] = {
			model = "models/courier/skippy_parrot/skippy_parrot.vmdl",
			particles = {
				[1] = 151
			},
			skin = 1
		},
		[232] = {
			model = "models/courier/skippy_parrot/skippy_parrot.vmdl",
			particles = {
				[1] = 152
			},
			skin = 2
		},
		[233] = {
			model = "models/courier/skippy_parrot/skippy_parrot.vmdl",
			particles = {
				[1] = 154
			},
			skin = 0
		},
		[234] = {
			particles = {},
			model = "models/items/courier/blue_lightning_horse/blue_lightning_horse.vmdl"
		},
		[235] = {
			particles = {
				[1] = 155
			},
			model = "models/items/courier/butch_pudge_dog/butch_pudge_dog.vmdl"
		},
		[236] = {
			particles = {},
			model = "models/items/courier/tory_the_sky_guardian/tory_the_sky_guardian.vmdl"
		},
		[237] = {
			particles = {},
			model = "models/items/courier/scuttling_scotty_penguin/scuttling_scotty_penguin.vmdl"
		},
		[238] = {
			particles = {},
			model = "models/items/courier/baekho/baekho.vmdl"
		},
		[239] = {
			particles = {},
			model = "models/items/courier/d2l_steambear/d2l_steambear.vmdl"
		},
		[240] = {
			particles = {},
			model = "models/courier/greevil/greevil.vmdl"
		},
		[241] = {
			particles = {},
			model = "models/items/courier/amphibian_kid/amphibian_kid.vmdl"
		},
		[242] = {
			particles = {},
			model = "models/courier/imp/imp.vmdl"
		},
		[243] = {
			particles = {},
			model = "models/courier/tegu/tegu.vmdl"
		},
		[244] = {
			particles = {},
			model = "models/courier/stump/stump.vmdl"
		},
		[245] = {
			particles = {
				[1] = 156
			},
			model = "models/courier/lockjaw/lockjaw.vmdl"
		},
		[246] = {
			particles = {
				[1] = 157,
				[2] = 158
			},
			model = "models/courier/turtle_rider/turtle_rider.vmdl"
		},
		[247] = {
			model = "models/courier/baby_rosh/babyroshan.vmdl",
			particles = {
				[1] = 159,
				[2] = 160
			},
			skin = 3
		},
		[248] = {
			particles = {},
			model = "models/courier/frog/frog.vmdl"
		},
		[249] = {
			particles = {},
			model = "models/items/courier/weplay_beaver/weplay_beaver.vmdl"
		},
		[250] = {
			model = "models/courier/baby_rosh/babyroshan_alt.vmdl",
			particles = {
				[1] = "particles/econ/courier/courier_babyrosh_alt_ti7/courier_babyrosh_alt_ti7.vpcf"
			},
			skin = 1
		},
		[251] = {
			particles = {},
			model = "models/items/courier/pumpkin_courier/pumpkin_courier.vmdl"
		},
		[252] = {
			particles = {
				[1] = "particles/econ/courier/courier_ti9/courier_ti9_lvl2_base.vpcf"
			},
			model = "models/items/courier/courier_ti9/courier_ti9_lvl2/courier_ti9_lvl2.vmdl"
		},
		[253] = {
			particles = {
				[1] = "particles/econ/courier/courier_ti9/courier_ti9_lvl3_base.vpcf"
			},
			model = "models/items/courier/courier_ti9/courier_ti9_lvl3/courier_ti9_lvl3.vmdl"
		},
		[254] = {
			particles = {
				[1] = "particles/econ/courier/courier_ti9/courier_ti9_lvl4_base.vpcf"
			},
			model = "models/items/courier/courier_ti9/courier_ti9_lvl4/courier_ti9_lvl4.vmdl"
		},
		[255] = {
			particles = {
				[1] = "particles/econ/courier/courier_ti9/courier_ti9_lvl5_base.vpcf"
			},
			model = "models/items/courier/courier_ti9/courier_ti9_lvl5/courier_ti9_lvl5.vmdl"
		},
		[256] = {
			particles = {
				[1] = "particles/econ/courier/courier_ti9/courier_ti9_lvl6_base.vpcf"
			},
			model = "models/items/courier/courier_ti9/courier_ti9_lvl6/courier_ti9_lvl6.vmdl"
		},
		[257] = {
			particles = {
				[1] = "particles/econ/courier/courier_ti9/courier_ti9_lvl7_base.vpcf"
			},
			model = "models/items/courier/courier_ti9/courier_ti9_lvl7/courier_ti9_lvl7.vmdl"
		},
		[258] = {
			particles = {
				[1] = "particles/econ/courier/courier_ti9/courier_ti9_lvl1_base.vpcf"
			},
			model = "models/items/courier/courier_ti9/courier_ti9_lvl1/courier_ti9_lvl1.vmdl"
		},
		[259] = {
			particles = {},
			model = "models/items/courier/serpent_warbler/serpent_warbler.vmdl"
		},
		[260] = {
			particles = {},
			model = "models/items/courier/bucktooth_jerry/bucktooth_jerry.vmdl"
		},
		[261] = {
			model = "models/items/courier/el_gato_beyond_the_summit/el_gato_beyond_the_summit.vmdl",
			particles = {},
			skin = 1
		},
		[262] = {
			model = "models/items/courier/el_gato_hero/el_gato_hero.vmdl",
			particles = {},
			skin = 0
		},
		[263] = {
			model = "models/items/courier/el_gato_beyond_the_summit/el_gato_beyond_the_summit.vmdl",
			particles = {},
			skin = 0
		}
	}
}