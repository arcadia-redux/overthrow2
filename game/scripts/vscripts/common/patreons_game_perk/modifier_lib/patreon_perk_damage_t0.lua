patreon_perk_damage_t0 = class({})
--------------------------------------------------------------------------------

function patreon_perk_damage_t0:IsHidden()
	return false
end

--------------------------------------------------------------------------------
function patreon_perk_damage_t0:GetTexture()
	return "perkIcons/patreon_perk_damage_t0"
end

--------------------------------------------------------------------------------
function patreon_perk_damage_t0:IsPurgable()
	return false
end
--------------------------------------------------------------------------------

function patreon_perk_damage_t0:RemoveOnDeath()
	return false
end
--------------------------------------------------------------------------------

function patreon_perk_damage_t0:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	}
	return funcs
end
--------------------------------------------------------------------------------

function patreon_perk_damage_t0:GetModifierPreAttack_BonusDamage(params)
	return GetPerkValue(5, self, 1, 0.5)
end

--------------------------------------------------------------------------------
function GetPerkValue(const, modifier, levelCounter, bonusPerLevel)
	local heroLvl = modifier:GetParent():GetLevel()
	return math.floor(heroLvl/levelCounter)*bonusPerLevel+const
end
--------------------------------------------------------------------------------