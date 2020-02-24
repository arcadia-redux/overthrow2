patreon_perk_spell_amp_t1 = class({})
--------------------------------------------------------------------------------

function patreon_perk_spell_amp_t1:IsHidden()
	return false
end

--------------------------------------------------------------------------------
function patreon_perk_spell_amp_t1:GetTexture()
	return "perkIcons/patreon_perk_spell_amp_t0"
end

--------------------------------------------------------------------------------
function patreon_perk_spell_amp_t1:IsPurgable()
	return false
end
--------------------------------------------------------------------------------
function patreon_perk_spell_amp_t1:RemoveOnDeath()
	return false
end
--------------------------------------------------------------------------------

function patreon_perk_spell_amp_t1:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
	}
	return funcs
end
--------------------------------------------------------------------------------

function patreon_perk_spell_amp_t1:GetModifierSpellAmplify_Percentage(params)
	return GetPerkValue(10, self, 1, 0)
end

--------------------------------------------------------------------------------
function GetPerkValue(const, modifier, levelCounter, bonusPerLevel)
	local heroLvl = modifier:GetParent():GetLevel()
	return math.floor(heroLvl/levelCounter)*bonusPerLevel+const
end
--------------------------------------------------------------------------------