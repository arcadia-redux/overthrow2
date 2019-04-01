LinkLuaModifier( "modifier_silencer_new_int_steal_debuff", "modifier_silencer_new_int_steal", LUA_MODIFIER_MOTION_NONE )
modifier_silencer_new_int_steal = class({})

function modifier_silencer_new_int_steal:IsHidden() return false end
function modifier_silencer_new_int_steal:IsPurgable() return false end
function modifier_silencer_new_int_steal:IsPurgeException() return false end
function modifier_silencer_new_int_steal:RemoveOnDeath() return false end

function modifier_silencer_new_int_steal:DeclareFunctions()
	local funcs = 
	{
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_EVENT_ON_HERO_KILLED,
	}

	return funcs
end

function modifier_silencer_new_int_steal:GetModifierBonusStats_Intellect()
	return self:GetStackCount()
end

function modifier_silencer_new_int_steal:GetTexture()
    return "silencer_glaives_of_wisdom"
end

function modifier_silencer_new_int_steal:OnHeroKilled(keys)
    if IsServer() then
        local bonus = 1
        if self:GetCaster():FindAbilityByName("special_bonus_unique_silencer_2"):GetLevel() > 0 then
			bonus = bonus + 1
		end
        if keys.target and keys.target:IsRealHero() and (keys.reincarnate == false or keys.reincarnate == nil) and keys.target:GetTeam() ~= self:GetCaster():GetTeam() then
            if keys.attacker == self:GetCaster() then
                self:SetStackCount(self:GetStackCount()+bonus)
                Timers:CreateTimer(1, function()
                    if keys.target:IsAlive() then
                        keys.target:AddNewModifier(self:GetCaster(), nil, "modifier_silencer_new_int_steal_debuff", {bonus = bonus})
                    else
                        return 1
                    end
                end)
            else
                print(keys.target:GetNumAttackers())
                for i = 0, keys.target:GetNumAttackers() - 1 do
                    if self:GetCaster():GetPlayerID() == keys.target:GetAttacker(i) then
                        self:SetStackCount(self:GetStackCount()+bonus)
                        Timers:CreateTimer(1, function()
                            if keys.target:IsAlive() then
                                keys.target:AddNewModifier(self:GetCaster(), nil, "modifier_silencer_new_int_steal_debuff", {bonus = bonus})
                            else
                                return 1
                            end
                        end)
                        break
                    end
                end
            end
        end
	end
end

modifier_silencer_new_int_steal_debuff = class({})

function modifier_silencer_new_int_steal_debuff:IsHidden() return true end
function modifier_silencer_new_int_steal_debuff:IsPurgable() return false end
function modifier_silencer_new_int_steal_debuff:IsPurgeException() return false end
function modifier_silencer_new_int_steal_debuff:RemoveOnDeath() return false end

function modifier_silencer_new_int_steal_debuff:OnCreated(keys)
    if IsServer() then
        self:SetStackCount(0-keys.bonus)
	end
end

function modifier_silencer_new_int_steal_debuff:GetAttributes() 
    return MODIFIER_ATTRIBUTE_MULTIPLE + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_silencer_new_int_steal_debuff:DeclareFunctions()
	local funcs = 
	{
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	}

	return funcs
end

function modifier_silencer_new_int_steal_debuff:GetModifierBonusStats_Intellect()
	return self:GetStackCount()
end