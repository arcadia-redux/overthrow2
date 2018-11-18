modifier_core_courier = {
	IsHidden = function() return true end,
	IsPurgable = function() return false end,
	RemoveOnDeath = function() return false end,

	DeclareFunctions = function()
		return {
			MODIFIER_PROPERTY_MOVESPEED_MAX,
			MODIFIER_PROPERTY_MOVESPEED_LIMIT,
			MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
			MODIFIER_PROPERTY_FIXED_DAY_VISION,
			MODIFIER_PROPERTY_FIXED_NIGHT_VISION,
		}
	end,
	GetModifierMoveSpeed_Max = function() return 2500 end,
	GetModifierMoveSpeed_Limit = function() return 2500 end,
	GetModifierMoveSpeed_Absolute = function() return 2500 end,
	GetFixedDayVision = function() return 150 end,
	GetFixedNightVision = function() return 150 end,

	CheckState = function()
		return {
			[MODIFIER_STATE_NO_HEALTH_BAR] = true,
			[MODIFIER_STATE_INVULNERABLE] = true,
		}
	end,
}
