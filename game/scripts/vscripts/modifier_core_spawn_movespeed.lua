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
	function modifier_core_spawn_movespeed:OnCreated(keys)
		self.xp = keys.xp == 1
	end

	function modifier_core_spawn_movespeed:OnUnitMoved(keys)
		local unit = keys.unit
		if unit ~= self:GetParent() then return end
		if self:GetDuration() == -1 then
			self:SetDuration(10, true)

			if self.xp then
				local xpGranterAbility
				for _, v in ipairs(Entities:FindAllByClassname("npc_dota_creature")) do
					if v:GetUnitName():starts("npc_dota_xp_granter") then
						xpGranterAbility = v:GetAbilityByIndex(0)
						break
					end
				end
				--if xpGranterAbility then
					--unit:AddNewModifier(unit, xpGranterAbility, "modifier_get_xp", { duration = 10 })
				--end
			end
		end
	end
end
