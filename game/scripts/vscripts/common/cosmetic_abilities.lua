local abilitiyPatreonLevel = {
	["high_five"] = 0,
	["seasonal_ti9_banner"] = 0,
	["seasonal_summon_cny_balloon"] = 0,
	["seasonal_summon_dragon"] = 0,
	["seasonal_summon_cny_tree"] = 0,
	["seasonal_firecrackers"] = 0,
	["seasonal_ti9_shovel"] = 0,
	["seasonal_ti9_instruments"] = 0,
	["seasonal_ti9_monkey"] = 0,
	["seasonal_summon_ti9_balloon"] = 0,
	["seasonal_throw_snowball"] = 0,
	["seasonal_festive_firework"] = 0,
	["seasonal_decorate_tree"] = 0,
	["seasonal_summon_snowman"] = 0,
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
	playerCourierEffects = {},
	playerWardEffects = {},

	playerHeroColors = {},
	playerPetColors = {},
	playerCourierColors = {},
	playerWardColors = {},

	playerKillEffects = {},
	playerPets = {},
}

require( "common/cosmetics_data" )

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

local function SetEffectColor( p, c, e )
	local e = type( e ) == "number" and Cosmetics.heroEffects[e] or e

	if e.color_point then
		ParticleManager:SetParticleControl( p, e.color_point, c )
	else
		ParticleManager:SetParticleControl( p, 15, c )
		ParticleManager:SetParticleControl( p, 16, Vector( 1, 0, 0 ) )
	end
end

local function RemoveEffectColor( p, e )
	local e = type( e ) == "number" and Cosmetics.heroEffects[e] or e

	if e.color_point then
		ParticleManager:SetParticleControl( p, e.color_point, Vector( 255, 255, 255 ) )
	else
		ParticleManager:SetParticleControl( p, 15, Vector( 255, 255, 255 ) )
		ParticleManager:SetParticleControl( p, 16, Vector( 0, 0, 0 ) )
	end
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

	if c or color then
		SetEffectColor( p, color or Vector( c.r, c.g, c.b ), effect )
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
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
			DOTA_UNIT_TARGET_FLAG_NO_INVIS,
			FIND_CLOSEST,
			false
		)[1]

		if near then
			enemy_dis = ( near:GetAbsOrigin() - pet_pos ):Length2D()

			if enemy_dis < 70 and not pet.isHidden then
				HidePet( pet, 100 )
			end
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

			FindClearSpaceForUnit( pet, owner_pos + r, true )
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
		local cosmetics = Patreons:GetPlayerSettings( id ).cosmetics

		if cosmetics then
			for _, ability in pairs( cosmetics.abilities ) do
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

			if cosmetics.hero_effect ~= -1 then
				self.SetHeroEffect( { PlayerID = id, index = cosmetics.hero_effect, type = "hero" } )
			end
			if cosmetics.pet_effect ~= -1 then
				self.SetHeroEffect( { PlayerID = id, index = cosmetics.pet_effect, type = "pet" } )
			end
			if cosmetics.wards_effect ~= -1 then
				self.SetHeroEffect( { PlayerID = id, index = cosmetics.wards_effect, type = "wards" } )
			end

			if cosmetics.hero_color ~= -1 then
				self.SetEffectColor( { PlayerID = id, index = cosmetics.hero_color, type = "hero" } )
			end
			if cosmetics.pet_color ~= -1 then
				self.SetEffectColor( { PlayerID = id, index = cosmetics.pet_color, type = "pet" } )
			end
			if cosmetics.wards_color ~= -1 then
				self.SetEffectColor( { PlayerID = id, index = cosmetics.wards_color, type = "wards" } )
			end

			if cosmetics.kill_effect ~= -1 then
				self.SetKillEffect( { PlayerID = id, index = cosmetics.kill_effect } )
			end

			if cosmetics.pet ~= -1 then
				self.SelectPet( { PlayerID = id, index = cosmetics.pet } )
			end
		end

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

	if killer and victim:IsRealHero() and not victim:IsReincarnating() then
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
		CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer( keys.PlayerID ), "display_custom_error", { message = "#nopatreonerror" } )
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
		CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer( keys.PlayerID ), "display_custom_error", { message = "#nopatreonerror" } )
	end
end

function Cosmetics.SetHeroEffect( keys )
	local id = keys.PlayerID
	local index = tonumber( keys.index )
	local effect = Cosmetics.heroEffects[index]
	local patreon = Patreons:GetPlayerSettings( id )

	if not effect then
		return
	--[[elseif not IsInToolsMode() and patreon.level < 1 then
		CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer( id ), "display_custom_error", { message = "#nopatreonerror" } )
		return]]
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
		local pet_data = Cosmetics.playerPets[id]
		local pet_effect = Cosmetics.playerPetEffects[id] or {}

		if pet_data then
			local pet = pet_data.unit

			if pet then
				if pet_effect and pet_effect.particle then
					ParticleManager:DestroyParticle( pet_effect.particle, true )
					ParticleManager:ReleaseParticleIndex( pet_effect.particle )
				end

				if not pet_effect then
					Cosmetics.playerPetEffects[id] = {}
				end

				local c = Cosmetics.playerPetColors[id]

				pet_effect.particle = CreateEffect( pet, effect, c and c.color or nil )
			end
		end

		pet_effect.index = index

		Cosmetics.playerPetEffects[id] = pet_effect
	elseif keys.type == "courier" then
		--local team = PlayerResource:GetTeam( id )
		--local courier = SearchCorrectCourier( id, team )
		--
		--if courier and courier.cosmeticEffect then
		--	local e = courier.cosmeticEffect
		--
		--	ParticleManager:DestroyParticle( e.particle, true )
		--	ParticleManager:ReleaseParticleIndex( e.particle )
		--end
		--
		--local c = Cosmetics.playerCourierColors[id]
		--
		--courier.cosmeticEffect = {
		--	particle = CreateEffect( courier, effect, c and c.color or nil ),
		--	index = index
		--}
	elseif keys.type == "wards" then
		local data = Cosmetics.playerWardEffects[id]

		if data then
			for _, ward in pairs( data.wards ) do
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

	local t = CustomNetTables:GetTableValue( "cosmetics", tostring( id ) ) or {}
	t[keys.type .. "_effect"] = index
	CustomNetTables:SetTableValue( "cosmetics", tostring( id ), t )
end

function Cosmetics.RemoveHeroEffect( keys )
	local id = keys.PlayerID
	local data = Cosmetics.playerHeroEffects[id]

	if keys.type == "hero" then
		local data = Cosmetics.playerHeroEffects[id]

		if data then
			ParticleManager:DestroyParticle( data.particle, true )
			ParticleManager:ReleaseParticleIndex( data.particle )

			Cosmetics.playerHeroEffects[id] = nil
		end
	elseif keys.type == "pet" then
		local pet_effect = Cosmetics.playerPetEffects[id]

		if pet_effect and pet_effect.particle then
			ParticleManager:DestroyParticle( pet_effect.particle, true )
			ParticleManager:ReleaseParticleIndex( pet_effect.particle )
		end

		Cosmetics.playerPetEffects[id] = nil
	elseif keys.type == "courier" then
		--local team = PlayerResource:GetTeam( id )
		--local courier = SearchCorrectCourier( id, team )
		--
		--if courier and courier.cosmeticEffect then
		--	local e = courier.cosmeticEffect
		--
		--	ParticleManager:DestroyParticle( e.particle, true )
		--	ParticleManager:ReleaseParticleIndex( e.particle )
		--end
		--
		--courier.cosmeticEffect = nil
	elseif keys.type == "wards" then
		local data = Cosmetics.playerWardEffects[id]

		if data then
			for _, ward in pairs( data.wards ) do
				if ward.cosmeticEffect then
					ParticleManager:DestroyParticle( ward.cosmeticEffect, true )
					ParticleManager:ReleaseParticleIndex( ward.cosmeticEffect )
				end
			end
		end

		data.index = nil
		data.effect = nil
	end

	local t = CustomNetTables:GetTableValue( "cosmetics", tostring( id ) ) or {}
	t[keys.type .. "_effect"] = nil
	CustomNetTables:SetTableValue( "cosmetics", tostring( id ), t )
end

function Cosmetics.SetEffectColor( keys )
	local id = keys.PlayerID
	local index = tonumber( keys.index )
	local color = Cosmetics.prismaticColors[index]
	local patreon = Patreons:GetPlayerSettings( id )

	if not color then
		return
	--[[elseif not IsInToolsMode() and patreon.level < 1 then
		CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer( id ), "display_custom_error", { message = "#nopatreonerror" } )
		return]]
	end

	if keys.type == "hero" then
		local data = Cosmetics.playerHeroEffects[id]

		if data then
			SetEffectColor( data.particle, color, data.index )
		end

		Cosmetics.playerHeroColors[id] = {
			color = color,
			index = index
		}
	elseif keys.type == "pet" then
		local data = Cosmetics.playerPetEffects[id]

		if data and data.particle then
			SetEffectColor( data.particle, color, data.index )
		end

		Cosmetics.playerPetColors[id] = {
			color = color,
			index = index
		}
	elseif keys.type == "courier" then
		--local team = PlayerResource:GetTeam( id )
		--local courier = SearchCorrectCourier( id, team )
		--
		--if courier and courier.cosmeticEffect then
		--	local e = courier.cosmeticEffect
		--
		--	SetEffectColor( e.particle, color, e.index )
		--end
		--
		--Cosmetics.playerCourierColors[id] = {
		--	index = index,
		--	color = color
		--}
	elseif keys.type == "wards" then
		local data = Cosmetics.playerWardEffects[id]

		if data then
			for _, ward in pairs( data.wards ) do
				if ward.cosmeticEffect then
					SetEffectColor( ward.cosmeticEffect, color, data.index )
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

	local t = CustomNetTables:GetTableValue( "cosmetics", tostring( id ) ) or {}
	t[keys.type .. "_color"] = index
	CustomNetTables:SetTableValue( "cosmetics", tostring( id ), t )
end

function Cosmetics.RemoveEffectColor( keys )
	local id = keys.PlayerID

	if keys.type == "hero" then
		local data = Cosmetics.playerHeroEffects[id]

		if data then
			RemoveEffectColor( data.particle, data.index )
		end

		Cosmetics.playerHeroColors[id] = nil
	elseif keys.type == "pet" then
		local data = Cosmetics.playerPetEffects[id]

		if data and data.particle then
			RemoveEffectColor( data.particle, data.index )
		end

		Cosmetics.playerPetColors[id] = nil
	elseif keys.type == "courier" then
		--local team = PlayerResource:GetTeam( id )
		--local courier = SearchCorrectCourier( id, team )
		--
		--if courier and courier.cosmeticEffect then
		--	local e = courier.cosmeticEffect
		--
		--	RemoveEffectColor( e.particle, e.index )
		--end
		--
		--Cosmetics.playerCourierColors[id] = nil
	elseif keys.type == "wards" then
		local data = Cosmetics.playerWardEffects

		if data then
			for _, ward in pairs( data.wards ) do
				if ward.cosmeticEffect then
					RemoveEffectColor( ward.cosmeticEffect, data.index )
				end
			end
		end

		Cosmetics.playerWardColors[id] = nil
	else
		return
	end

	local t = CustomNetTables:GetTableValue( "cosmetics", tostring( id ) ) or {}
	t[keys.type .. "_color"] = nil
	CustomNetTables:SetTableValue( "cosmetics", tostring( id ), t )
end

function Cosmetics.SetKillEffect( keys )
	local id = keys.PlayerID
	local effect = Cosmetics["kill_effect_" .. keys.effect_name]
	local patreon = Patreons:GetPlayerSettings( id )

	if not effect then
		return
	elseif effect == Cosmetics.playerKillEffects[id] then
		return
	--[[elseif not IsInToolsMode() and patreon.level < 1 then
		CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer( id ), "display_custom_error", { message = "#nopatreonerror" } )
		return]]
	end

	Cosmetics.playerKillEffects[id] = {
		effect = effect,
		name = keys.effect_name
	}

	local t = CustomNetTables:GetTableValue( "cosmetics", tostring( id ) ) or {}
	t.kill_effects = keys.effect_name
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
	--[[elseif not IsInToolsMode() and patreon.level < 1 then
		CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer( id ), "display_custom_error", { message = "#nopatreonerror" } )
		return]]
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
	CustomNetTables:SetTableValue( "cosmetics", tostring( id ), t )
end

function Cosmetics:GetSettings( id )
	local player = PlayerResource:GetPlayer( id )
	local hero = PlayerResource:GetSelectedHeroEntity( id )
	local patreon = Patreons:GetPlayerSettings( id )

	if --[[not IsInToolsMode() and patreon.level < 1 or ]]not hero then
		return
	end

	local a = self.playerPets[id]
	local b = self.playerHeroEffects[id]
	local c = self.playerHeroColors[id]
	local d = self.playerPetEffects[id]
	local e = self.playerPetColors[id]
	local f = self.playerWardEffects[id]
	local g = self.playerWardColors[id]
	local h = self.playerKillEffects[id]

	local data = {
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

	return data
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
	tomb:SetAngles( 0, RandomInt( 240, 300 ), 0 )

	EmitSoundOnLocationWithCaster( victim:GetAbsOrigin(), "FrostivusConsumable.Fireworks.Explode", killer )
end

function Cosmetics.kill_effect_incineration( killer, victim )
	local particles = {
		"particles/units/heroes/hero_lina/lina_death_a.vpcf",
		"particles/units/heroes/hero_lina/lina_death_ash_ground.vpcf",
		"particles/units/heroes/hero_lina/lina_death_b.vpcf",
		"particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_shadowraze_collumn.vpcf",
		"particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_shadowraze_char_fire.vpcf",
		"particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_shadowraze_char.vpcf"
	}

	for _, pname in pairs( particles ) do
		local p = ParticleManager:CreateParticle( pname, PATTACH_WORLDORIGIN, victim )
		ParticleManager:SetParticleControl( p, 0, victim:GetAbsOrigin() )
		ParticleManager:ReleaseParticleIndex( p )
	end

	EmitSoundOnLocationWithCaster( victim:GetAbsOrigin(), "Hero_DragonKnight.BreathFire", killer ) -- Mb ""
end

function Cosmetics.kill_effect_halloween( killer, victim )
	local models = {
		"models/props_gameplay/halloween_candy.vmdl",
		"models/props_gameplay/pumpkin_bucket.vmdl"
	}

	local r = RandomInt( 1, #models )

	local pos = victim:GetAbsOrigin()
	pos.z = GetGroundHeight( victim:GetAbsOrigin(), victim )

	if r == 1 then
		pos.z = pos.z + 8
	end

	local prop = SpawnEntityFromTableSynchronous( "prop_dynamic", { origin = pos, model = models[r] } )
	prop:SetAngles( 0, RandomInt( 240, 300 ), 0 )

	if r == 2 then
		prop:SetModelScale( 0.5 )
	else
		prop:SetModelScale( 0.87 )
	end

	killer:EmitSoundParams( "Conquest.hallow_laughter", 0, 3, 5 )
end