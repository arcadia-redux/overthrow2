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

	if unit.dummyCaster then
		unit.dummyCaster:ForceKill(false)
		unit.dummyCaster = nil
	end
	
	if unit:IsRealHero() and not unit.dummyCaster then
		local dummyCaster = CreateUnitByName("npc_dummy_cosmetic_caster", unit:GetAbsOrigin(), true, unit, unit, unit:GetTeam())
		for _, abilityName in pairs( STARTING_ABILITIES ) do
			local overrideCooldown
			if abilityName == "high_five_custom" then
				overrideCooldown = 140
			end
			if abilityName == "spray_custom" then
				overrideCooldown = 0
			end
			Cosmetics:AddAbility(dummyCaster, abilityName, overrideCooldown)
		end
		--dummyCaster:FollowEntity(unit, true)
		unit.dummyCaster = dummyCaster
		dummyCaster:SetControllableByPlayer(unit:GetPlayerOwnerID(), true)
		dummyCaster:SetOwner(unit)
		CustomGameEventManager:Send_ServerToPlayer(unit:GetOwner(), "cosmetic_abilities:update_dummy_tracking", {ent = dummyCaster:GetEntityIndex()})
		if unit:HasModifier("modifier_hero_refreshing") then
			dummyCaster:AddNewModifier(dummyCaster, nil, "modifier_hero_refreshing", {})
		end
		dummyCaster:AddNewModifier(dummyCaster, nil, "modifier_dummy_caster", {})
		dummyCaster:SetContextThink("UpdateDummyPosition", function()
			self:UpdateDummyPosition(unit)
			return 0.33
		end, 0.5)
		dummyCaster:RemoveNoDraw()
	end
end
function Cosmetics:UpdateDummyPosition(unit)
	if unit:IsAlive() then
		local dummy = unit.dummyCaster
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
	if not hero.dummyCaster then return end
	CustomGameEventManager:Send_ServerToPlayer(hero:GetOwner(), "cosmetic_abilities:update_dummy_tracking", {ent = hero.dummyCaster:GetEntityIndex()})
end
