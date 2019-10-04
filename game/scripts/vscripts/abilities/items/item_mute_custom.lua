item_mute_custom = item_mute_custom or class({})

--------------------------------------------------------------------------------

function item_mute_custom:OnSpellStart()
	local target = self:GetCursorTarget()
	local caster = self:GetCaster()

	local targetId = target:GetPlayerID()

	local event_data =
	{
		mute = true,
		to = targetId,
	}
	CustomGameEventManager:Send_ServerToPlayer(caster:GetPlayerOwner(), "set_mute_refresh", event_data )

end
