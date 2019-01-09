-- Ported from Dota IMBA (Credits: EarthSalamander #42)

modifier_donator = class({})

function modifier_donator:IsHidden() return true end
function modifier_donator:IsPurgable() return false end
function modifier_donator:IsPurgeException() return false end
function modifier_donator:RemoveOnDeath() return false end

function modifier_donator:OnCreated(keys)
	if IsServer() then
		print("Donator level:", keys.patron_level)
		self:SetStackCount(keys.patron_level) -- TODO: get what tier the patron is
		self:StartIntervalThink(0.1)
		self.current_effect_name = ""
		self.effect_name = ""
		local label_colors = {}
		label_colors[1] = {249, 104, 84}
		label_colors[2] = {5, 45, 73}

--		self:GetParent():SetCustomHealthLabel("#donator_label_" .. tostring(self:GetStackCount()), label_colors[self:GetStackCount()][1], label_colors[self:GetStackCount()][2], label_colors[self:GetStackCount()][3])
	end
end

function modifier_donator:OnIntervalThink()
	-- Move those in a global scope if needed somewhere else
	local IGNORE_PATREON_PARTICLE_MODIFIERS = {
		"modifier_monkey_king_transform",

--		"modifier_monkey_king_tree_dance_hidden",
--		"modifier_item_shadow_amulet_fade",
--		"modifier_pangolier_gyroshell",
--		"modifier_smoke_of_deceit",
	}

	for _, v in ipairs(IGNORE_PATREON_PARTICLE_MODIFIERS) do
		if self:GetParent():HasModifier(v) then
			self.effect_name = ""
			self:RefreshEffect()
			return
		end
	end

	self.effect_name = "particles/econ/events/ti8/custom_hero_effect.vpcf"

	self:RefreshEffect()
end

function modifier_donator:RefreshEffect()
	local parent = self:GetParent()
	local playerId = parent:GetPlayerID()
	local emblemEnabled = Patreons:GetPlayerSettings(playerId).emblemEnabled
	if self.pfx and not emblemEnabled then
		ParticleManager:DestroyParticle(self.pfx, false)
		ParticleManager:ReleaseParticleIndex(self.pfx)
		self.pfx = nil
		return
	end

	if self.current_effect_name ~= self.effect_name or not self.pfx and emblemEnabled then
--		print("Old Effect:", self.current_effect_name)
--		print("Effect:", self.effect_name)

		if self.pfx then
			ParticleManager:DestroyParticle(self.pfx, false)
			ParticleManager:ReleaseParticleIndex(self.pfx)
			self.pfx = nil
		end

		self.pfx = ParticleManager:CreateParticle(self.effect_name, PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
		self.current_effect_name = self.effect_name
	end

	if self.pfx then
		local emblemColor = Patreons:GetPlayerEmblemColor(playerId)
		ParticleManager:SetParticleControl(self.pfx, 9, emblemColor)
	end
end

function modifier_donator:OnDestroy()
	if IsServer() then
		if self.pfx then
			ParticleManager:DestroyParticle(self.pfx, false)
			ParticleManager:ReleaseParticleIndex(self.pfx)
		end
	end
end
