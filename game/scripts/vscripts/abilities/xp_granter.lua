dota_ability_xp_granter = {
	GetIntrinsicModifierName = function() return "modifier_dota_ability_xp_granter" end
}

dota_ability_xp_granter2 = {
	GetIntrinsicModifierName = function() return "modifier_dota_ability_xp_granter" end
}

dota_ability_xp_granter3 = {
	GetIntrinsicModifierName = function() return "modifier_dota_ability_xp_granter" end
}

LinkLuaModifier("modifier_dota_ability_xp_granter", "abilities/xp_granter", LUA_MODIFIER_MOTION_NONE)
modifier_dota_ability_xp_granter = {
	IsHidden = function() return true end,
	IsAura = function() return true end,
	GetModifierAura    = function() return "modifier_get_xp" end,
	GetAuraRadius = function(self) return self:GetAbility():GetSpecialValueFor("aura_radius") end,
	GetAuraDuration    = function() return 0.2 end,
	GetAuraSearchTeam = function() return DOTA_UNIT_TARGET_TEAM_BOTH end,
	GetAuraSearchType = function() return DOTA_UNIT_TARGET_HERO end,
	GetAuraSearchFlags = function() return DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS end,
}

function modifier_dota_ability_xp_granter:CheckState()
	return {
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_OUT_OF_GAME] = true,
	}
end


LinkLuaModifier("modifier_get_xp", "abilities/xp_granter", LUA_MODIFIER_MOTION_NONE)
modifier_get_xp = {
	IsDebuff = function() return false end,
	GetTexture = function() return "custom_games_xp_coin" end
}

local isFirstXpAuraModifier = true
if IsServer() then
	function modifier_get_xp:OnCreated(keys)
		if isFirstXpAuraModifier and keys.isProvidedByAura == 1 then
			isFirstXpAuraModifier = false
			local parent = self:GetParent()
			local ability = self:GetAbility()
			local units = FindUnitsInRadius(parent:GetTeamNumber(), Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS, FIND_ANY_ORDER, false)
			for _,v in ipairs(units) do
				if v ~= parent then
					v:AddNewModifier(parent, ability, "modifier_get_xp_late_bonus", { duration = 120 })
				end
			end
		end
		self:StartIntervalThink(0.5)
	end

	function modifier_get_xp:OnIntervalThink()
		local parent = self:GetParent()
		local ability = self:GetAbility()

		local xp = ability:GetSpecialValueFor("aura_xp")
		local gold = ability:GetSpecialValueFor("aura_gold")
		parent:ModifyGold(gold, false, 0)
		parent:AddExperience(xp, 0, false, false)
	end
end


LinkLuaModifier("modifier_get_xp_late_bonus", "abilities/xp_granter", LUA_MODIFIER_MOTION_NONE)
modifier_get_xp_late_bonus = {
	IsDebuff = function() return false end,
	GetTexture = function() return "custom_games_xp_coin" end
}

if IsServer() then
	function modifier_get_xp_late_bonus:OnCreated(keys)
		self.wasConnected = keys.wasConnected
		self.leftFountain = keys.leftFountain
		self:StartIntervalThink(0.5)
		self:OnIntervalThink()
	end

	function modifier_get_xp_late_bonus:OnIntervalThink()
		local parent = self:GetParent()
		local ability = self:GetAbility()
		local isOnCenter = parent:HasModifier("modifier_get_xp")
		if isOnCenter then
			self:Destroy()
			return
		end

		if not self.wasConnected and self:GetRemainingTime() > 30 then
			local isConnected = parent:GetPlayerOwner() ~= nil
			if isConnected then
				self:Destroy()
				parent:AddNewModifier(
					self:GetCaster(),
					ability,
					"modifier_get_xp_late_bonus",
					{ duration = 30, leftFountain = self.leftFountain, wasConnected = true }
				)
				return
			end
		end
		if not self.leftFountain and self:GetRemainingTime() > 10 then
			local isOnFountain = parent:HasModifier("modifier_fountain_aura_effect_lua")
			if not isOnFountain then
				self:Destroy()
				parent:AddNewModifier(
					self:GetCaster(),
					ability,
					"modifier_get_xp_late_bonus",
					{ duration = 10, leftFountain = true, wasConnected = self.wasConnected }
				)
				return
			end
		end

		local xp = ability:GetSpecialValueFor("aura_xp")
		local gold = ability:GetSpecialValueFor("aura_gold")
		parent:ModifyGold(gold, false, 0)
		parent:AddExperience(xp, 0, false, false)
	end
end
