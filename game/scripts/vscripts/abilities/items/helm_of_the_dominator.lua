local JUNGLE_UNITS = {
	--"npc_dota_neutral_kobold",
	--"npc_dota_neutral_kobold_tunneler",
	"npc_dota_neutral_kobold_taskmaster",
	--"npc_dota_neutral_centaur_outrunner",
	"npc_dota_neutral_centaur_khan",
	--"npc_dota_neutral_fel_beast",
	"npc_dota_neutral_polar_furbolg_champion",
	"npc_dota_neutral_polar_furbolg_ursa_warrior",
	"npc_dota_neutral_mud_golem",
	--"npc_dota_neutral_mud_golem_split",
	--"npc_dota_neutral_mud_golem_split_doom",
	--"npc_dota_neutral_ogre_mauler",
	"npc_dota_neutral_ogre_magi",
	--"npc_dota_neutral_giant_wolf",
	"npc_dota_neutral_alpha_wolf",
	--"npc_dota_neutral_wildkin",
	"npc_dota_neutral_enraged_wildkin",
	"npc_dota_neutral_satyr_soulstealer",
	"npc_dota_neutral_satyr_hellcaller",
	--"npc_dota_neutral_jungle_stalker",
	--"npc_dota_neutral_prowler_acolyte",
	--"npc_dota_neutral_prowler_shaman",
	--"npc_dota_neutral_rock_golem",
	--"npc_dota_neutral_granite_golem",
	--"npc_dota_neutral_big_thunder_lizard",
	--"npc_dota_neutral_small_thunder_lizard",
	"npc_dota_neutral_gnoll_assassin",
	"npc_dota_neutral_ghost",
	--"npc_dota_neutral_dark_troll",
	"npc_dota_neutral_dark_troll_warlord",
	"npc_dota_neutral_satyr_trickster",
	--"npc_dota_neutral_forest_troll_berserker",
	"npc_dota_neutral_forest_troll_high_priest",
	--"npc_dota_neutral_harpy_scout",
	"npc_dota_neutral_harpy_storm",
	--"npc_dota_neutral_black_drake",
	--"npc_dota_neutral_black_dragon",
}


item_helm_of_the_dominator_custom = {
	GetIntrinsicModifierName = function() return "modifier_item_helm_of_the_dominator_custom" end
}

if IsServer() then
	function item_helm_of_the_dominator_custom:OnSpellStart()
		local caster = self:GetCaster()
		local casterTeam = caster:GetTeamNumber()

		if IsValidEntity(self.dominatedUnit) then
			self.dominatedUnit:ForceKill(false)
		end

		local unit = self:GetCursorTarget()
		if IsValidEntity(unit) then
			unit:SetTeam(casterTeam)
			unit:SetOwner(caster)
			if IsValidEntity(unit.dominationAbility) then
				unit.dominationAbility.dominatedUnit = nil
			end
		else
			local positionTarget = self:GetCursorPosition()
			local unitName = JUNGLE_UNITS[RandomInt(1, #JUNGLE_UNITS)]
			unit = CreateUnitByName(unitName, positionTarget, true, caster, caster, casterTeam)
			ParticleManager:CreateParticle("particles/dev/library/base_dust_hit.vpcf", PATTACH_ROOTBONE_FOLLOW, unit)
		end
		self.dominatedUnit = unit
		unit.dominationAbility = self

		unit:SetControllableByPlayer(caster:GetPlayerOwnerID(), true)
		unit:EmitSound("DOTA_Item.HotD.Activate")

		local goldBounty = self:GetSpecialValueFor("gold_bounty")
		local speedBase = self:GetSpecialValueFor("speed_base")
		local healthMin = self:GetSpecialValueFor("health_min")
		unit:SetMinimumGoldBounty(goldBounty)
		unit:SetMaximumGoldBounty(goldBounty)
		unit:SetBaseMoveSpeed(math.max(speedBase, unit:GetBaseMoveSpeed()))
		if unit:GetMaxHealth() < healthMin then
			unit:SetBaseMaxHealth(healthMin)
			unit:SetMaxHealth(healthMin)
			unit:SetHealth(healthMin)
		end
	end
end


LinkLuaModifier("modifier_item_helm_of_the_dominator_custom", "abilities/items/helm_of_the_dominator", LUA_MODIFIER_MOTION_NONE)
modifier_item_helm_of_the_dominator_custom = {
	IsHidden = function() return true end,
	IsPurgable = function() return false end,
	GetAttributes = function() return MODIFIER_ATTRIBUTE_MULTIPLE end,

	IsAura = function() return true end,
	GetModifierAura = function() return "modifier_item_helm_of_the_dominator_custom_aura" end,
	GetAuraRadius = function(self) return self:GetAbility():GetSpecialValueFor("aura_radius") end,
	GetAuraSearchTeam = function() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end,
	GetAuraSearchType = function() return DOTA_UNIT_TARGET_ALL end,

	GetModifierBonusStats_Strength = function(self) return self:GetAbility():GetSpecialValueFor("bonus_stats") end,
	GetModifierBonusStats_Agility = function(self) return self:GetAbility():GetSpecialValueFor("bonus_stats") end,
	GetModifierBonusStats_Intellect = function(self) return self:GetAbility():GetSpecialValueFor("bonus_stats") end,
}

function modifier_item_helm_of_the_dominator_custom:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	}
end


LinkLuaModifier("modifier_item_helm_of_the_dominator_custom_aura", "abilities/items/helm_of_the_dominator", LUA_MODIFIER_MOTION_NONE)
modifier_item_helm_of_the_dominator_custom_aura = {
	GetModifierAttackSpeedBonus_Constant = function(self) return self:GetAbility():GetSpecialValueFor("attack_speed_aura") end,
	GetModifierConstantHealthRegen = function(self) return self:GetAbility():GetSpecialValueFor("hp_regen_aura") end,
}

function modifier_item_helm_of_the_dominator_custom_aura:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
	}
end
