LinkLuaModifier ("modifier_devour_cloak_aura", "abilities/heroes/doom_bringer/devour_cloak_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier ("modifier_devour_cloak_aura_buff", "abilities/heroes/doom_bringer/devour_cloak_aura", LUA_MODIFIER_MOTION_NONE)

if devour_cloak_aura == nil then
    devour_cloak_aura = class({})
end

function devour_cloak_aura:GetIntrinsicModifierName()
    return "modifier_devour_cloak_aura"
end


------------------------------------------------------------------------------

modifier_devour_cloak_aura = modifier_devour_cloak_aura or class({
	IsHidden 				= function(self) return true end,
	IsPurgable 				= function(self) return false end,
	IsDebuff 				= function(self) return false end,
	IsBuff                  = function(self) return true end,
	IsAura	                = function(self) return true end,
	RemoveOnDeath 			= function(self) return false end,
	AllowIllusionDuplicate	= function(self) return true end,
	IsPermanent             = function(self) return false end,
})


function modifier_devour_cloak_aura:GetModifierAura()
    return "modifier_devour_cloak_aura_buff"
end

function modifier_devour_cloak_aura:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_devour_cloak_aura:GetTexture()
    return "mudgolem_cloak_aura"
end

function modifier_devour_cloak_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_devour_cloak_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_devour_cloak_aura:GetAuraDuration()
    return 0.5
end
------------------------------------------------------------------------------

modifier_devour_cloak_aura_buff = modifier_devour_cloak_aura_buff or class({
	IsHidden 				= function(self) return false end,
	IsPurgable 				= function(self) return false end,
	IsDebuff 				= function(self) return false end,
	IsBuff                  = function(self) return true end,
	RemoveOnDeath 			= function(self) return true end,
	AllowIllusionDuplicate	= function(self) return true end,
	IsPermanent             = function(self) return false end,
})

function modifier_devour_cloak_aura_buff:GetTexture()
    return "mudgolem_cloak_aura"
end

function modifier_devour_cloak_aura_buff:DeclareFunctions()
	local funcs = 
	{
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, 
	}
	return funcs
end

function modifier_devour_cloak_aura_buff:GetModifierMagicalResistanceBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_magical_armor")
end
