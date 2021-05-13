item_linken_perk = item_linken_perk or class({})
LinkLuaModifier("modifier_linken_perk","items/item_linken_perk", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_linken_perk_self","items/item_linken_perk", LUA_MODIFIER_MOTION_NONE)

function item_linken_perk:OnSpellStart()
	if not IsServer() then return end
	
	local caster = self:GetCaster()
	local parent = self:GetCursorTarget()
	if not caster or not parent then return end
	
	parent:AddNewModifier(caster, self, "modifier_linken_perk", { duration = self:GetSpecialValueFor("buff_duration") })
	parent:EmitSound("DOTA_Item.LinkensSphere.Target")
end

item_linken_perk_0 = class(item_linken_perk)
item_linken_perk_1 = class(item_linken_perk)
item_linken_perk_2 = class(item_linken_perk)

modifier_linken_perk = modifier_linken_perk or class({})
function modifier_linken_perk:RemoveOnDeath() return true end
function modifier_linken_perk:IsHidden() return false end
function modifier_linken_perk:DeclareFunctions() return { MODIFIER_PROPERTY_ABSORB_SPELL } end
function modifier_linken_perk:OnCreated()
	local parent = self:GetParent()
	self.particle = ParticleManager:CreateParticle("particles/items_fx/immunity_sphere_buff.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
	ParticleManager:SetParticleControlEnt(self.particle, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
end
function modifier_linken_perk:OnDestroy()
	ParticleManager:DestroyParticle( self.particle, false )
	ParticleManager:ReleaseParticleIndex( self.particle )
end

function modifier_linken_perk:GetAbsorbSpell()
	local parent = self:GetParent()
	if not parent then return end
	
	parent:EmitSound("DOTA_Item.LinkensSphere.Activate")
	ParticleManager:CreateParticle("particles/items_fx/immunity_sphere.vpcf", PATTACH_POINT_FOLLOW, parent)
	self:Destroy()
	
	return 1
end
