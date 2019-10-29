function OnSpellStartMute(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability

	local targetId = target:GetPlayerID()

	local event_data =
	{
		mute = true,
		to = targetId,
	}
	CustomGameEventManager:Send_ServerToPlayer(caster:GetPlayerOwner(), "set_mute_refresh", event_data )
	if ability:GetCurrentCharges() > 1 then
		ability:SetCurrentCharges(ability:GetCurrentCharges()-1)
	else
		ability:RemoveSelf()
	end
end