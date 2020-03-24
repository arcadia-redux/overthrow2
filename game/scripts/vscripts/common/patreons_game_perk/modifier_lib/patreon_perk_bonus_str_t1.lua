patreon_perk_bonus_str_t1 = class({})
--------------------------------------------------------------------------------

function patreon_perk_bonus_str_t1:IsHidden()
	return false
end

--------------------------------------------------------------------------------
function patreon_perk_bonus_str_t1:GetTexture()
	return "perkIcons/patreon_perk_bonus_str_t0"
end

--------------------------------------------------------------------------------
function patreon_perk_bonus_str_t1:IsPurgable()
	return false
end
--------------------------------------------------------------------------------
function patreon_perk_bonus_str_t1:RemoveOnDeath()
	return false
end
--------------------------------------------------------------------------------

function patreon_perk_bonus_str_t1:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
	}
	return funcs
end
--------------------------------------------------------------------------------

function patreon_perk_bonus_str_t1:GetModifierBonusStats_Strength(params)
	return GetPerkValue(0, self, 1, 1)
end

--------------------------------------------------------------------------------
function GetPerkValue(const, modifier, levelCounter, bonusPerLevel)
	local heroLvl = modifier:GetParent():GetLevel()
	return math.floor(heroLvl/levelCounter)*bonusPerLevel+const
end
--------------------------------------------------------------------------------