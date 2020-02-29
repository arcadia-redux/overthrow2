patreon_perk_gpm_t1 = class({})
--------------------------------------------------------------------------------

function patreon_perk_gpm_t1:IsHidden()
	return false
end

--------------------------------------------------------------------------------
function patreon_perk_gpm_t1:GetTexture()
	return "perkIcons/patreon_perk_gpm_t0"
end

--------------------------------------------------------------------------------

function patreon_perk_gpm_t1:IsPurgable()
	return false
end
--------------------------------------------------------------------------------
function patreon_perk_gpm_t1:OnCreated()
	self:GetParent().bonusGpmForPerkPerMinute = GetPerkValue(100, self, 1, 0)
end
----------------------------------------------------------------------------------
function patreon_perk_gpm_t1:RemoveOnDeath()
	return false
end
--------------------------------------------------------------------------------
function GetPerkValue(const, modifier, levelCounter, bonusPerLevel)
	local heroLvl = modifier:GetParent():GetLevel()
	return math.floor(heroLvl/levelCounter)*bonusPerLevel+const
end
--------------------------------------------------------------------------------