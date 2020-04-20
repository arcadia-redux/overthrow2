patreon_perk_cast_range_t2 = class({})
--------------------------------------------------------------------------------

function patreon_perk_cast_range_t2:IsHidden()
	return false
end

--------------------------------------------------------------------------------
function patreon_perk_cast_range_t2:GetTexture()
	return "perkIcons/patreon_perk_cast_range_t0"
end

--------------------------------------------------------------------------------
function patreon_perk_cast_range_t2:IsPurgable()
	return false
end
--------------------------------------------------------------------------------
function patreon_perk_cast_range_t2:RemoveOnDeath()
	return false
end
--------------------------------------------------------------------------------

function patreon_perk_cast_range_t2:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_CAST_RANGE_BONUS_STACKING,
	}
	return funcs
end
--------------------------------------------------------------------------------

function patreon_perk_cast_range_t2:GetModifierCastRangeBonusStacking(params)
	return GetPerkValue(200, self, 1, 0)
end

--------------------------------------------------------------------------------
function GetPerkValue(const, modifier, levelCounter, bonusPerLevel)
	local heroLvl = modifier:GetParent():GetLevel()
	return math.floor(heroLvl/levelCounter)*bonusPerLevel+const
end
--------------------------------------------------------------------------------