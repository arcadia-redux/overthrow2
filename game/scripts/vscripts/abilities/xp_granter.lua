dota_ability_xp_granter = {
	GetIntrinsicModifierName = function() return "modifier_dota_ability_xp_granter" end
}

dota_ability_xp_granter2 = {
	GetIntrinsicModifierName = function() return "modifier_dota_ability_xp_granter" end
}


LinkLuaModifier("modifier_dota_ability_xp_granter", "abilities/xp_granter", LUA_MODIFIER_MOTION_NONE)
modifier_dota_ability_xp_granter = {
	IsHidden = function() return true end,
	IsAura = function() return true end,
	GetModifierAura    = function() return "modifier_get_xp" end,
	GetAuraRadius = function(self) return self:GetAbility():GetSpecialValueFor("aura_radius") end,
	GetAuraDuration    = function() return 0.2 end,
	GetAuraSearchTeam = function() return DOTA_UNIT_TARGET_TEAM_BOTH end,
	GetAuraSearchType = function() return DOTA_UNIT_TARGET_HERO end,
	GetAuraSearchFlags = function() return DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS end,
}

function modifier_dota_ability_xp_granter:CheckState()
	return {
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_OUT_OF_GAME] = true,
	}
end


LinkLuaModifier("modifier_get_xp", "abilities/xp_granter", LUA_MODIFIER_MOTION_NONE)
modifier_get_xp = {
	IsDebuff = function() return false end,
	GetTexture = function() return "custom_games_xp_coin" end
}

if IsServer() then
	function modifier_get_xp:OnCreated()
		self:StartIntervalThink(0.5)
	end

	function modifier_get_xp:OnIntervalThink()
		local parent = self:GetParent()
		local ability = self:GetAbility()

		local xp = ability:GetSpecialValueFor("aura_xp")
		local gold = ability:GetSpecialValueFor("aura_gold")
		parent:ModifyGold(gold, false, 0)
		parent:AddExperience(xp, 0, false, false)
	end
end
