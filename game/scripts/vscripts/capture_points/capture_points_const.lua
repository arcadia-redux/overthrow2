PATH_CAPTURE_POINTS = "particles/capture_point_ring/"
INVISIBLE_MODEL = "models/development/invisiblebox.vmdl"
RADIUS_CAPTURE_POINT = 200
TIME_FOR_CAPTURE_POINT = 4
BASE_COLOR = Vector(220,220,220)
INTERVAL_THINK = 0.02
NEUTRAL_ITEM_FLY_TIME = 2.2
NEUTRAL_ITEM_MAX_TIME = 20
INIT_POSITION_FOR_ITEM = Vector(0, 0 ,500)
MAX_OFFSET_FOR_ITEM = 510

TEAMS_COLORS = {
	[DOTA_TEAM_GOODGUYS] = Vector(61, 210, 150),
	[DOTA_TEAM_BADGUYS]  = Vector(243, 201, 9),
	[DOTA_TEAM_CUSTOM_1] = Vector(197, 77, 168),
	[DOTA_TEAM_CUSTOM_2] = Vector(255, 108, 0),
	[DOTA_TEAM_CUSTOM_3] = Vector(52, 85, 255),
	[DOTA_TEAM_CUSTOM_4] = Vector(101, 212, 19),
	[DOTA_TEAM_CUSTOM_5] = Vector(129, 83, 54),
	[DOTA_TEAM_CUSTOM_6] = Vector(27, 192, 216),
	[DOTA_TEAM_CUSTOM_7] = Vector(199, 228, 13),
	[DOTA_TEAM_CUSTOM_8] = Vector(140, 42, 244),
	[DOTA_TEAM_NEUTRALS] = BASE_COLOR,
}

NEUTRAL_ITEMS = {
	[1] = {
		"item_elixer",
		"item_keen_optic",
		"item_poor_mans_shield",
		"item_iron_talon",
		"item_ironwood_tree",
		"item_royal_jelly",
		"item_mango_tree",
		"item_ocean_heart",
		"item_broom_handle",
		"item_trusty_shovel",
		"item_faded_broach",
		"item_arcane_ring",
		"item_third_eye",
		"item_phoenix_ash",
	},
	[2] = {
		"item_grove_bow",
		"item_vampire_fangs",
		"item_ring_of_aquila",
		"item_pupils_gift",
		"item_imp_claw",
		"item_philosophers_stone",
		"item_nether_shawl",
		"item_dragon_scale",
		"item_essence_ring",
		"item_clumsy_net",
		"item_vambrace",
		"item_tome_of_aghanim",
		"item_dimensional_doorway",
	},
	[3] = {
		"item_helm_of_the_undying",
		"item_craggy_coat",
		"item_greater_faerie_fire",
		"item_quickening_charm",
		"item_mind_breaker",
		"item_spider_legs",
		"item_enchanted_quiver",
		"item_paladin_sword",
		"item_orb_of_destruction",
		"item_titan_sliver",
		"item_horizon",
	},
	[4] = {
		"item_witless_shako",
		"item_timeless_relic",
		"item_spell_prism",
		"item_princes_knife",
		"item_flicker",
		"item_ninja_gear",
		"item_illusionsts_cape",
		"item_havoc_hammer",
		"item_panic_button",
	},
	[5] = {
		"item_force_boots",
		"item_desolator_2",
		"item_seer_stone",
		"item_mirror_shield",
		"item_fusion_rune",
		"item_ballista",
		"item_woodland_striders",
		"item_demonicon",
		"item_fallen_sky",
		"item_pirate_hat",
		"item_ex_machina",
		"item_apex",
		"item_greater_mango",
	}
}
