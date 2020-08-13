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
MAX_TIER = 5

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
	[1] = {},
	[2] = {},
	[3] = {},
	[4] = {},
	[5] = {},
}
for slevel, levelData in pairs(LoadKeyValues("scripts/npc/neutral_items.txt")) do
	if levelData and type(levelData) == "table" then
		for key,data in pairs(levelData) do
			if key =="items" then
				for sItemName,_ in pairs(data) do
					table.insert(NEUTRAL_ITEMS[tonumber(slevel)], sItemName)
				end
			end
		end
	end
end