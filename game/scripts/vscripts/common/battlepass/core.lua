require("common/battlepass/player_progress")
require("common/battlepass/quests")
require("common/battlepass/chests")
require("common/battlepass/achievements")
require("common/battlepass/masteries")
require("common/battlepass/inventory/wear_functions")
require("common/battlepass/inventory/inventory")
require("common/battlepass/tracker/progress_tracker")
require("common/battlepass/cosmetic_abilities")

Battlepass = Battlepass or {}

function Battlepass:Init()
	print("[Battlepass] Init Core")
	Battlepass.steamid_map = {}
	Battlepass.playerid_map = {}

	ProgressTracker:Init()
	BP_PlayerProgress:Init()
	BP_Achievements:Init()
	BP_Quests:Init()
	BP_Masteries:Init()
	BP_Inventory:Init()
	WearFunc:Init()
	Feedback:Init()
	Cosmetics:Init()

	Battlepass:InitConversionTables()
end

function Battlepass:InitConversionTables()
	print("PLAYERS COUNT:", PlayerResource:GetPlayerCount())

	for player_id=0, 23 do
		if PlayerResource:IsValidPlayerID(player_id) then
			local steam_id = tostring(PlayerResource:GetSteamID(player_id))
			self.steamid_map[player_id] = steam_id
			self.playerid_map[steam_id] = player_id
		else
			print(player_id, type(player_id), "is not a valid player id")
		end
	end

	print("playerid -> steamid")
	table.print(self.steamid_map)
	print("steamid -> playerod")
	table.print(self.playerid_map)
end

-- when data from webapi arrives, it will be passed here
function Battlepass:OnDataArrival(data)
	print("[Battlepass] data arrived: ", data)
	Battlepass:InitConversionTables()
	if not data.players then print("[Battlepass] no players data in incoming data") return end

	local quests_definitions = data.quests
	local achievements_definition = data.achievements

	local achievements = {}
	local quests = {}
	local player_stats = {}
	local inventories = {}
	local equipped_items = {}

	for index, player_data in pairs(data.players) do
		local steam_id = player_data.steamId
		table.print(player_data)
		if player_data.achievements then
			achievements[steam_id] = player_data.achievements
		end
		if player_data.quests then
			quests[steam_id] = player_data.quests
		end
		if player_data.progress then
			player_stats[steam_id] = player_data.progress
		end
		if player_data.inventory then
			inventories[steam_id] = player_data.inventory
		end
		if player_data.equipped_items then
			equipped_items[steam_id] = player_data.equipped_items
		end
	end
	print("-------------------P ACHIEVEMENTS-------------------")
	table.print(achievements)
	print("----------------------QUESTS----------------------")
	table.print(quests)
	print("---------------------PLAYERS----------------------")
	table.print(player_stats)
	print("---------------------INVENTORIES----------------------")
	table.print(inventories)

	BP_Achievements:OnDataArrival(achievements, achievements_definition)
	BP_Quests:OnDataArrival(quests, quests_definitions)
	BP_PlayerProgress:OnDataArrival(player_stats)
	BP_Inventory:OnDataArrival(inventories, equipped_items)

	--print("GLORY:", BP_PlayerProgress["76561198132422587"].glory)
end


function Battlepass:GetSteamId(player_id)
	if Battlepass.steamid_map[player_id] then return Battlepass.steamid_map[player_id] end
	local steam_id = tostring(PlayerResource:GetSteamID(player_id))
	Battlepass.steamid_map[player_id] = steam_id
	return steam_id
end


function Battlepass:GetPlayerId(steam_id)
	if not Battlepass.playerid_map[steam_id] then
		print("[Battlepass:GetPlayerId] " .. steam_id .. " not found", type(steam_id))
	end
	return Battlepass.playerid_map[steam_id]
end
