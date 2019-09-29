LinkLuaModifier ("modifier_devour_speed_aura", "abilities/heroes/doom_bringer/devour_speed_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier ("modifier_devour_speed_aura_buff", "abilities/heroes/doom_bringer/devour_speed_aura", LUA_MODIFIER_MOTION_NONE)

if devour_speed_aura == nil then
    devour_speed_aura = class({})
end

function devour_speed_aura:GetIntrinsicModifierName()
    return "modifier_devour_speed_aura"
end


------------------------------------------------------------------------------

modifier_devour_speed_aura = modifier_devour_speed_aura or class({
	IsHidden 				= function(self) return true end,
	IsPurgable 				= function(self) return false end,
	IsDebuff 				= function(self) return false end,
	IsBuff                  = function(self) return true end,
	IsAura	                = function(self) return true end,
	RemoveOnDeath 			= function(self) return false end,
	AllowIllusionDuplicate	= function(self) return true end,
	IsPermanent             = function(self) return false end,
})


function modifier_devour_speed_aura:GetModifierAura()
    return "modifier_devour_speed_aura_buff"
end

function modifier_devour_speed_aura:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_devour_speed_aura:GetTexture()
    return "kobold_taskmaster_speed_aura"
end

function modifier_devour_speed_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_devour_speed_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_devour_speed_aura:GetAuraDuration()
    return 0.3
end

------------------------------------------------------------------------------

modifier_devour_speed_aura_buff = modifier_devour_speed_aura_buff or class({
	IsHidden 				= function(self) return false end,
	IsPurgable 				= function(self) return false end,
	IsDebuff 				= function(self) return false end,
	IsBuff                  = function(self) return true end,
	RemoveOnDeath 			= function(self) return true end,
	AllowIllusionDuplicate	= function(self) return true end,
	IsPermanent             = function(self) return false end,
})

function modifier_devour_speed_aura_buff:GetTexture()
    return "kobold_taskmaster_speed_aura"
end

function modifier_devour_speed_aura_buff:DeclareFunctions()
	local funcs = 
	{
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, 
	}
	return funcs
end

function modifier_devour_speed_aura_buff:GetModifierMoveSpeedBonus_Percentage()
	if self:GetAbility() then
		return self:GetAbility():GetSpecialValueFor("bonus_movement_speed")
	else 
		return 0
	end		
end
