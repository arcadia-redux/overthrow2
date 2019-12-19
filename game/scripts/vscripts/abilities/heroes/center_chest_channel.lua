center_chest_channel = class({})

function center_chest_channel:OnChannelFinish(interrupted)
	if interrupted then
		local newItem = CreateItem( "item_center_chest", nil, nil )
		local drop = CreateItemOnPositionForLaunch( self:GetCaster():GetAbsOrigin(), newItem )
		newItem:LaunchLootInitialHeight( false, 0, 300, 0.4, self:GetCaster():GetAbsOrigin() + RandomVector(200))
		newItem:SetContextThink( "KillLoot", function() return COverthrowGameMode:KillLoot( newItem, drop ) end, 20 )
	else
		COverthrowGameMode:SpecialItemAdd(self:GetCaster())
	end
end

LinkLuaModifier("modifier_center_chest_channel", "abilities/heroes/center_chest_channel", LUA_MODIFIER_MOTION_NONE)

modifier_center_chest_channel = class({})

function modifier_center_chest_channel:IsDebuff() return true end
function modifier_center_chest_channel:IsHidden() return true end
function modifier_center_chest_channel:IsPurgable() return true end
function modifier_center_chest_channel:IsStunDebuff() return false end
function modifier_center_chest_channel:RemoveOnDeath() return true end

function modifier_center_chest_channel:CheckState()
	local state = {
		[MODIFIER_STATE_ROOTED] = true,
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true
	}

	if IsServer() then
		return state
	end
end