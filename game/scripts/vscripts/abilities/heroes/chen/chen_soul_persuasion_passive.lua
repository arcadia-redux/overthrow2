chen_soul_persuasion_passive = class({})
----------------------------------------------------
function chen_soul_persuasion_passive:OnCreated()
	if not IsServer() then return end
	self.souls_limit = self:GetAbility():GetSpecialValueFor("souls_limit")
	self.souls_per_kill = self:GetAbility():GetSpecialValueFor("souls_per_kill")
	self.souls_per_second = self:GetAbility():GetSpecialValueFor("souls_per_second")
	self.souls_tick_rate = self:GetAbility():GetSpecialValueFor("souls_tick_rate")
	self:StartIntervalThink(self.souls_tick_rate)
end
----------------------------------------------------
function chen_soul_persuasion_passive:OnRefresh(params)
    self:OnCreated(params)
end
----------------------------------------------------
function chen_soul_persuasion_passive:IncreaseSoulsStacks(stacksIncrement)
	local currentStacks = self:GetStackCount()
	if currentStacks >= self.souls_limit then return end
	local newStackCount = currentStacks + stacksIncrement
	self:SetStackCount(self.souls_limit < newStackCount and self.souls_limit or newStackCount)
end
----------------------------------------------------
function chen_soul_persuasion_passive:OnIntervalThink()
	if not IsServer() then return end
	self:IncreaseSoulsStacks(self.souls_per_second)
end
----------------------------------------------------
function chen_soul_persuasion_passive:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_HERO_KILLED,
	}
	return funcs
end
----------------------------------------------------
function chen_soul_persuasion_passive:OnHeroKilled(params)
	if not IsServer() then return end
	local parent = self:GetParent()
	local killerID = params.attacker:GetPlayerOwnerID()
	
	if killerID and killerID == parent:GetPlayerOwnerID() then
		self:IncreaseSoulsStacks(self.souls_per_kill)
	end
end
----------------------------------------------------
