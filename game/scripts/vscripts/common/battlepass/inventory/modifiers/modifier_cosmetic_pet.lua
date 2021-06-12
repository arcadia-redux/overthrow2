modifier_cosmetic_pet = class( {} )

function modifier_cosmetic_pet:CheckState()
	return {
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_UNTARGETABLE] = true,
		[MODIFIER_STATE_MAGIC_IMMUNE] = true,
		[MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
		[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_OUT_OF_GAME] = true,
		[MODIFIER_STATE_NOT_ON_MINIMAP] = true
	}
end

function modifier_cosmetic_pet:OnCreated(data)
	self.ownerHero = data.hero
	self:StartIntervalThink(0.1)
end

DISTANCE_FOR_TELEPORT = 900
DISTANCE_FOR_MOVING = 200
DISTANCE_FOR_RUN_AWAY = 150
MIN_DISTANCE_MOVE = 170
MAX_DISTANCE_MOVE = 190

function modifier_cosmetic_pet:OnIntervalThink()
	if IsServer() then
		local pet = self:GetParent()
		local owner = pet:GetOwner()
		if not owner then return end
		local ownerPos = owner:GetAbsOrigin()
		local petPos = pet:GetAbsOrigin()
		local distance = ( ownerPos - petPos ):Length2D()
		local ownerDir = owner:GetForwardVector()
		local dir = ownerDir * RandomInt( MIN_DISTANCE_MOVE, MAX_DISTANCE_MOVE )

		if owner and owner:IsInvisible() then
			pet:AddNewModifier(pet, nil, "modifier_invisible", {})
		elseif pet:HasModifier("modifier_invisible") then
			pet:RemoveModifierByName("modifier_invisible")
		end
		
		if distance > DISTANCE_FOR_TELEPORT then
			local a = RandomInt( 60, 120 )
			if RandomInt( 1, 2 ) == 1 then
				a = a * -1
			end
			local r = RotatePosition( Vector( 0, 0, 0 ), QAngle( 0, a, 0 ), dir )
			pet:SetAbsOrigin( ownerPos + r )
			pet:SetForwardVector( ownerDir )
			FindClearSpaceForUnit( pet, ownerPos + r, true )
		elseif distance > DISTANCE_FOR_MOVING then
			local right = RotatePosition( Vector( 0, 0, 0 ), QAngle( 0, RandomInt( 70, 110 ) * -1, 0 ), dir ) + ownerPos
			local left = RotatePosition( Vector( 0, 0, 0 ), QAngle( 0, RandomInt( 70, 110 ), 0 ), dir ) + ownerPos

			if ( petPos - right ):Length2D() > ( petPos - left ):Length2D() then
				pet:MoveToPosition( left )
			else
				pet:MoveToPosition( right )
			end
		elseif distance < DISTANCE_FOR_RUN_AWAY then
			pet:MoveToPosition( ownerPos + ( petPos - ownerPos ):Normalized() * RandomInt( MIN_DISTANCE_MOVE, MAX_DISTANCE_MOVE ) )
		end
	end
end
