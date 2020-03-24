patreon_perk_bonus_hp_pct_t0 = class({})
--------------------------------------------------------------------------------

function patreon_perk_bonus_hp_pct_t0:IsHidden()
	return false
end

--------------------------------------------------------------------------------
function patreon_perk_bonus_hp_pct_t0:GetTexture()
	return "perkIcons/patreon_perk_bonus_hp_pct_t0"
end

--------------------------------------------------------------------------------
function patreon_perk_bonus_hp_pct_t0:IsPurgable()
	return false
end
--------------------------------------------------------------------------------
function patreon_perk_bonus_hp_pct_t0:RemoveOnDeath()
	return false
end
--------------------------------------------------------------------------------

function patreon_perk_bonus_hp_pct_t0:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_EXTRA_HEALTH_PERCENTAGE,
	}
	return funcs
end
--------------------------------------------------------------------------------

function patreon_perk_bonus_hp_pct_t0:GetModifierExtraHealthPercentage(params)
	return GetPerkValue(6, self, 1, 0)
end

--------------------------------------------------------------------------------
function GetPerkValue(const, modifier, levelCounter, bonusPerLevel)
	local heroLvl = modifier:GetParent():GetLevel()
	return math.floor(heroLvl/levelCounter)*bonusPerLevel+const
end
--------------------------------------------------------------------------------