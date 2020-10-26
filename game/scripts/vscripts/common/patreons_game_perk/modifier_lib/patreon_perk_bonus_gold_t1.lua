patreon_perk_bonus_gold_t1 = class({})
--------------------------------------------------------------------------------

function patreon_perk_bonus_gold_t1:IsHidden()
	return false
end

--------------------------------------------------------------------------------
function patreon_perk_bonus_gold_t1:GetTexture()
	return "perkIcons/patreon_perk_bonus_gold_t0"
end

--------------------------------------------------------------------------------

function patreon_perk_bonus_gold_t1:IsPurgable()
	return false
end
--------------------------------------------------------------------------------
function patreon_perk_bonus_gold_t1:OnCreated()
	if not IsServer() then return end
	local parent = self:GetParent()
	if not parent:IsRealHero() or parent:IsClone() or parent:IsTempestDouble() then return end
	parent:ModifyGold(GetPerkValue(400, self, 1, 0), true, 0)
end
----------------------------------------------------------------------------------
function patreon_perk_bonus_gold_t1:RemoveOnDeath()
	return false
end
--------------------------------------------------------------------------------
function GetPerkValue(const, modifier, levelCounter, bonusPerLevel)
	local heroLvl = modifier:GetParent():GetLevel()
	return math.floor(heroLvl/levelCounter)*bonusPerLevel+const
end
-----------------------------------------------------------------------------
