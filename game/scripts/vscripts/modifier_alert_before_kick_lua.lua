modifier_alert_before_kick_lua = class({})

function modifier_alert_before_kick_lua:IsHidden()
	return false
end

function modifier_alert_before_kick_lua:IsDebuff()
	return true
end

function modifier_alert_before_kick_lua:IsPurgable()
	return false
end

function modifier_alert_before_kick_lua:RemoveOnDeath()
	return false
end

function modifier_alert_before_kick_lua:GetTexture()
	return "banhammer2"
end

function modifier_alert_before_kick_lua:GetEffectName()
	return "particles/alert_ban_hammer.vpcf"
end

function modifier_alert_before_kick_lua:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end