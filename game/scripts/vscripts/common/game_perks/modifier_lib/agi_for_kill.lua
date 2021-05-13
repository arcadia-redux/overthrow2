require("common/game_perks/base_game_perk")

agi_for_kill = class(base_game_perk)

function agi_for_kill:DeclareFunctions() return { MODIFIER_PROPERTY_STATS_AGILITY_BONUS, MODIFIER_EVENT_ON_HERO_KILLED } end

function agi_for_kill:OnHeroKilled(keys)
	if not IsServer() then return end
	local killerID = keys.attacker:GetPlayerOwnerID()
	
	if killerID and killerID == self:GetParent():GetPlayerOwnerID() and keys.target:GetTeam() ~= self:GetParent():GetTeam() then
		self:IncrementStackCount()
		self:GetParent():CalculateStatBonus(false)
	end
end
function agi_for_kill:GetTexture() return "perkIcons/agi_for_kill" end

function agi_for_kill:GetModifierBonusStats_Agility()
	if self:GetParent():HasModifier("modifier_meepo_divided_we_stand") then return end
	return self.v * self:GetStackCount()
end

agi_for_kill_t0 = class(agi_for_kill)
agi_for_kill_t1 = class(agi_for_kill)
agi_for_kill_t2 = class(agi_for_kill)

function agi_for_kill_t0:OnCreated() self.v = 1 end
function agi_for_kill_t1:OnCreated() self.v = 2 end
function agi_for_kill_t2:OnCreated() self.v = 3 end
