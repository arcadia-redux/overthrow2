patreon_perk_damage_t2 = class({})
--------------------------------------------------------------------------------
function patreon_perk_damage_t2:IsHidden()
	return false
end
--------------------------------------------------------------------------------
function patreon_perk_damage_t2:GetTexture()
	return "perkIcons/patreon_perk_damage_t0"
end
--------------------------------------------------------------------------------
function patreon_perk_damage_t2:IsPurgable()
	return false
end
--------------------------------------------------------------------------------
function patreon_perk_damage_t2:RemoveOnDeath()
	return false
end
--------------------------------------------------------------------------------
function patreon_perk_damage_t2:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	}
	return funcs
end
--------------------------------------------------------------------------------
function patreon_perk_damage_t2:GetModifierPreAttack_BonusDamage(params)
	return GetPerkValue(20, self, 1, 2)
end
--------------------------------------------------------------------------------
function GetPerkValue(const, modifier, levelCounter, bonusPerLevel)
	local heroLvl = modifier:GetParent():GetLevel()
	return math.floor(heroLvl/levelCounter)*bonusPerLevel+const
end
--------------------------------------------------------------------------------
