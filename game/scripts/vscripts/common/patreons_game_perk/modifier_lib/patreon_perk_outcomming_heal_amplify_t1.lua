patreon_perk_outcomming_heal_amplify_t1 = class({})
--------------------------------------------------------------------------------

function patreon_perk_outcomming_heal_amplify_t1:IsHidden()
	return false
end

--------------------------------------------------------------------------------
function patreon_perk_outcomming_heal_amplify_t1:GetTexture()
	return "perkIcons/patreon_perk_outcomming_heal_amplify_t0"
end

--------------------------------------------------------------------------------
function patreon_perk_outcomming_heal_amplify_t1:IsPurgable()
	return false
end
--------------------------------------------------------------------------------
function patreon_perk_outcomming_heal_amplify_t1:RemoveOnDeath()
	return false
end
--------------------------------------------------------------------------------

function patreon_perk_outcomming_heal_amplify_t1:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
	}
	return funcs
end
--------------------------------------------------------------------------------

function patreon_perk_outcomming_heal_amplify_t1:GetModifierHealAmplify_PercentageSource()
	return GetPerkValue(14, self, 1, 0)
end

--------------------------------------------------------------------------------
function GetPerkValue(const, modifier, levelCounter, bonusPerLevel)
	local heroLvl = modifier:GetParent():GetLevel()
	return math.floor(heroLvl/levelCounter)*bonusPerLevel+const
end
--------------------------------------------------------------------------------