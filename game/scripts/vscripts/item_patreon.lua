function OnSpellStart( event )
    local caster = event.caster
    local abilityname = event.Ability
    --local psets = Patreons:GetPlayerSettings(caster:GetPlayerID())
    --if psets.level > 0 then
        local pa1 = caster:AddAbility(abilityname)
        pa1:SetLevel(1)
        pa1:CastAbility()
        Timers:CreateTimer(1, function()
            caster:RemoveAbility(abilityname)
        end)
    --else
    --    CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(caster:GetPlayerID()), "display_custom_error", { message = "#nopatreonerror" })
    --end
end

function OnSpellStartBundle( event )
    local caster = event.caster
    local ability = event.ability
    local item1 = event.Item1
    local item2 = event.Item2
    local item3 = event.Item3
    local item4 = event.Item4
    if caster:IsRealHero() then
        local supporter_level = Supporters:GetLevel(caster:GetPlayerID())
        if supporter_level > 0 then
            ability:RemoveSelf()
            caster:AddItemByName(item1)
            caster:AddItemByName(item2)
            caster:AddItemByName(item3)
            caster:AddItemByName(item4)
        else
            CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(caster:GetPlayerID()), "display_custom_error", { message = "#nopatreonerror" })
        end
    end
end

function OnSpellStartBanHammer( event )
    local target = event.target
    local caster = event.caster
    local ability = event.ability

	local playerId = target:GetPlayerOwnerID()
	if playerId and WebApi.playerMatchesCount[playerId] and WebApi.playerMatchesCount[playerId] < 5 then
		ability:EndCooldown()
		CustomGameEventManager:Send_ServerToPlayer(caster:GetPlayerOwner(), "display_custom_error", { message = "#voting_to_kick_no_kick_new_players" })
		return
	end
	
    if caster:IsRealHero() then
		local caster_player_id = caster:GetPlayerID()
        local supporter_level = Supporters:GetLevel(caster_player_id)
        if supporter_level > 1 then
            if target:IsRealHero() then
				local target_player_id = target:GetPlayerID()
                local supporter_target_level = Supporters:GetLevel(target_player_id)
                if supporter_target_level == 0 then
                    local uniqueKey = caster:GetEntityIndex() .. "_" .. target:GetEntityIndex()
                    if not _G.alertsKickForPlayer[uniqueKey] then
                        _G.alertsKickForPlayer[uniqueKey] = true

                        GameRules:SendCustomMessage("#alert_for_ban_message_1",caster_player_id, 0)
                        GameRules:SendCustomMessage("#alert_for_ban_message_2", target_player_id, 0)

                        local all_heroes = HeroList:GetAllHeroes()
                        for _, hero in pairs(all_heroes) do
                            if hero:IsRealHero() and hero:IsControllableByAnyPlayer() then
                                EmitSoundOn("Hero_Chen.HandOfGodHealHero" , hero)
                            end
                        end

                        CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(target_player_id), "display_custom_error", { message = "#alertforban" })
                        ability:ApplyDataDrivenModifier(caster, target, "modifier_alert_before_kick", { duration = 30 })
                    else
                        if target:HasModifier("modifier_alert_before_kick") then
                            CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(caster_player_id), "display_custom_error", { message = "#playerhasalertforban" })
                        else
							local current_charges = ability:GetCurrentCharges()
                            if current_charges > 1 then
                                ability:SetCurrentCharges(current_charges - 1)
                            else
                                ability:RemoveSelf()
                            end
							_G.kicks[target_player_id] = true
							if _G.tUserIds[target_player_id] then
								SendToServerConsole('kickid '.. _G.tUserIds[target_player_id])
							end
                        end
                    end
                else
                    CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(caster_player_id), "display_custom_error", { message = "#cannotkickotherpatreons" })
                end
            end
        else
            CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(caster_player_id), "display_custom_error", { message = "#nopatreonerror2" })
        end
    end
end
