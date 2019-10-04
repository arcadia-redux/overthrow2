item_disable_help_custom = item_disable_help_custom or class({})

--------------------------------------------------------------------------------

function item_disable_help_custom:OnSpellStart()
	local target = self:GetCursorTarget()
	local targetId = target:GetPlayerID()
	local casterId = self:GetCaster():GetPlayerID()



	local to = targetId;
	if PlayerResource:IsValidPlayerID(to) then
		local disable = true
		PlayerResource:SetUnitShareMaskForPlayer(casterId, to, 4, disable)

		local disableHelp = CustomNetTables:GetTableValue("disable_help", tostring(casterId)) or {}
		disableHelp[tostring(to)] = disable
		CustomNetTables:SetTableValue("disable_help", tostring(casterId), disableHelp)
		CustomGameEventManager:Send_ServerToAllClients( "set_disable_help_refresh", {} )
	end
end
