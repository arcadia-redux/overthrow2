local HighFiveLimitSucces = 5
local HighFiveLimitLose = 5

high_five_custom = class({
	OnSpellStart = function(self)
		local caster = PlayerResource:GetSelectedHeroEntity(self:GetCaster():GetPlayerOwnerID())
		if not caster:IsAlive() then return end
		caster:AddNewModifier(caster, self,'modifier_high_five_custom_search', {duration = 10})
		self:StartCooldown(self:GetCooldown(self:GetLevel()))
		EmitSoundOn('high_five.cast', caster)
	end,

	OnProjectileHit = function(self,hTarget,vLocation)
		if hTarget or not self.creep or self.creep:IsNull() then
			return
		end
		local particle = ParticleManager:CreateParticle('particles/econ/events/ti9/high_five/high_five_impact.vpcf', PATTACH_ABSORIGIN_FOLLOW, self.creep)
		ParticleManager:SetParticleControl(particle, 3, self.creep:GetOrigin())
		self.creep:ForceKill(false)
		ParticleManager:ReleaseParticleIndex(particle)
		EmitSoundOn('high_five.impact', self.creep)
	end,
})

local use_high_five = function(hHero1,hHero2)
	local vPoint = (hHero2:GetOrigin() + hHero1:GetOrigin())/2
	local dummy = CreateUnitByName('npc_dummy', vPoint, false, nil,nil, DOTA_TEAM_NEUTRALS)
	local ability1 = hHero1:FindAbilityByName('high_five_custom')
	local ability2 = hHero2:FindAbilityByName('high_five_custom')
	if ability1 then
		ability1.creep = dummy
	end
	if ability2 then
		ability2.creep = dummy
	end
	ProjectileManager:CreateLinearProjectile({
		Source = hHero1,
		Ability = ability1,
		vSpawnOrigin = hHero1:GetAbsOrigin(),

	    iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_NONE,
	    iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
	    iUnitTargetType = DOTA_UNIT_TARGET_NONE,

	    EffectName = 'particles/econ/events/ti9/high_five/high_five_lvl1_travel.vpcf',
	    fDistance = #(vPoint - hHero1:GetOrigin()),
	    fStartRadius = 10,
	    fEndRadius = 10,
		vVelocity = (vPoint - hHero1:GetOrigin()):Normalized() * 700,
	})
	ProjectileManager:CreateLinearProjectile({
		Source = hHero2,
		Ability = ability2,
		vSpawnOrigin = hHero2:GetAbsOrigin(),

	    iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_NONE,
	    iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
	    iUnitTargetType = DOTA_UNIT_TARGET_NONE,

	    EffectName = 'particles/econ/events/ti9/high_five/high_five_lvl1_travel.vpcf',
	    fDistance = #(vPoint - hHero2:GetOrigin()),
	    fStartRadius = 10,
	    fEndRadius = 10,
		vVelocity = (vPoint - hHero2:GetOrigin()):Normalized() * 700,
	})
end

LinkLuaModifier('modifier_high_five_custom_search', 'heroes/high_five_custom.lua', LUA_MODIFIER_MOTION_NONE)
modifier_high_five_custom_search = class({
	IsHidden 				= function(self) return true end,
	IsPurgable 				= function(self) return false end,
	IsDebuff 				= function(self) return false end,
	IsBuff                  = function(self) return true end,
	RemoveOnDeath 			= function(self) return false end,
	AllowIllusionDuplicate	= function(self) return true end,
	IsPermanent             = function(self) return true end,
	OnCreated 				= function(self)
		self.parent = self:GetParent()
		self.ability = self:GetAbility()
		self:StartIntervalThink(0.2)
	end,
	GetEffectAttachType 	= function(self) return PATTACH_OVERHEAD_FOLLOW end,
	GetEffectName 			= function(self) return 'particles/econ/events/ti9/high_five/high_five_lvl1_overhead.vpcf' end,

	OnDestroy 				= function(self)
		if self.bSearch or IsClient() then return end
		if not self.parent.__high_five_lose or self.parent.__high_five_lose <= HighFiveLimitLose then
			local UnitNameFormatted = "<font color='#70EA72'>" .. PlayerResource:GetPlayerName(self.parent:GetPlayerID()) .. "</font>"
			self.parent.__high_five_lose = (self.parent.__high_five_lose or 0) + 1
			CustomChat:MessageToAll(UnitNameFormatted .. " %%High_five_LeftHanging%%", -1)
		end
	end,

	GetRgbColor = function(self,target)
		if not GameMode.vTeamColors or not GameMode.vTeamColors[target:GetTeam()] then
			return 'rgb(255,255,255)'
		end
		local colorTeam = GameMode.vTeamColors[target:GetTeam()]
		return 'rgb(' .. colorTeam[1] .. ',' .. colorTeam[2] .. ',' .. colorTeam[3] .. ')'
	end,

	OnIntervalThink 		= function(self)
		if IsClient() then return end

		local units = FindUnitsInRadius( self.parent:GetTeamNumber(),
			self.parent:GetOrigin(),
			self.parent,
			800,
			DOTA_UNIT_TARGET_TEAM_BOTH,
			DOTA_UNIT_TARGET_HERO,
			DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
			FIND_CLOSEST,
			false )

		for k,v in pairs(units) do
			local modifier = v:FindModifierByName('modifier_high_five_custom_search')
			if modifier and v ~= self.parent  then
				use_high_five(self.parent,v)
				if self.bSearch then break end
				self.bSearch = true
				modifier.bSearch = true
				if (not self.parent.__high_five_succes or self.parent.__high_five_succes <= HighFiveLimitSucces) and
				   (not modifier.parent.__high_five_succes or modifier.parent.__high_five_succes <= HighFiveLimitSucces) then
					self.parent.__high_five_succes = (self.parent.__high_five_succes or 0) + 1
					local playerID_parent = self.parent:GetPlayerID()
					local playerID_search = modifier.parent:GetPlayerID()

					local heroNameParent = "<font color='".. self:GetRgbColor(self.parent) .. "'>" .. PlayerResource:GetPlayerName(playerID_parent) .. "</font>"
					local heroNameSearch = "<font color='".. self:GetRgbColor(modifier.parent) .. "'>" .. PlayerResource:GetPlayerName(playerID_search) .. "</font>"

					local str = heroNameParent .. ' %%and%% ' .. heroNameSearch .. ' %%High_five_just%%'
					CustomChat:MessageToAll(str, -1)
				end
				if self.ability and self.ability:GetAbilityName() == 'high_five_custom' then
					self.ability:EndCooldown()
				end

				if modifier.ability and modifier.ability:GetAbilityName() == 'high_five_custom' then
					modifier.ability:EndCooldown()
				end
				self:Destroy()
				modifier:Destroy()
				break
			end
		end
	end,
})
