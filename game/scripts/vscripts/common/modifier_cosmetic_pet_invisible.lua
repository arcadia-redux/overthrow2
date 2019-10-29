modifier_cosmetic_pet_invisible = class( {} )

function modifier_cosmetic_pet_invisible:CheckState()
	return {
		[MODIFIER_STATE_TRUESIGHT_IMMUNE] = true,
		[MODIFIER_STATE_INVISIBLE] = true
	}
end