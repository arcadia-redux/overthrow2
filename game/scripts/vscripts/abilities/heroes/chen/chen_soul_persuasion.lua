chen_soul_persuasion = class({})
LinkLuaModifier("chen_soul_persuasion_passive", "abilities/heroes/chen/chen_soul_persuasion_passive", LUA_MODIFIER_MOTION_NONE)

function chen_soul_persuasion:GetIntrinsicModifierName()
	return "chen_soul_persuasion_passive"
end

function chen_soul_persuasion:OnSpellStart()
	if not IsServer() then return end
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
	}
	for _, param in pairs(paramsList) do
		self[param] = self:GetSpecialValueFor(param)
	end
	
	self.abilityData = {
		[self.souls_summon_little] = {
			creeps = {
				"npc_dota_neutral_kobold",
				"npc_dota_neutral_kobold_tunneler",
				"npc_dota_neutral_kobold_taskmaster",
				"npc_dota_neutral_centaur_outrunner",
				"npc_dota_neutral_fel_beast",
				"npc_dota_neutral_giant_wolf",
				"npc_dota_neutral_wildkin",
				"npc_dota_neutral_satyr_soulstealer",
				"npc_dota_neutral_gnoll_assassin",
				"npc_dota_neutral_ghost",
				"npc_dota_neutral_dark_troll_warlord",
				"npc_dota_neutral_satyr_trickster",
				"npc_dota_neutral_forest_troll_berserker",
			},
			manacost = self.manacost_little,
			cooldown = self.cooldown_little,
		},
		[self.souls_summon_middle] = {
			creeps = {
				"npc_dota_neutral_dark_troll",
				"npc_dota_wraith_ghost",
				"npc_dota_neutral_ogre_mauler",
				"npc_dota_neutral_polar_furbolg_champion",
				"npc_dota_neutral_forest_troll_high_priest",
			},
			manacost = self.manacost_middle,
			cooldown = self.cooldown_middle,
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
			},
			manacost = self.manacost_big,
			cooldown = self.cooldown_big,
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
		}		
	}
	
	local parent = self:GetCaster()
	local souldModifierName = "chen_soul_persuasion_passive"
	local soulsCount = parent:GetModifierStackCount(souldModifierName, parent)
	local summonSouls = self:CheckSummonType(soulsCount)
	if summonSouls == 0 then
		self:EndCooldown()
		return
	end
	local currentData = self.abilityData[summonSouls]

	if parent:GetMana() < currentData.manacost then
		CustomGameEventManager:Send_ServerToPlayer(parent:GetPlayerOwnerID(), "display_custom_error", { message = "#dota_hud_error_not_enough_mana" })
		self:EndCooldown()
		return
	end
	
	parent:SetModifierStackCount(souldModifierName, self, soulsCount - summonSouls)
	local minDistance, maxDistance = 90, 180
	local randX, randY = RandomInt(-maxDistance, maxDistance), RandomInt(-180, maxDistance)
	while(math.abs(randX) < minDistance) do
		randX = RandomInt(-maxDistance, maxDistance)
	end
	while(math.abs(randY) < minDistance) do
		randY = RandomInt(-maxDistance, maxDistance)
	end
	
	local spawnPoint = parent:GetAbsOrigin() + Vector(randX, randY, 0)
	local unit = CreateUnitByName(table.random(currentData.creeps), spawnPoint, false, parent, parent, parent:GetTeamNumber())
	FindClearSpaceForUnit(unit, spawnPoint, true)
	unit:SetControllableByPlayer(parent:GetPlayerOwnerID(), true)
	
	local spawnParticle = ParticleManager:CreateParticle("particles/econ/items/pets/pet_frondillo/pet_spawn_frondillo.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(spawnParticle, 0, spawnPoint)
	ParticleManager:ReleaseParticleIndex( spawnParticle )
	
	parent:ReduceMana(currentData.manacost)
	self:StartCooldown(currentData.cooldown)
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
