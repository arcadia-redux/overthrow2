modifier_cosmetic_skin_ice_chrome = class({})

function modifier_cosmetic_skin_ice_chrome:IsHidden() return true end
function modifier_cosmetic_skin_ice_chrome:IsDebuff() return false end
function modifier_cosmetic_skin_ice_chrome:IsPurgable() return false end
function modifier_cosmetic_skin_ice_chrome:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

function modifier_cosmetic_skin_ice_chrome:GetStatusEffectName()
	return "particles/cosmetic/hero_skins/ice_chrome.vpcf"
end
