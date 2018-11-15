modifier_core_spawn_movespeed = {
	GetTexture = function() return "item_boots" end,
	GetModifierMoveSpeedBonus_Constant = function() return 200 end,
	DeclareFunctions = function()
		return {
			MODIFIER_EVENT_ON_UNIT_MOVED,
			MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
		}
	end,
}

if IsServer() then
	function modifier_core_spawn_movespeed:OnUnitMoved(keys)
		local unit = keys.unit
		if unit ~= self:GetParent() then return end
		if self:GetDuration() == -1 then
			self:SetDuration(10, true)
		end
	end
end
