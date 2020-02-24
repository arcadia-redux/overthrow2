patreon_perk_hp_regen_t2 = class({})
--------------------------------------------------------------------------------

function patreon_perk_hp_regen_t2:IsHidden()
	return false
end

--------------------------------------------------------------------------------
function patreon_perk_hp_regen_t2:GetTexture()
	return "perkIcons/patreon_perk_hp_regen_t0"
end

--------------------------------------------------------------------------------
function patreon_perk_hp_regen_t2:IsPurgable()
	return false
end
--------------------------------------------------------------------------------
function patreon_perk_hp_regen_t2:RemoveOnDeath()
	return false
end
--------------------------------------------------------------------------------

function patreon_perk_hp_regen_t2:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
	}
	return funcs
end
--------------------------------------------------------------------------------

function patreon_perk_hp_regen_t2:GetModifierConstantHealthRegen(params)
	return GetPerkValue(1, self, 1, 1)
end

--------------------------------------------------------------------------------
function GetPerkValue(const, modifier, levelCounter, bonusPerLevel)
	local heroLvl = modifier:GetParent():GetLevel()
	return math.floor(heroLvl/levelCounter)*bonusPerLevel+const
end
--------------------------------------------------------------------------------