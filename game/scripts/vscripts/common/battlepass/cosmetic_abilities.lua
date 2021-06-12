STARTING_ABILITIES = {
	"high_five_custom",
	"default_cosmetic_ability",
	"spray_custom",
}

Cosmetics = Cosmetics or {}

function Cosmetics:Init()
	CustomGameEventManager:RegisterListener("cosmetic_abilities:get_dummy_caster",function(_, keys)
		self:GetDummyCasterForClient(keys)
	end)
end

function Cosmetics:InitCosmeticForUnit(unit)

	if unit.dummy_caster then
		unit.dummy_caster:ForceKill(false)
		unit.dummy_caster = nil
	end

	if unit:IsRealHero() and not unit.dummy_caster then
		local dummy_caster = CreateUnitByName("npc_dummy_cosmetic_caster", unit:GetAbsOrigin(), true, unit, unit, unit:GetTeam())
		for _, abilityName in pairs( STARTING_ABILITIES ) do
			local overrideCooldown
			if abilityName == "high_five_custom" then
				overrideCooldown = 140
			end
			if abilityName == "spray_custom" then
				overrideCooldown = 0
			end
			Cosmetics:AddAbility(dummy_caster, abilityName, overrideCooldown)
		end
		--dummy_caster:FollowEntity(unit, true)
		unit.dummy_caster = dummy_caster
		dummy_caster:SetControllableByPlayer(unit:GetPlayerOwnerID(), true)
		dummy_caster:SetOwner(unit)
		CustomGameEventManager:Send_ServerToPlayer(unit:GetOwner(), "cosmetic_abilities:update_dummy_tracking", {ent = dummy_caster:GetEntityIndex()})
		if unit:HasModifier("modifier_hero_refreshing") then
			dummy_caster:AddNewModifier(dummy_caster, nil, "modifier_hero_refreshing", {})
		end
		dummy_caster:AddNewModifier(dummy_caster, nil, "modifier_dummy_caster", {})
		dummy_caster:SetContextThink("UpdateDummyPosition", function()
			if not unit or unit:IsNull() then return end
			self:UpdateDummyPosition(unit)
			return 0.33
		end, 0.5)
		dummy_caster:RemoveNoDraw()
	end
end
function Cosmetics:UpdateDummyPosition(unit)
	if unit:IsAlive() then
		local dummy = unit.dummy_caster
		if not dummy then return end
		dummy:SetAbsOrigin(unit:GetAbsOrigin())
		dummy:SetForwardVector(unit:GetForwardVector())
	end
end
function Cosmetics:AddAbility(unit, abilityName, overrideCooldown)
	if unit:FindAbilityByName(abilityName) then return end
	local ability = unit:AddAbility(abilityName)
	ability:SetLevel(1)
	ability:SetHidden(false)
	ability.isCosmeticAbility = true
	ability:StartCooldown(overrideCooldown or ability:GetCooldown(ability:GetLevel()))
	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(unit:GetPlayerOwnerID()), "cosmetics_reload_abilities", {})
end
function Cosmetics:GetDummyCasterForClient(data)
	local playerId = data.PlayerID
	if not playerId then return end
	local hero = PlayerResource:GetSelectedHeroEntity(playerId)
	if not hero then return end
	if not hero.dummy_caster then return end
	CustomGameEventManager:Send_ServerToPlayer(hero:GetOwner(), "cosmetic_abilities:update_dummy_tracking", {ent = hero.dummy_caster:GetEntityIndex()})
end
