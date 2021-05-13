item_teleport_perk = item_teleport_perk or class({})
LinkLuaModifier("modifier_teleport_from_perk","items/item_teleport_perk", LUA_MODIFIER_MOTION_NONE)

function FindDistance(vec1, vec2)
	return (vec1 - vec2):Length2D()
end

local black_list_for_tp = {
	["npc_torch_vision_revealer"] = true,
}

function item_teleport_perk:OnSpellStart()
	if not IsServer() then return end
	
	local caster = self:GetCaster()
	if not caster then return end
	
	local player_id = caster:GetPlayerOwnerID()
	if not player_id then return end

	local team = caster:GetTeamNumber()
	
	local friendly_units = FindUnitsInRadius(team,
		Vector(0, 0, 0),
		nil,
		FIND_UNITS_EVERYWHERE,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP + DOTA_UNIT_TARGET_BUILDING,
		DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
		FIND_ANY_ORDER,
		false)
	
	local init_point = self:GetCursorPosition()
	local unit_fot_tp
	local min_distance = 100000
	for _, x in pairs(friendly_units) do
		if x and x ~= caster and (x.GetUnitName and not black_list_for_tp[x:GetUnitName()]) then
			if min_distance > FindDistance(init_point, x:GetAbsOrigin()) then
				min_distance = FindDistance(init_point, x:GetAbsOrigin())
				unit_fot_tp = x;
			end
		end
	end
	
	if not unit_fot_tp then return end
	
	if FindDistance(init_point, unit_fot_tp:GetAbsOrigin()) <= 600 then
		self.pos_for_tp = init_point
	else
		self.pos_for_tp = unit_fot_tp:GetAbsOrigin() + (init_point - unit_fot_tp:GetAbsOrigin()):Normalized() * 600
	end
	
	MinimapEvent( team, caster, self.pos_for_tp.x, self.pos_for_tp.y, DOTA_MINIMAP_EVENT_TEAMMATE_TELEPORTING, self:GetChannelTime() )
	
	self:SetChanneling(false)
	caster:AddNewModifier(caster, nil, "modifier_teleport_from_perk", {})
	caster:EmitSound("Portal.Loop_Appear")

	self.tp_end = ParticleManager:CreateParticle("particles/items2_fx/teleport_end.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl( self.tp_end, 0, self.pos_for_tp)
	ParticleManager:SetParticleControl( self.tp_end, 1, self.pos_for_tp)
	ParticleManager:SetParticleControl( self.tp_end, 2, Vector(200, 100, 20))
	ParticleManager:SetParticleControlEnt( self.tp_end, 3, caster, PATTACH_ABSORIGIN, "attach_origin", Vector(0,0,0), false)
	ParticleManager:SetParticleControl( self.tp_end, 4, Vector(1.0, 0, 0) )
	ParticleManager:SetParticleControl( self.tp_end, 5, self.pos_for_tp + Vector(0,0,150) )
end

function item_teleport_perk:OnChannelFinish(b_interrupted)
	local caster = self:GetCaster()
	
	if not b_interrupted then
		FindClearSpaceForUnit(caster, self.pos_for_tp, false)
		caster:EmitSound("Portal.Hero_Appear")
	else
		MinimapEvent( caster:GetTeamNumber(), caster, 0, 0, DOTA_MINIMAP_EVENT_CANCEL_TELEPORTING, 0 )
	end
	
	caster:StopSound("Portal.Loop_Appear")
	caster:RemoveModifierByName("modifier_teleport_from_perk")

	ParticleManager:DestroyParticle(self.tp_end, b_interrupted)
	ParticleManager:ReleaseParticleIndex(self.tp_end)
end

modifier_teleport_from_perk = modifier_teleport_from_perk or class({})
function modifier_teleport_from_perk:RemoveOnDeath() return true end
function modifier_teleport_from_perk:IsHidden() return true end
function modifier_teleport_from_perk:GetEffectName()
	return "particles/items2_fx/teleport_start.vpcf"
end

item_teleport_perk_0 = class(item_teleport_perk)
item_teleport_perk_1 = class(item_teleport_perk)
item_teleport_perk_2 = class(item_teleport_perk)
