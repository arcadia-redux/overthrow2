modifier_core_pumpkin_regeneration = {
	GetTexture = function() return "rune_regen" end,

	DeclareFunctions = function()
		return {
			MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
			MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE,
		}
	end,
	GetModifierHealthRegenPercentage = function() return 5 end,
	GetModifierTotalPercentageManaRegen = function() return 5 end,
	GetEffectName = function() return "particles/custom/items/core_pumpkin_owner.vpcf" end,
}
