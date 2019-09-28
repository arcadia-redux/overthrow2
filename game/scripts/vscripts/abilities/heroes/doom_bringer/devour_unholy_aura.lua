LinkLuaModifier ("modifier_devour_unholy_aura", "abilities/heroes/doom_bringer/devour_unholy_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier ("modifier_devour_unholy_aura_buff", "abilities/heroes/doom_bringer/devour_unholy_aura", LUA_MODIFIER_MOTION_NONE)

if devour_unholy_aura == nil then
    devour_unholy_aura = class({})
end

function devour_unholy_aura:GetIntrinsicModifierName()
    return "modifier_devour_unholy_aura"
end


------------------------------------------------------------------------------

modifier_devour_unholy_aura = modifier_devour_unholy_aura or class({
	IsHidden 				= function(self) return true end,
	IsPurgable 				= function(self) return false end,
	IsDebuff 				= function(self) return false end,
	IsBuff                  = function(self) return true end,
	IsAura	                = function(self) return true end,
	RemoveOnDeath 			= function(self) return false end,
	AllowIllusionDuplicate	= function(self) return true end,
	IsPermanent             = function(self) return false end,
})


function modifier_devour_unholy_aura:GetModifierAura()
    return "modifier_devour_unholy_aura_buff"
end

function modifier_devour_unholy_aura:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_devour_unholy_aura:GetTexture()
    return "satyr_hellcaller_unholy_aura"
end

function modifier_devour_unholy_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_devour_unholy_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_devour_unholy_aura:GetAuraDuration()
    return 0.5
end
------------------------------------------------------------------------------

modifier_devour_unholy_aura_buff = modifier_devour_unholy_aura_buff or class({
	IsHidden 				= function(self) return false end,
	IsPurgable 				= function(self) return false end,
	IsDebuff 				= function(self) return false end,
	IsBuff                  = function(self) return true end,
	RemoveOnDeath 			= function(self) return true end,
	AllowIllusionDuplicate	= function(self) return true end,
	IsPermanent             = function(self) return false end,
})

function modifier_devour_unholy_aura_buff:GetTexture()
    return "satyr_hellcaller_unholy_aura"
end

function modifier_devour_unholy_aura_buff:DeclareFunctions()
	local funcs = 
	{
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, 
	}
	return funcs
end

function modifier_devour_unholy_aura_buff:GetModifierConstantHealthRegen()
	return self:GetAbility():GetSpecialValueFor("health_regen")
end
