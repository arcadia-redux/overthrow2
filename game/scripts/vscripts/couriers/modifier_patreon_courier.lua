modifier_patreon_courier = {
	IsHidden = function() return true end,
	IsPurgable = function() return false end,
	RemoveOnDeath = function() return false end,

	GetModifierMoveSpeed_Max = function() return 400 end,
	GetModifierMoveSpeed_Absolute = function() return 400 end,
	GetFixedDayVision = function() return 150 end,
	GetFixedNightVision = function() return 150 end,

	CheckState = function()
		return {
			[MODIFIER_STATE_NO_HEALTH_BAR] = true,
			[MODIFIER_STATE_INVULNERABLE] = true,
		}
	end,
}

function modifier_patreon_courier:GetModifierModelChange()
	return "models/items/juggernaut/ward/fortunes_tout/fortunes_tout.vmdl"
end

function modifier_patreon_courier:OnModelChanged()
	Timers:CreateTimer(.2, function()
		local parent = self:GetParent()
		parent:SetModel("models/items/juggernaut/ward/fortunes_tout/fortunes_tout.vmdl")
		parent:SetOriginalModel("models/items/juggernaut/ward/fortunes_tout/fortunes_tout.vmdl")
	end)
end

function modifier_patreon_courier:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MODEL_CHANGE,
		MODIFIER_EVENT_ON_MODEL_CHANGED,
		MODIFIER_PROPERTY_MOVESPEED_MAX,
		MODIFIER_PROPERTY_MOVESPEED_LIMIT,
		MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
		MODIFIER_PROPERTY_FIXED_DAY_VISION,
		MODIFIER_PROPERTY_FIXED_NIGHT_VISION,
	}
end