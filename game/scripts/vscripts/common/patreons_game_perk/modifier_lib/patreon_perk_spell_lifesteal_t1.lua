patreon_perk_spell_lifesteal_t1 = class({})
--------------------------------------------------------------------------------

function patreon_perk_spell_lifesteal_t1:IsHidden()
	return false
end

--------------------------------------------------------------------------------
function patreon_perk_spell_lifesteal_t1:GetTexture()
	return "perkIcons/patreon_perk_spell_lifesteal_t0"
end

--------------------------------------------------------------------------------
function patreon_perk_spell_lifesteal_t1:IsPurgable()
	return false
end
--------------------------------------------------------------------------------
function patreon_perk_spell_lifesteal_t1:RemoveOnDeath()
	return false
end
--------------------------------------------------------------------------------

function patreon_perk_spell_lifesteal_t1:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
	return funcs
end
--------------------------------------------------------------------------------

function patreon_perk_spell_lifesteal_t1:OnTakeDamage(params)
	if self:GetParent() ~= params.attacker then return end
	if params.damage <= 0 then return end
	if params.infilctor or DOTA_DAMAGE_CATEGORY_ATTACK == params.damage_category then return end
	local lifestealPct = GetPerkValue(4, self, 1, 0)
	local attacker = params.attacker
	local steal = math.max(1, params.damage * (lifestealPct/100))
	attacker:Heal(steal, self)
	local particle = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_OVERHEAD_FOLLOW, params.attacker)
	ParticleManager:SetParticleControl(particle, 0, params.attacker:GetAbsOrigin())
	SendOverheadEventMessage(params.unit, OVERHEAD_ALERT_HEAL, params.attacker, steal, nil)
end

-------------------------------------------------------------------------------
function GetPerkValue(const, modifier, levelCounter, bonusPerLevel)
	local heroLvl = modifier:GetParent():GetLevel()
	return math.floor(heroLvl/levelCounter)*bonusPerLevel+const
end
--------------------------------------------------------------------------------
