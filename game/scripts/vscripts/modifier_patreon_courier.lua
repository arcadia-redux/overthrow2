modifier_patreon_courier = {}

function modifier_patreon_courier:GetModifierModelChange()
	return "models/items/juggernaut/ward/fortunes_tout/fortunes_tout.vmdl"
end

function modifier_patreon_courier:OnModelChanged()
	Timers:CreateTimer(.2, function()
		local parent = self:GetParent()
		parent:SetModel("models/items/juggernaut/ward/fortunes_tout/fortunes_tout.vmdl")
		parent:SetOriginalModel("models/items/juggernaut/ward/fortunes_tout/fortunes_tout.vmdl")
	end)
end

function modifier_patreon_courier:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MODEL_CHANGE,
		MODIFIER_EVENT_ON_MODEL_CHANGED,
	}
end