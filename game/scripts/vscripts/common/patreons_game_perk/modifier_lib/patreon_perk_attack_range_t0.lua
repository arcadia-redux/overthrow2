patreon_perk_attack_range_t0 = class({})
--------------------------------------------------------------------------------

function patreon_perk_attack_range_t0:IsHidden()
	return false
end

--------------------------------------------------------------------------------
function patreon_perk_attack_range_t0:GetTexture()
	return "perkIcons/patreon_perk_attack_range_t0"
end

--------------------------------------------------------------------------------

function patreon_perk_attack_range_t0:IsPurgable()
	return false
end
--------------------------------------------------------------------------------
function patreon_perk_attack_range_t0:RemoveOnDeath()
	return false
end
--------------------------------------------------------------------------------

function patreon_perk_attack_range_t0:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
	}
	return funcs
end
--------------------------------------------------------------------------------

function patreon_perk_attack_range_t0:GetModifierAttackRangeBonus()
	if self:GetParent():IsRangedAttacker() then
		return GetPerkValue(35, self, 1, 0)
	else
		return GetPerkValue(15, self, 1, 0)
	end
end


--------------------------------------------------------------------------------
function GetPerkValue(const, modifier, levelCounter, bonusPerLevel)
	local heroLvl = modifier:GetParent():GetLevel()
	return math.floor(heroLvl/levelCounter)*bonusPerLevel+const
end
--------------------------------------------------------------------------------