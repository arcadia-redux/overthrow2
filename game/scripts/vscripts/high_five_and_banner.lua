ListenToGameEvent( "npc_spawned", function( keys )
	local npc = EntIndexToHScript( keys.entindex )

	if npc:IsRealHero() and not npc:FindAbilityByName( "high_five" ) then
		local high_five = npc:AddAbility( "high_five" )
		high_five:SetLevel( 1 )
		high_five:SetHidden( true )
	end

	if npc:IsRealHero() and not npc:FindAbilityByName( "seasonal_ti9_banner" ) then
		local banner = npc:AddAbility( "seasonal_ti9_banner" )
		banner:SetLevel( 1 )
		banner:SetHidden( true )
	end
end, nil )

CustomGameEventManager:RegisterListener( "cons_ability_activate", function( id, keys )
	local npc = EntIndexToHScript( keys.unit )

	if not npc then return end

	local p = Patreons:GetPlayerSettings( npc:GetPlayerID() )

	if p and p.level == 0 and keys.ability == "seasonal_ti9_banner" then
		CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer( npc:GetPlayerID() ), "display_custom_error", { message = "#nopatreonerror" } )
		return
	end

	local ability = npc:FindAbilityByName( keys.ability )

	if ability then
		npc:SetCursorPosition( npc:GetAbsOrigin() )
		ability:CastAbility()
	end
end )