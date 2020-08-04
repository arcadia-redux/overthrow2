treant_generating_tree = class({})
LinkLuaModifier("treant_generating_tree_auto_cast", "abilities/heroes/treant/treant_generating_tree_auto_cast", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("treant_generating_tree_charges", "abilities/heroes/treant/treant_generating_tree_charges", LUA_MODIFIER_MOTION_NONE)

function treant_generating_tree:GetIntrinsicModifierName()
	return "treant_generating_tree_auto_cast"
end

function treant_generating_tree:OnSpellStart()
	if not IsServer() then return end
	if self.charges:GetStackCount() < 1 then
		local caster = self:GetCaster()
		CustomGameEventManager:Send_ServerToPlayer(caster:GetPlayerOwner(), "display_custom_error", { message = "#dota_hud_error_no_charges" })
		caster:GiveMana(self:GetManaCost(self:GetLevel() - 1))
		self:EndCooldown()
		return
	end
	self.charges:DecrementStackCount()
	self:CreateTree(self:GetCursorPosition())
end

function treant_generating_tree:CreateTree(pos)
	CreateTempTree(pos, self.tree_duration)
	local unitsInRadius = FindUnitsInRadius(self:GetCaster():GetTeamNumber(), pos, nil, 60, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_COURIER, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
	for _, unit in pairs(unitsInRadius) do
		FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
	end
	
	local spawnParticle = ParticleManager:CreateParticle("particles/world_destruction_fx/tree_grow_generic.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(spawnParticle, 0, pos)
	ParticleManager:ReleaseParticleIndex( spawnParticle )
end 
