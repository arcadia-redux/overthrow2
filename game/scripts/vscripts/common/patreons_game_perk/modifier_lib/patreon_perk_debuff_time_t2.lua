patreon_perk_debuff_time_t2 = class({})
--------------------------------------------------------------------------------

function patreon_perk_debuff_time_t2:IsHidden()
	return false
end

--------------------------------------------------------------------------------
function patreon_perk_debuff_time_t2:GetTexture()
	return "perkIcons/patreon_perk_debuff_time_t0"
end

--------------------------------------------------------------------------------
function patreon_perk_debuff_time_t2:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATUS_RESISTANCE_CASTER
	}
end
--------------------------------------------------------------------------------
function patreon_perk_debuff_time_t2:IsPurgable()
	return false
end
--------------------------------------------------------------------------------
function patreon_perk_debuff_time_t2:OnCreated()
	self.bonusDebuffTime = GetPerkValue(100, self, 1, 0)
end
----------------------------------------------------------------------------------
function patreon_perk_debuff_time_t2:RemoveOnDeath()
	return false
end
--------------------------------------------------------------------------------
function patreon_perk_debuff_time_t2:GetModifierStatusResistanceCaster()
	return -self.bonusDebuffTime
end
--------------------------------------------------------------------------------
function GetPerkValue(const, modifier, levelCounter, bonusPerLevel)
	local heroLvl = modifier:GetParent():GetLevel()
	return math.floor(heroLvl/levelCounter)*bonusPerLevel+const
end
--------------------------------------------------------------------------------
