require("common/game_perks/base_game_perk")

magician = class(base_game_perk)
local aoe_keywords = {
	"aoe",
	"area_of_effect",
	"radius",
}

local other_keywords = {
	scepter_range = true,
	arrow_range_multiplier = true,
	wave_width = true,
	agility_range = true,
	aftershock_range = true,
	echo_slam_damage_range = true,
	echo_slam_echo_search_range = true,
	echo_slam_echo_range = true,
	torrent_max_distance = true,
	cleave_ending_width = true,
	cleave_distance = true,
	ghostship_width = true,
	dragon_slave_distance = true,
	dragon_slave_width_initial = true,
	dragon_slave_width_end = true,
	width = true,
	arrow_width = true,
	requiem_line_width_start = true,
	requiem_line_width_end = true,
	orb_vision = true,
	hook_distance = true,
	flesh_heap_range = true,
	hook_width = true,
	end_distance = true,
	burrow_width = true,
	splash_width = true,
	splash_range = true,
	arrow_width = true,
	jump_range = true,
	bounce_range = true,
	attack_spill_range = true,
	attack_spill_width = true,
}

function magician:GetTexture() return "perkIcons/magician" end
function magician:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE
	}
end

function magician:GetModifierOverrideAbilitySpecial(keys)
	if (not keys.ability) or (not keys.ability_special_value) or (not aoe_keywords) then return 0 end

	for _, keyword in pairs(aoe_keywords) do
		if string.find(keys.ability_special_value, keyword) then
			return 1
		end
	end

	if (other_keywords and other_keywords[keys.ability_special_value]) then
		return 1
	end 

	return 0
end

function magician:GetModifierOverrideAbilitySpecialValue(keys)
	local value = keys.ability:GetLevelSpecialValueNoOverride(keys.ability_special_value, keys.ability_special_level)

	for _, keyword in pairs(aoe_keywords) do
		if string.find(keys.ability_special_value, keyword) then
			return value * (self.v or 1)
		end
	end

	if (other_keywords and other_keywords[keys.ability_special_value]) then
		return value * (self.v or 1)
	end 

	return value
end

magician_t0 = class(magician)
magician_t1 = class(magician)
magician_t2 = class(magician)

function magician_t0:OnCreated() self.v = 1.05 end
function magician_t1:OnCreated() self.v = 1.1 end
function magician_t2:OnCreated() self.v = 1.2 end
