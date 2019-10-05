function OnSpellStartDisableHelp(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability

	local targetId = target:GetPlayerID()
	local casterId = caster:GetPlayerID()

	local to = targetId;
	if PlayerResource:IsValidPlayerID(to) then
		local disable = true
		PlayerResource:SetUnitShareMaskForPlayer(casterId, to, 4, disable)

		local disableHelp = CustomNetTables:GetTableValue("disable_help", tostring(casterId)) or {}
		disableHelp[tostring(to)] = disable
		CustomNetTables:SetTableValue("disable_help", tostring(casterId), disableHelp)
		CustomGameEventManager:Send_ServerToAllClients( "set_disable_help_refresh", {} )
	end
	if ability:GetCurrentCharges() > 1 then
		ability:SetCurrentCharges(ability:GetCurrentCharges()-1)
	else
		ability:RemoveSelf()
	end
end
