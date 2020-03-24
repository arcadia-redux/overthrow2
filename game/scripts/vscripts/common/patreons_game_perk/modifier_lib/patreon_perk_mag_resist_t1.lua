patreon_perk_mag_resist_t1 = class({})
--------------------------------------------------------------------------------

function patreon_perk_mag_resist_t1:IsHidden()
	return false
end

--------------------------------------------------------------------------------
function patreon_perk_mag_resist_t1:GetTexture()
	return "perkIcons/patreon_perk_mag_resist_t0"
end

--------------------------------------------------------------------------------
function patreon_perk_mag_resist_t1:IsPurgable()
	return false
end
--------------------------------------------------------------------------------
function patreon_perk_mag_resist_t1:RemoveOnDeath()
	return false
end
--------------------------------------------------------------------------------

function patreon_perk_mag_resist_t1:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	}
	return funcs
end
--------------------------------------------------------------------------------

function patreon_perk_mag_resist_t1:GetModifierMagicalResistanceBonus(params)
	return GetPerkValue(10, self, 1, 0)
end

--------------------------------------------------------------------------------
function GetPerkValue(const, modifier, levelCounter, bonusPerLevel)
	local heroLvl = modifier:GetParent():GetLevel()
	return math.floor(heroLvl/levelCounter)*bonusPerLevel+const
end
--------------------------------------------------------------------------------