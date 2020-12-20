item_hand_of_midas_custom = {
	GetIntrinsicModifierName = function() return "modifier_item_hand_of_midas_custom" end,
	GetAOERadius = function(self) return self:GetSpecialValueFor("aoe_radius") end,
}

if IsServer() then
	local function FindCoinsInRadius(position, radius)
		local coins = {}
		local containers = Entities:FindAllByClassnameWithin("dota_item_drop", position, radius)
		for _, container in ipairs(containers) do
			local item = container:GetContainedItem()
			if IsValidEntity(item) and item:GetAbilityName() == "item_bag_of_gold" then
				table.insert(coins, container)
			end
		end

		return coins
	end

	function item_hand_of_midas_custom:CastFilterResultLocation(position)
		return #FindCoinsInRadius(position, self:GetSpecialValueFor("aoe_radius")) == 0 and UF_FAIL_CUSTOM or UF_SUCCESS
	end

	function item_hand_of_midas_custom:GetCustomCastErrorLocation(position)
		return #FindCoinsInRadius(position, self:GetSpecialValueFor("aoe_radius")) == 0 and "custom_hud_error_no_coins" or ""
	end

	function item_hand_of_midas_custom:OnSpellStart()
		local caster = self:GetCaster()
		local position = self:GetCursorPosition()
		local errMessage = self:GetCustomCastErrorLocation(position)
		if errMessage ~= "" then
			DisplayError(caster:GetPlayerOwnerID(), errMessage)
			return
		end

		caster:EmitSound("DOTA_Item.Hand_Of_Midas")
		ParticleManager:SetParticleControl(
			ParticleManager:CreateParticle("particles/custom/items/hand_of_midas_cast.vpcf", PATTACH_CUSTOMORIGIN, nil),
			0,
			position + Vector(0, 0, 32)
		)

		local coins = FindCoinsInRadius(position, self:GetSpecialValueFor("aoe_radius"))
		for _, coin in ipairs(coins) do
			ProjectileManager:CreateTrackingProjectile({
				Target = caster,
				vSourceLoc = coin:GetAbsOrigin(),
				Ability = self,
				EffectName = "particles/custom/items/hand_of_midas_coin.vpcf",
				bDodgeable = false,
				bProvidesVision = false,
				iMoveSpeed = self:GetSpecialValueFor("projectile_speed")
			})
			coin:RemoveSelf()
		end
	end

	function item_hand_of_midas_custom:OnProjectileHit(target)
		if target then
			COverthrowGameMode:AddGoldenCoin(target)
			target:AddExperienceCustom(self:GetSpecialValueFor("xp_per_coin"), 0, false, false)
			SendOverheadEventMessage(target, OVERHEAD_ALERT_XP, target, self:GetSpecialValueFor("xp_per_coin"), nil)
		end
	end
end


LinkLuaModifier("modifier_item_hand_of_midas_custom", "abilities/items/hand_of_midas", LUA_MODIFIER_MOTION_NONE)
modifier_item_hand_of_midas_custom = {
	IsHidden = function() return true end,
	IsPurgable = function() return false end,
	GetAttributes = function() return MODIFIER_ATTRIBUTE_MULTIPLE end,

	DeclareFunctions = function() return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT } end,
	GetModifierAttackSpeedBonus_Constant = function(self) return self:GetAbility():GetSpecialValueFor("bonus_attack_speed") end,
}
