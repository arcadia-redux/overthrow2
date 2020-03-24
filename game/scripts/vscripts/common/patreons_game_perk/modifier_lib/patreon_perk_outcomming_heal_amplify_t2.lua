patreon_perk_outcomming_heal_amplify_t2 = class({})
--------------------------------------------------------------------------------

function patreon_perk_outcomming_heal_amplify_t2:IsHidden()
	return false
end

--------------------------------------------------------------------------------
function patreon_perk_outcomming_heal_amplify_t2:GetTexture()
	return "perkIcons/patreon_perk_outcomming_heal_amplify_t0"
end

--------------------------------------------------------------------------------
function patreon_perk_outcomming_heal_amplify_t2:IsPurgable()
	return false
end
--------------------------------------------------------------------------------
function patreon_perk_outcomming_heal_amplify_t2:RemoveOnDeath()
	return false
end
--------------------------------------------------------------------------------

function patreon_perk_outcomming_heal_amplify_t2:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
	}
	return funcs
end
--------------------------------------------------------------------------------

function patreon_perk_outcomming_heal_amplify_t2:GetModifierHealAmplify_PercentageSource()
	return GetPerkValue(28, self, 1, 0)
end

--------------------------------------------------------------------------------
function GetPerkValue(const, modifier, levelCounter, bonusPerLevel)
	local heroLvl = modifier:GetParent():GetLevel()
	return math.floor(heroLvl/levelCounter)*bonusPerLevel+const
end
--------------------------------------------------------------------------------