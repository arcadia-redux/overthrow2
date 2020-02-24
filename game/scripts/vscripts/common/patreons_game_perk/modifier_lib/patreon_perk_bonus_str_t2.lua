patreon_perk_bonus_str_t2 = class({})
--------------------------------------------------------------------------------

function patreon_perk_bonus_str_t2:IsHidden()
	return false
end

--------------------------------------------------------------------------------
function patreon_perk_bonus_str_t2:GetTexture()
	return "perkIcons/patreon_perk_bonus_str_t0"
end

--------------------------------------------------------------------------------
function patreon_perk_bonus_str_t2:IsPurgable()
	return false
end
--------------------------------------------------------------------------------
function patreon_perk_bonus_str_t2:RemoveOnDeath()
	return false
end
--------------------------------------------------------------------------------

function patreon_perk_bonus_str_t2:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
	}
	return funcs
end
--------------------------------------------------------------------------------

function patreon_perk_bonus_str_t2:GetModifierBonusStats_Strength(params)
	return GetPerkValue(0, self, 1, 2)
end

--------------------------------------------------------------------------------
function GetPerkValue(const, modifier, levelCounter, bonusPerLevel)
	local heroLvl = modifier:GetParent():GetLevel()
	return math.floor(heroLvl/levelCounter)*bonusPerLevel+const
end
--------------------------------------------------------------------------------