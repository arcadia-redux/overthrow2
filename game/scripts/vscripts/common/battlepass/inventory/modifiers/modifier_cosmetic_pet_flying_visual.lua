modifier_cosmetic_pet_flying_visual = class( {} )

function modifier_cosmetic_pet_flying_visual:CheckState()
	return {
		[MODIFIER_STATE_FLYING ] = true
	}
end
