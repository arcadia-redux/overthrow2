local ABILITY_SETS = {
	{ "devour_speed_aura" },
	{ "devour_cloak_aura" },
	{ "centaur_khan_war_stomp" },
	{ "polar_furbolg_ursa_warrior_thunder_clap", "devour_endurance_aura" },
	{ "mud_golem_hurl_boulder", "mud_golem_rock_destroy" },
	{ "ogre_magi_frost_armor" },
	{ "alpha_wolf_critical_strike", "devour_command_aura" },
	{ "enraged_wildkin_tornado", "devour_toughness_aura" },
	{ "satyr_soulstealer_mana_burn" },
	{ "satyr_hellcaller_shockwave", "devour_unholy_aura" },
	-- { "spawnlord_aura" },
	-- { "spawnlord_master_stomp", "spawnlord_master_freeze" },
	-- { "granite_golem_hp_aura" },
	-- { "big_thunder_lizard_frenzy", "big_thunder_lizard_wardrums_aura", "big_thunder_lizard_slam" },
	{ "gnoll_assassin_envenomed_weapon" },
	{ "ghost_frost_attack" },
	{ "dark_troll_warlord_ensnare", "dark_troll_warlord_raise_dead" },
	{ "satyr_trickster_purge" },
	{ "forest_troll_high_priest_heal", "devour_mana_aura" },
	{ "harpy_storm_chain_lightning" },
	-- { "black_dragon_fireball", "black_dragon_splash_attack", "black_dragon_dragonhide_aura" },
}

doom_bringer_devour_custom = {
	GetIntrinsicModifierName = function() return "modifier_doom_bringer_devour_custom" end,
}

if IsServer() then
	function doom_bringer_devour_custom:OnSpellStart()
		local caster = self:GetCaster()
		for i, v in ipairs({ caster:GetAbilityByIndex(3), caster:GetAbilityByIndex(4) }) do
			local abilityName = v:GetAbilityName()
			if abilityName ~= "doom_bringer_empty" .. i then
				caster:SwapAbilities("doom_bringer_empty" .. i, abilityName, true, false)
				caster:RemoveAbility(abilityName)
			end
		end

		caster:EmitSound("Hero_DoomBringer.Devour")
		ParticleManager:SetParticleControlEnt(
			ParticleManager:CreateParticle("particles/units/heroes/hero_doom_bringer/doom_bringer_devour.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster),
			1,
			caster,
			PATTACH_POINT_FOLLOW,
			"attach_hitloc",
			caster:GetOrigin(),
			true
		)

		if not self.sets or #self.sets == 0 then
			self.sets = table.shuffled(ABILITY_SETS)
		end
		local abilitySet = table.remove(self.sets)
		for i = 1, 2 do
			local abilityName = abilitySet[i]
			local slot = caster:GetAbilityByIndex(3 + i)
			if abilityName then
				local ability = caster:AddAbility(abilityName)
				ability:SetLevel(ability:GetMaxLevel())
				caster:SwapAbilities("doom_bringer_empty" .. i, abilityName, false, true)
			end
		end
	end
end

LinkLuaModifier("modifier_doom_bringer_devour_custom", "abilities/heroes/doom_bringer_devour", LUA_MODIFIER_MOTION_NONE)
modifier_doom_bringer_devour_custom = {
	IsHidden = function() return true end,
	IsPurgable = function() return false end,

	DeclareFunctions = function() return { MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT } end,
	GetModifierConstantHealthRegen = function(self) return self.health_regen end,
}


function modifier_doom_bringer_devour_custom:OnCreated()
	self.gold = 0

	self.ability = self:GetAbility()
	self.parent = self:GetParent()
	self.caster = self:GetCaster()

	self.health_regen = self.ability:GetSpecialValueFor("health_regen")

	if IsServer() then
		self.interval = 1
		self:StartIntervalThink(self.interval)
	end
end

function modifier_doom_bringer_devour_custom:OnIntervalThink()
	if not self.ability or not self.parent or not self.caster then return end
	if self.ability:IsNull() or self.parent:IsNull() or self.caster:IsNull() then return end

	local goldPerMinute = self.ability:GetSpecialValueFor("bonus_gold_per_minute")

	local talent = self.caster:FindAbilityByName("special_bonus_unique_doom_3")

	if talent and not talent:IsNull() and talent:GetLevel() > 0 then
		goldPerMinute = goldPerMinute + 150
	end
	self.gold = self.gold + (goldPerMinute / 60) * self.interval

	local integral, fractional = math.modf(self.gold, 1)
	self.parent:ModifyGold(integral, false, DOTA_ModifyGold_GameTick)
	self.gold = fractional
end

