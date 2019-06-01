local PERMANENT_HERO_ABILITIES = {
	"high_five",
	"seasonal_ti9_banner"
}

local PATREON_LEVEL_FOR_ABILITY = {
	["high_five"] = 0,
	["seasonal_ti9_banner"] = 1,
	["seasonal_summon_cny_balloon"] = 1,
	["seasonal_summon_dragon"] = 1,
	["seasonal_summon_cny_tree"] = 1,
	["seasonal_firecrackers"] = 1
}

local function AddAbilityIfNeed( npc, abilityName, sendReload )
	if npc:IsRealHero() and not npc:FindAbilityByName( abilityName ) then
		local new_ability = npc:AddAbility( abilityName )

		new_ability:SetLevel( 1 )
		new_ability:SetHidden( false )

		local p = Patreons:GetPlayerSettings( npc:GetPlayerID() )

		if p and p.level < PATREON_LEVEL_FOR_ABILITY[abilityName] then
			new_ability:SetActivated( false )
		end

		if sendReload then
			CustomGameEventManager:Send_ServerToAllClients( "cosmetic_abilities_reload_hud", nil )
		end
	end
end

ListenToGameEvent( "npc_spawned", function( keys )
	local npc = EntIndexToHScript( keys.entindex )

	if npc:IsRealHero() then
		for _, ability_name in pairs( PERMANENT_HERO_ABILITIES ) do
			AddAbilityIfNeed( npc, ability_name )
		end
	end
end, nil )

local function CheckAbilityAndUnit( abilityName, npcIndex )
	local npc = EntIndexToHScript( npcIndex )

	if not npc or not npc:GetClassname():find( "npc_dota_" ) then return end

	local id = npc:GetPlayerID()
	local p = Patreons:GetPlayerSettings( id )

	if p and p.level < PATREON_LEVEL_FOR_ABILITY[abilityName] then
		CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer( id ), "display_custom_error", { message = "#nopatreonerror" } )
		return
	end

	return true
end

CustomGameEventManager:RegisterListener( "cosmetic_abilities_try_activate", function( id, keys )
	CheckAbilityAndUnit( keys.ability, keys.unit )
end )

CustomGameEventManager:RegisterListener( "cosmetic_abilities_take", function( id, keys )
	if CheckAbilityAndUnit( keys.ability, keys.unit ) then
		AddAbilityIfNeed( EntIndexToHScript( keys.unit ), keys.ability, true )
	end
end )