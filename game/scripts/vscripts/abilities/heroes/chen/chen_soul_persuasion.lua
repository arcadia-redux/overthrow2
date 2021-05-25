chen_soul_persuasion = class({})
chen_soul_persuasion.summon_list = chen_soul_persuasion.summon_list or {}

LinkLuaModifier("chen_soul_persuasion_passive", "abilities/heroes/chen/chen_soul_persuasion_passive", LUA_MODIFIER_MOTION_NONE)

function chen_soul_persuasion:GetIntrinsicModifierName()
	return "chen_soul_persuasion_passive"
end

function chen_soul_persuasion:OnSpellStart()
	if not IsServer() then return end
	local parent = self:GetCaster()
	local soulsModifierName = "chen_soul_persuasion_passive"
	local soulsCount = parent:GetModifierStackCount(soulsModifierName, parent)
	local summonSouls = self:CheckSummonType(soulsCount)
	if summonSouls == 0 then
		self:EndCooldown()
		return
	end
	local player = parent:GetPlayerOwner()
	
	local summonMax = self:GetSpecialValueFor("creeps_max_summoned")
	self:ValidateCurrentSummons()
	if #self.summon_list >= summonMax and player and not player:IsNull() then
		CustomGameEventManager:Send_ServerToPlayer(player, "display_custom_error", { message = "#dota_chen_soul_persuasion_max_limit_error" })
		self:EndCooldown()
		return
	end
	
	local currentData = self.abilityData[summonSouls]

	if parent:GetMana() < currentData.manacost then
		if player and not player:IsNull() then
			CustomGameEventManager:Send_ServerToPlayer(player, "display_custom_error", {
				message = "#dota_hud_error_not_enough_mana"
			})
		end
		self:EndCooldown()
		return
	end

	parent:SetModifierStackCount(soulsModifierName, self, soulsCount - summonSouls)
	local creepsCount = math.min(parent:HasScepter() and self.creeps_with_aghanim or 1, summonMax - #self.summon_list)

	for _ = 1, creepsCount do
		self:CreateCreep(currentData.creeps)
	end

	parent:ReduceMana(currentData.manacost)
	self:StartCooldown(currentData.cooldown * parent:GetCooldownReduction())
end

function chen_soul_persuasion:ValidateCurrentSummons()
	for unit_index = #self.summon_list, 1, -1 do
		local unit_handle = self.summon_list[unit_index]
		if not unit_handle or unit_handle:IsNull() or not unit_handle:IsAlive() then
			table.remove(self.summon_list, unit_index)
		end
	end
end

function chen_soul_persuasion:CreateCreep(creepsData)
	local parent = self:GetCaster()
	local minDistance, maxDistance = 140, 210
	local spawnPoint = GetRandomPathablePositionWithin(parent:GetAbsOrigin(), maxDistance, minDistance)
	spawnPoint.z = 0
	local unit = CreateUnitByName(table.random(creepsData), spawnPoint, false, parent, parent, parent:GetTeamNumber())
	FindClearSpaceForUnit(unit, spawnPoint, true)
	unit:SetControllableByPlayer(parent:GetPlayerOwnerID(), true)
	table.insert(self.summon_list, unit)

	local talentForHP = parent:FindAbilityByName("special_bonus_unique_chen_4")

	if talentForHP and talentForHP:GetLevel() > 0 then
		local newHP = unit:GetMaxHealth() + talentForHP:GetSpecialValueFor("value")
		unit:SetBaseMaxHealth(newHP)
		unit:SetMaxHealth(newHP)
		unit:SetHealth(newHP)
	end

	local talentForDamage = parent:FindAbilityByName("special_bonus_unique_chen_5")

	if talentForDamage and talentForDamage:GetLevel() > 0 then
		local bonusDamage = talentForDamage:GetSpecialValueFor("value")
		local currentMinDamage, currentMaxDamage = unit:GetBaseDamageMin(), unit:GetBaseDamageMax()
		unit:SetBaseDamageMin(currentMinDamage + bonusDamage)
		unit:SetBaseDamageMax(currentMaxDamage + bonusDamage)
	end

	local spawnParticle = ParticleManager:CreateParticle("particles/econ/items/pets/pet_frondillo/pet_spawn_frondillo.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(spawnParticle, 0, spawnPoint)
	ParticleManager:ReleaseParticleIndex( spawnParticle )
end

function chen_soul_persuasion:CheckSummonType(stacksCount)
	if stacksCount >= self.souls_summon_ancient then
		return self.souls_summon_ancient
	end
	if stacksCount >= self.souls_summon_big then
		return self.souls_summon_big
	end
	if stacksCount >= self.souls_summon_middle then
		return self.souls_summon_middle
	end
	if stacksCount >= self.souls_summon_little then
		return self.souls_summon_little
	end
	return 0
end

function chen_soul_persuasion:GetAbilityTextureName()
	if self.abilityData then
		local caster = self:GetCaster()
		return self.abilityData[self:CheckSummonType(caster:GetModifierStackCount("chen_soul_persuasion_passive", caster))].icon
	end
	return "chen_soul_persuasion_1"
end

function chen_soul_persuasion:DataInit()
	local paramsList = {
		"souls_summon_little",
		"souls_summon_middle",
		"souls_summon_big",
		"souls_summon_ancient",
		"manacost_little",
		"manacost_middle",
		"manacost_big",
		"manacost_ancient",
		"cooldown_little",
		"cooldown_middle",
		"cooldown_big",
		"cooldown_ancient",
		"creeps_with_aghanim",
	}
	for _, param in pairs(paramsList) do
		self[param] = self:GetSpecialValueFor(param)
	end

	self.abilityData = {
		[0] = {
			icon = "chen_soul_persuasion_1",
		},
		[self.souls_summon_little] = {
			creeps = {
				"npc_dota_neutral_kobold",
				"npc_dota_neutral_kobold_tunneler",
				"npc_dota_neutral_centaur_outrunner",
				"npc_dota_neutral_fel_beast",
				"npc_dota_neutral_giant_wolf",
				"npc_dota_neutral_wildkin",
				"npc_dota_neutral_gnoll_assassin",
				"npc_dota_neutral_ghost",
				"npc_dota_neutral_satyr_trickster",
				"npc_dota_neutral_forest_troll_berserker",
			},
			manacost = self.manacost_little,
			cooldown = self.cooldown_little,
			icon = "chen_soul_persuasion_1",
		},
		[self.souls_summon_middle] = {
			creeps = {
				"npc_dota_neutral_dark_troll",
				"npc_dota_wraith_ghost",
				"npc_dota_neutral_ogre_mauler",
				"npc_dota_neutral_polar_furbolg_champion",
				"npc_dota_neutral_forest_troll_high_priest",
				"npc_dota_neutral_kobold_taskmaster",
				"npc_dota_neutral_satyr_soulstealer",
			},
			manacost = self.manacost_middle,
			cooldown = self.cooldown_middle,
			icon = "chen_soul_persuasion_2",
		},
		[self.souls_summon_big] = {
			creeps = {
				"npc_dota_neutral_centaur_khan",
				"npc_dota_neutral_polar_furbolg_ursa_warrior",
				"npc_dota_neutral_mud_golem",
				"npc_dota_neutral_ogre_magi",
				"npc_dota_neutral_alpha_wolf",
				"npc_dota_neutral_enraged_wildkin",
				"npc_dota_neutral_satyr_hellcaller",
				"npc_dota_neutral_small_thunder_lizard",
				"npc_dota_neutral_black_drake",
				"npc_dota_neutral_dark_troll_warlord",
			},
			manacost = self.manacost_big,
			cooldown = self.cooldown_big,
			icon = "chen_soul_persuasion_3",
		},
		[self.souls_summon_ancient] = {
			creeps = {
				"npc_dota_neutral_prowler_shaman",
				"npc_dota_neutral_rock_golem",
				"npc_dota_neutral_granite_golem",
				"npc_dota_neutral_big_thunder_lizard",
				"npc_dota_neutral_black_dragon",
			},
			manacost = self.manacost_ancient,
			cooldown = self.cooldown_ancient,
			icon = "chen_soul_persuasion_4",
		}
	}
end
