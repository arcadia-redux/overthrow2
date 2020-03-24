patreon_perk_cast_range_t0 = class({})
--------------------------------------------------------------------------------

function patreon_perk_cast_range_t0:IsHidden()
	return false
end

--------------------------------------------------------------------------------
function patreon_perk_cast_range_t0:GetTexture()
	return "perkIcons/patreon_perk_cast_range_t0"
end

--------------------------------------------------------------------------------
function patreon_perk_cast_range_t0:IsPurgable()
	return false
end
--------------------------------------------------------------------------------
function patreon_perk_cast_range_t0:RemoveOnDeath()
	return false
end
--------------------------------------------------------------------------------

function patreon_perk_cast_range_t0:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_CAST_RANGE_BONUS,
	}
	return funcs
end
--------------------------------------------------------------------------------

function patreon_perk_cast_range_t0:GetModifierCastRangeBonus(params)
	return GetPerkValue(50, self, 1, 0)
end

--------------------------------------------------------------------------------
function GetPerkValue(const, modifier, levelCounter, bonusPerLevel)
	local heroLvl = modifier:GetParent():GetLevel()
	return math.floor(heroLvl/levelCounter)*bonusPerLevel+const
end
--------------------------------------------------------------------------------