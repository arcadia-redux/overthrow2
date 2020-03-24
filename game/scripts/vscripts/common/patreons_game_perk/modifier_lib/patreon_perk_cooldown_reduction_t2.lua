patreon_perk_cooldown_reduction_t2 = class({})
--------------------------------------------------------------------------------

function patreon_perk_cooldown_reduction_t2:IsHidden()
	return false
end

--------------------------------------------------------------------------------
function patreon_perk_cooldown_reduction_t2:GetTexture()
	return "perkIcons/patreon_perk_cooldown_reduction_t0"
end

--------------------------------------------------------------------------------
function patreon_perk_cooldown_reduction_t2:IsPurgable()
	return false
end
--------------------------------------------------------------------------------
function patreon_perk_cooldown_reduction_t2:RemoveOnDeath()
	return false
end
--------------------------------------------------------------------------------

function patreon_perk_cooldown_reduction_t2:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
	}
	return funcs
end
--------------------------------------------------------------------------------

function patreon_perk_cooldown_reduction_t2:GetModifierPercentageCooldown(params)
	return GetPerkValue(16, self, 1, 0)
end

--------------------------------------------------------------------------------
function GetPerkValue(const, modifier, levelCounter, bonusPerLevel)
	local heroLvl = modifier:GetParent():GetLevel()
	return math.floor(heroLvl/levelCounter)*bonusPerLevel+const
end
--------------------------------------------------------------------------------