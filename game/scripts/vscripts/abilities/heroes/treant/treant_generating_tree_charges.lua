treant_generating_tree_charges = class({})
----------------------------------------------------

function treant_generating_tree_charges:IsPurgable() 
	return false
end

function treant_generating_tree_charges:DestroyOnExpire() 
	return false
end

function treant_generating_tree_charges:RemoveOnDeath() 
	return false
end

function treant_generating_tree_charges:IsHidden()
	return self:GetStackCount() <= 0
end

function treant_generating_tree_charges:OnCreated()
	if not IsServer() then return end
	self.ability = self:GetAbility()
	self.charge_cooldown = self.ability:GetSpecialValueFor("charge_cooldown")
	
	self:StartIntervalThink(self.charge_cooldown)
end
----------------------------------------------------
function treant_generating_tree_charges:OnRefresh(params)
    self:OnCreated(params)
end
----------------------------------------------------
function treant_generating_tree_charges:OnIntervalThink()
	if not IsServer() then return end
	local currentCharges = self:GetStackCount()
	if currentCharges < self.ability.max_charges then
		self:IncrementStackCount()
	end
end
----------------------------------------------------
