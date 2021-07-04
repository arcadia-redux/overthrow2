const THINK = 0.01;
const PINGS_COUNT = 7;
const MIN_OFFSET = 18;
const MAX_OFFSET = 200;
const TRIGGER_TIME_FOR_WHEEL = 0.1;

// 80 - that's 1/2 of height/width from HUD_PING_WHEEL
const hud_wheel_half_width = 80;
const hud_wheel_half_height = 80;

const hud_ping_root_half_width = 25;
const hud_ping_root_half_height = 25;

const default_mapa_size = [8000, 8000, 0, 0];
const MAP_SIZES = {
	dota: default_mapa_size,
	dota_tournament: default_mapa_size,
	core_quartet: [7692, 7992],
	desert_duo: [5532, 5532],
	desert_octet: [4800, 5000, 0, 18], //Recompile
	desert_quintet: [4800, 5000, 0, 18], //Recompile
	forest_solo: [5532, 5532],
	mines_trio: [5532, 5532],
	temple_quartet: [5500, 5500],
};

const m_name = Game.GetMapInfo().map_display_name;
const map_data = MAP_SIZES[m_name] || default_mapa_size;

const WORLD_X = map_data[0];
const WORLD_Y = map_data[1];
const X_OFFSET = map_data[2] || 0;
const Y_OFFSET = map_data[3] || 0;

const C_PingsTypes = {
	DEFAULT: 0,
	DANGER: 1,
	WAYPOINT: 2,
	RETREAT: 3,
	ATTACK: 4,
	ENEMY_WARD: 5,
	FRIENDLY_WARD: 6,
};

const PINGS_DATA = {
	[C_PingsTypes.DEFAULT]: {
		image: "file://{resources}/images/custom_game/ping_icon_world_minimap.png",
		sound: "General.Ping",
	},
	[C_PingsTypes.DANGER]: {
		image: "file://{resources}/images/custom_game/import_dota/ping_danger_psd.png",
		sound: "General.PingWarning",
	},
	[C_PingsTypes.WAYPOINT]: {
		image: "file://{resources}/images/custom_game/ping_icon_waypoint_minimap.png",
		sound: "General.PingWaypoint",
	},
	[C_PingsTypes.RETREAT]: {
		image: "file://{resources}/images/custom_game/import_dota/ping_danger_psd.png",
		sound: "General.PingWarning",
	},
	[C_PingsTypes.ATTACK]: {
		image: "file://{resources}/images/custom_game/import_dota/ping_icon_attack_psd.png",
		sound: "General.PingAttack",
	},
	[C_PingsTypes.ENEMY_WARD]: {
		image: "file://{resources}/images/custom_game/import_dota/ping_icon_enemyward_psd.png",
		sound: "General.PingEnemyWard",
	},
	[C_PingsTypes.FRIENDLY_WARD]: {
		image: "file://{resources}/images/custom_game/import_dota/ping_icon_friendlyward_psd.png",
		sound: "General.PingFriendlyWard",
	},
};

/* HUD */
const HUD_ROOT_FOR_TRACKER = FindDotaHudElement("HeroRelicProgress");
const HUD_PING_WHEEL = $("#Custom_PingWheel");
const HUD_FOR_CUSTOM_PINGS = $("#CustomPings_Minimap");
const ROOT = $.GetContextPanel();

/* DOTA HUD */
const minimap = FindDotaHudElement("minimap_block");
const dota_hud = FindDotaHudElement("Hud");
