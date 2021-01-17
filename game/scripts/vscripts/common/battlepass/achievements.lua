--[[
Achievements implementation goes here
Split apart from player_progress (at least for now)
]]

BP_Achievements = BP_Achievements or {}

function BP_Achievements:Init()
	BP_Achievements.players_achievements = {}
end

function BP_Achievements:OnDataArrival(players_achievements, definitions)
	if not players_achievements then print("[Battlepass] no players achievements supplied in incoming data!") return end
	if not definitions then print("[Battlepass] no achievements definitions supplied in incoming data!") return end

	BP_Achievements.players_achievements = players_achievements
	BP_Achievements.definitions = {}
	for _, val in pairs(definitions) do
		BP_Achievements.definitions[val.id] = val
	end
	ProgressTracker:ProcessAchievements(players_achievements, BP_Achievements.definitions)
end

function BP_Achievements:GetPlayerAchievements(player_id, with_progress)
	local steamid = Battlepass:GetSteamId(player_id)
	local achievements = self.players_achievements[steamid]
	if not achievements then return {} end
	if not with_progress then
		return achievements
	end
	local progressed_achievements = {}
	for _, achievement in pairs(achievements) do
		if achievement.init_progress ~= achievement.progress then
			table.insert(progressed_achievements, achievement)
			achievement.init_progress = achievement.progress
		end
	end
	return progressed_achievements
end


function BP_Achievements:GetPlayerAchievementById(player_id, achievement_id)
	local steamid = Battlepass:GetSteamId(player_id)
	local achievements = self.players_achievements[steamid]
	for _, achievement in pairs(achievements) do
		if achievement.achievementId == achievement_id then return achievement end
	end
end


function BP_Achievements:GetAchievementDefinition(achievement_id)
	return self.definitions[achievement_id]
end


setmetatable(BP_Achievements, {
	__index = function(tbl, key)
		local pl_table = rawget(tbl, "players_achievements")
		if pl_table and pl_table[key] then return pl_table[key] end
		return rawget(tbl, key)
	end
})
