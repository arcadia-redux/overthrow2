treant_generating_tree_auto_cast = class({})
----------------------------------------------------
function treant_generating_tree_auto_cast:IsHidden()
	return true
end
----------------------------------------------------
function treant_generating_tree_auto_cast:OnCreated()
	if not IsServer() then return end
	self.ability = self:GetAbility()
	local parent = self:GetParent()
	self.ability.tree_duration = self.ability:GetSpecialValueFor("tree_duration")
	
	self.auto_cast_tick_rate = self.ability:GetSpecialValueFor("auto_cast_tick_rate")
	self.min_distance = self.ability:GetSpecialValueFor("min_distance")
	self.original_distance = self.ability:GetCastRange(parent:GetAbsOrigin(), parent)
	
	self:StartIntervalThink(self.auto_cast_tick_rate)

	self.ability.charges = parent:AddNewModifier( parent, self.ability, "treant_generating_tree_charges", {duration = -1} )
	self.ability.max_charges = self.ability:GetSpecialValueFor("max_charges")
end
----------------------------------------------------
function treant_generating_tree_auto_cast:OnRefresh(params)
    self:OnCreated(params)
end
----------------------------------------------------
function treant_generating_tree_auto_cast:OnIntervalThink()
	if not IsServer() then return end
	
	local parent = self:GetParent()
	if not parent:IsAlive() then return end
	
	if not self.ability:GetAutoCastState() then return end
	if self.ability.charges:GetStackCount() ~= self.ability.max_charges then return end
	
	local manacost = self.ability:GetManaCost(self.ability:GetLevel() - 1)
	if manacost > parent:GetMana() then return end
	
	local maxDistance = self.original_distance + parent:GetCastRangeBonus()
	local getRandomValue = function() 
		return (RandomInt(0, 1) * 2 - 1) * ( self.minDistance + RandomInt(0, maxDistance - self.minDistance ) )
	end
	self.ability:CreateTree(parent:GetAbsOrigin() + Vector(getRandomValue(), getRandomValue(), 0))
	self.ability.charges:DecrementStackCount()
	parent:ReduceMana(manacost)
end
----------------------------------------------------
