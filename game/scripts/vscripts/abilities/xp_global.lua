dota_ability_xp_global = {
	GetIntrinsicModifierName = function() return "modifier_dota_ability_xp_global" end
}


LinkLuaModifier("modifier_dota_ability_xp_global", "abilities/xp_global", LUA_MODIFIER_MOTION_NONE)
modifier_dota_ability_xp_global = {
	IsHidden = function() return true end,
	IsAura = function() return true end,
	GetModifierAura = function() return "modifier_get_xp_global" end,
	GetAuraRadius = function() return FIND_UNITS_EVERYWHERE end,
	GetAuraSearchTeam = function() return DOTA_UNIT_TARGET_TEAM_BOTH end,
	GetAuraSearchType = function() return DOTA_UNIT_TARGET_HERO end,
	GetAuraSearchFlags = function() return DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS end,
}

function modifier_dota_ability_xp_global:GetAuraEntityReject(entity)
	return entity:HasModifier("modifier_fountain_aura_effect_lua") and not entity:HasModifier("modifier_get_xp_late_bonus")
end

function modifier_dota_ability_xp_global:CheckState()
	return {
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_OUT_OF_GAME] = true,
	}
end


LinkLuaModifier("modifier_get_xp_global", "abilities/xp_global", LUA_MODIFIER_MOTION_NONE)
modifier_get_xp_global = {
	IsDebuff = function() return false end,
  GetTexture = function() return "alchemist_goblins_greed" end,
	GetEffectName = function() return "particles/econ/courier/courier_greevil_yellow/courier_greevil_yellow_ambient_3_b.vpcf" end,
}

if IsServer() then
	function modifier_get_xp_global:OnCreated()
		self:StartIntervalThink(0.5)
	end

	function modifier_get_xp_global:OnIntervalThink()
		local parent = self:GetParent()
		local ability = self:GetAbility()

		local xp = ability:GetSpecialValueFor("aura_xp")
		local gold = ability:GetSpecialValueFor("aura_gold")
		parent:ModifyGold(gold, false, 0)
		parent:AddExperience(xp, 0, false, false)
	end
end
