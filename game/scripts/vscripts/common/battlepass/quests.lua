--[[
Quests, given to each player
From what i understood from schema (and without reading the doc), quests are daily
Includes:
- Getting list of quests
- Bulding quests track list to track them actively within game
- Submitting collected results to server
- Providing rewards for completion

Like BP_PlayersProgress, provides shortcut to get player data by steam id:
	BP_Quests["192073812129038"] -- as overloaded index operator, takes in str steamid64
Or with player id
	BP_Quests:GetQuests(1) -- as class method, takes in int player id
]]

BP_Quests = BP_Quests or {}


function BP_Quests:Init()
	BP_Quests.players_quests = {}

	CustomGameEventManager:RegisterListener("daily_quests:get_info",function(_, keys)
		self:SendQuestsToLoadingScreen(keys.PlayerID)
	end)
end


function BP_Quests:OnDataArrival(players_quests, definitions)
	if not players_quests then print("[Battlepass] no players quests supplied in incoming data!") return end
	if not definitions then print("[Battlepass] no quests definitions supplied in incoming data!") return end

	BP_Quests.players_quests = players_quests
	BP_Quests.definitions = {}
	for _, val in pairs(definitions) do
		BP_Quests.definitions[val.id] = val
	end
	ProgressTracker:ProcessQuests(players_quests)
end


function BP_Quests:GetPlayerQuests(player_id, with_progress)
	local steamid = Battlepass:GetSteamId(player_id)
	local quests = self.players_quests[steamid]
	if not quests then return {} end
	if not with_progress then
		return quests
	end
	progressed_quests = {}
	for _, quest in pairs(quests) do
		if quest.init_progress ~= quest.progress then 
			table.insert(progressed_quests, quest)
			quest.init_progress = quest.progress
		end
	end
	return progressed_quests
end

function BP_Quests:GetQuestDefinition(quest_id)
	return self.definitions[quest_id]
end

function BP_Quests:SendQuestsToLoadingScreen(player_id)
	if not player_id then return end
	if not Battlepass then
		Timers:CreateTimer(1, function()
			self:SendQuestsToLoadingScreen(player_id)
			return nil
		end)
		return
	end
	local quests = BP_Quests:GetPlayerQuests(player_id, false)
	local dataForClient = {quests = {}, battlepassInfo = {}}
	if #quests > 0 then
		for _, quest in pairs(quests) do
			local questDefinition = BP_Quests:GetQuestDefinition(quest.questId)
			table.insert(dataForClient.quests, {
				type = questDefinition.type,
				glory = questDefinition.reward and questDefinition.reward.glory or 0,
				exp = questDefinition.reward and questDefinition.reward.exp or 0,
				goal = questDefinition.description.goal,
				name = questDefinition.name,
				progress = quest.progress,
			})
		end
		dataForClient.battlepassInfo.level = BP_PlayerProgress:GetBPLevel(player_id) or 0
		dataForClient.battlepassInfo.currentExp = BP_PlayerProgress:GetCurrentExp(player_id) or 0
		dataForClient.battlepassInfo.maxExp = BP_PlayerProgress:GetRequiredExp(player_id) or 1000
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(player_id), "daily_quests:init_info", dataForClient )
	else
		Timers:CreateTimer(0.3, function()
			self:SendQuestsToLoadingScreen(player_id)
			return nil
		end)
	end
end

setmetatable(BP_Quests, {
	__index = function(tbl, key)
		local pl_table = rawget(tbl, "players_quests")
		if pl_table and pl_table[key] then return pl_table[key] end
		return rawget(tbl, key)
	end
})
