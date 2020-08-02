chen_soul_persuasion = class({})
LinkLuaModifier("chen_soul_persuasion_passive", "abilities/heroes/chen/chen_soul_persuasion_passive", LUA_MODIFIER_MOTION_NONE)

function chen_soul_persuasion:GetIntrinsicModifierName()
	return "chen_soul_persuasion_passive"
end

function chen_soul_persuasion:OnSpellStart()
	if not IsServer() then return end
	self.souls_summon_little = self:GetSpecialValueFor("souls_summon_little")
	self.souls_summon_middle = self:GetSpecialValueFor("souls_summon_middle")
	self.souls_summon_big = self:GetSpecialValueFor("souls_summon_big")
	self.souls_summon_ancient = self:GetSpecialValueFor("souls_summon_ancient")
	self.creeps = {
		[self.souls_summon_little] = {
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
		[self.souls_summon_middle] = {
			"npc_dota_neutral_dark_troll",
			"npc_dota_wraith_ghost",
			"npc_dota_neutral_ogre_mauler",
			"npc_dota_neutral_polar_furbolg_champion",
			"npc_dota_neutral_forest_troll_high_priest",
		},
		[self.souls_summon_big] = {
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
		[self.souls_summon_ancient] = {
			"npc_dota_neutral_prowler_shaman",
			"npc_dota_neutral_rock_golem",
			"npc_dota_neutral_granite_golem",
			"npc_dota_neutral_big_thunder_lizard",
			"npc_dota_neutral_black_dragon",
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
	
	parent:SetModifierStackCount(souldModifierName, self, soulsCount - summonSouls)
	local minDistance, maxDistance = 90, 180
	local randX, randY = RandomInt(-maxDistance, maxDistance), RandomInt(-180, maxDistance)
	while(math.abs(randX) < minDistance) do
		randX = RandomInt(-maxDistance, maxDistance)
	end
	while(math.abs(randY) < minDistance) do
		randY = RandomInt(-maxDistance, maxDistance)
	end
	print("randY: ["..randY.."] randX: ["..randX.."]")
	local spawnPoint = parent:GetAbsOrigin() + Vector(randX, randY, 0)
	local unit = CreateUnitByName(table.random(self.creeps[summonSouls]), spawnPoint, false, parent, parent, parent:GetTeamNumber())
	FindClearSpaceForUnit(unit, spawnPoint, true)
	unit:SetControllableByPlayer(parent:GetPlayerOwnerID(), true)
	
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
