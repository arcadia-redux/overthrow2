local ABILITY_SETS = {
	{ "kobold_taskmaster_speed_aura" },
	{ "mudgolem_cloak_aura" },
	{ "centaur_khan_war_stomp" },
	{ "polar_furbolg_ursa_warrior_thunder_clap", "centaur_khan_endurance_aura" },
	{ "mud_golem_hurl_boulder", "mud_golem_rock_destroy" },
	{ "ogre_magi_frost_armor" },
	{ "alpha_wolf_critical_strike", "alpha_wolf_command_aura" },
	{ "enraged_wildkin_tornado", "enraged_wildkin_toughness_aura" },
	{ "satyr_soulstealer_mana_burn" },
	{ "satyr_hellcaller_shockwave", "satyr_hellcaller_unholy_aura" },
	-- { "spawnlord_aura" },
	-- { "spawnlord_master_stomp", "spawnlord_master_freeze" },
	-- { "granite_golem_hp_aura" },
	-- { "big_thunder_lizard_frenzy", "big_thunder_lizard_wardrums_aura", "big_thunder_lizard_slam" },
	{ "gnoll_assassin_envenomed_weapon" },
	{ "ghost_frost_attack" },
	{ "dark_troll_warlord_ensnare", "dark_troll_warlord_raise_dead" },
	{ "satyr_trickster_purge" },
	{ "forest_troll_high_priest_heal", "forest_troll_high_priest_mana_aura" },
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
			self.sets = ShuffledList(ABILITY_SETS)
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
	GetModifierConstantHealthRegen = function(self) return self:GetAbility():GetSpecialValueFor("health_regen") end,
}

if IsServer() then
	local interval = 1
	function modifier_doom_bringer_devour_custom:OnCreated()
		self.gold = 0
		self:StartIntervalThink(interval)
	end

	function modifier_doom_bringer_devour_custom:OnIntervalThink()
		local goldPerMinute = self:GetAbility():GetSpecialValueFor("bonus_gold_per_minute")
		if self:GetCaster():FindAbilityByName("special_bonus_unique_doom_3"):GetLevel() > 0 then
			goldPerMinute = goldPerMinute + 150
		end
		self.gold = self.gold + (goldPerMinute / 60) * interval

		local integral, fractional = math.modf(self.gold, 1)
		self:GetParent():ModifyGold(integral, false, DOTA_ModifyGold_GameTick)
		self.gold = fractional
	end
end
