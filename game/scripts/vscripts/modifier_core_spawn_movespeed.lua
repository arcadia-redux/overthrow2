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

			local xpGranterAbility
			for _, unit in ipairs(Entities:FindAllByClassname("npc_dota_creature")) do
				if unit:GetUnitName():starts("npc_dota_xp_granter") then
					xpGranterAbility = unit:GetAbilityByIndex(0)
					break
				end
			end

			if xpGranterAbility then
				unit:AddNewModifier(self:GetCaster(), xpGranterAbility, "modifier_get_xp", { duration = 10 })
			end
		end
	end
end
