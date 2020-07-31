patreon_perk_bonus_gold_t2 = class({})
--------------------------------------------------------------------------------

function patreon_perk_bonus_gold_t2:IsHidden()
	return false
end

--------------------------------------------------------------------------------
function patreon_perk_bonus_gold_t2:GetTexture()
	return "perkIcons/patreon_perk_bonus_gold_t0"
end

--------------------------------------------------------------------------------

function patreon_perk_bonus_gold_t2:IsPurgable()
	return false
end
--------------------------------------------------------------------------------
function patreon_perk_bonus_gold_t2:OnCreated()
	if not IsServer() then return end
	self:GetParent():ModifyGold(GetPerkValue(800, self, 1, 0), true, 0)
end
----------------------------------------------------------------------------------
function patreon_perk_bonus_gold_t2:RemoveOnDeath()
	return false
end
--------------------------------------------------------------------------------
function GetPerkValue(const, modifier, levelCounter, bonusPerLevel)
	local heroLvl = modifier:GetParent():GetLevel()
	return math.floor(heroLvl/levelCounter)*bonusPerLevel+const
end
-----------------------------------------------------------------------------