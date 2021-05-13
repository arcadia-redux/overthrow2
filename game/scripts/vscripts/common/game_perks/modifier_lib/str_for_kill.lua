require("common/game_perks/base_game_perk")

str_for_kill = class(base_game_perk)

function str_for_kill:DeclareFunctions() return { MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, MODIFIER_EVENT_ON_HERO_KILLED } end

function str_for_kill:OnHeroKilled(keys)
	if not IsServer() then return end
	local killerID = keys.attacker:GetPlayerOwnerID()
	
	if killerID and killerID == self:GetParent():GetPlayerOwnerID() and keys.target:GetTeam() ~= self:GetParent():GetTeam() then
		self:IncrementStackCount()
		self:GetParent():CalculateStatBonus(false)
	end
end
function str_for_kill:GetTexture() return "perkIcons/str_for_kill" end

function str_for_kill:GetModifierBonusStats_Strength()
	if self:GetParent():HasModifier("modifier_meepo_divided_we_stand") then return end
	return self.v * self:GetStackCount()
end

str_for_kill_t0 = class(str_for_kill)
str_for_kill_t1 = class(str_for_kill)
str_for_kill_t2 = class(str_for_kill)

function str_for_kill_t0:OnCreated() self.v = 1 end
function str_for_kill_t1:OnCreated() self.v = 2 end
function str_for_kill_t2:OnCreated() self.v = 3 end
