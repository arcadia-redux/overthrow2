patreon_perk_cd_after_deadth_t0 = class({})
--------------------------------------------------------------------------------
function patreon_perk_cd_after_deadth_t0:IsHidden()
	return false
end
--------------------------------------------------------------------------------
function patreon_perk_cd_after_deadth_t0:GetTexture()
	return "perkIcons/patreon_perk_cd_after_deadth_t0"
end
--------------------------------------------------------------------------------
function patreon_perk_cd_after_deadth_t0:IsPurgable()
	return false
end
--------------------------------------------------------------------------------
function patreon_perk_cd_after_deadth_t0:RemoveOnDeath()
	return false
end
--------------------------------------------------------------------------------
function patreon_perk_cd_after_deadth_t0:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_DEATH
	}
end
--------------------------------------------------------------------------------
function patreon_perk_cd_after_deadth_t0:OnDeath(params)
	if not IsServer() then return end
	local parent = self:GetParent()
	if params.unit == parent then
		if not parent:IsReincarnating() then
			parent.reduceCooldownAfterRespawn = GetPerkValue(25, self, 1, 0)
		else
			parent.reduceCooldownAfterRespawn = false
		end
	end
end
----------------------------------------------------------------------------------
function GetPerkValue(const, modifier, levelCounter, bonusPerLevel)
	local heroLvl = modifier:GetParent():GetLevel()
	return math.floor(heroLvl / levelCounter) * bonusPerLevel + const
end
--------------------------------------------------------------------------------
