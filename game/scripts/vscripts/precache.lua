local particles = {
	"particles/items2_fx/veil_of_discord.vpcf",
	"particles/econ/events/nexon_hero_compendium_2014/teleport_end_nexon_hero_cp_2014.vpcf",
	"particles/leader/leader_overhead.vpcf",
	"particles/last_hit/last_hit.vpcf",
	"particles/units/heroes/hero_zuus/zeus_taunt_coin.vpcf",
	"particles/addons_gameplay/player_deferred_light.vpcf",
	"particles/items_fx/black_king_bar_avatar.vpcf",
	"particles/treasure_courier_death.vpcf",
	"particles/econ/wards/f2p/f2p_ward/f2p_ward_true_sight_ambient.vpcf",
	"particles/econ/items/lone_druid/lone_druid_cauldron/lone_druid_bear_entangle_dust_cauldron.vpcf",
	"particles/newplayer_fx/npx_landslide_debris.vpcf",
	"particles/custom/items/hand_of_midas_cast.vpcf",
	"particles/custom/items/hand_of_midas_coin.vpcf",
	"particles/custom/items/core_pumpkin_owner.vpcf",
	"particles/econ/events/fall_major_2015/teleport_end_fallmjr_2015_ground_flash.vpcf",
	"particles/in_particles/core_door_open.vpcf",
	"particles/world_environmental_fx/lamp_flame_braser.vpcf",
	"particles/alert_ban_hammer.vpcf",
	"particles/patreon_gift_tier_1.vpcf",
	"particles/patreon_gift_tier_2.vpcf",
}
local sounds = {
	"soundevents/soundevents_custom.vsndevts",
	"soundevents/soundevents_world_custom.vsndevts",
	"soundevents/game_sounds_heroes/game_sounds_dragon_knight.vsndevts",
	"soundevents/soundevents_conquest.vsndevts",
	"soundevents/game_sounds_heroes/game_sounds_sniper.vsndevts",
	"soundevents/custom_soundboard_soundevents.vsndevts",
	"soundevents/game_sounds_heroes/game_sounds_chen",
	"soundevents/game_sounds_ui_imported.vsndevts",
}
local models = {
	"item_treasure_chest",
	"npc_dota_creature_basic_zombie",
	"npc_dota_creature_berserk_zombie",
	"npc_dota_treasure_courier",
	"npc_dummy_capture"
}
local unitsByNameSync = {
	"npc_dota_creature_basic_zombie",
	"npc_dota_creature_berserk_zombie",
	"npc_dota_treasure_courier",
	"npc_dummy_capture",
}
local itemsByNameSync = {
	"item_bag_of_gold",
	"item_treasure_chest",
}
local particle_folders = {
	"particles/units/heroes/hero_dragon_knight",
	"particles/units/heroes/hero_venomancer",
	"particles/units/heroes/hero_axe",
	"particles/units/heroes/hero_life_stealer",
}

return function(context)
	for _, p in pairs(itemsByNameSync) do
		PrecacheItemByNameSync(p, context)
	end
	for _, p in pairs(unitsByNameSync) do
		PrecacheUnitByNameSync(p, context)
	end
	for _, p in pairs(models) do
		PrecacheModel(p, context)
	end
	for _, p in pairs(particles) do
		PrecacheResource("particle", p, context)
	end
	for _, p in pairs(particle_folders) do
		PrecacheResource("particle_folder", p, context)
	end
	for _, p in pairs(sounds) do
		PrecacheResource("soundfile", p, context)
	end

	local heroeskv = LoadKeyValues("scripts/heroes.txt")
	for hero, _ in pairs(heroeskv) do
		PrecacheResource("soundfile", "soundevents/voscripts/game_sounds_vo_" .. string.sub(hero, 15) .. ".vsndevts", context)
	end

	local itemsCategories = LoadKeyValues("scripts/vscripts/common/battlepass/inventory/inventory_specs.kv").Category
	for category, _ in pairs(itemsCategories) do
		local itemsData = LoadKeyValues("scripts/vscripts/common/battlepass/inventory/battlepass_items/" .. category .. ".kv")
		for _, itemData in pairs(itemsData) do
			if itemData.Particles then
				for _, particleData in pairs(itemData.Particles) do
					PrecacheResource("particle", particleData.ParticleName, context)
				end
			end
			if itemData.Model then
				PrecacheResource("model", itemData.Model, context)
			end
		end
	end
end

