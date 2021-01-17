ProgressTracker = ProgressTracker or {}

require("common/battlepass/tracker/progress_callbacks")

LinkLuaModifier("modifier_tracker_dummy", "common/battlepass/tracker/modifier_tracker_dummy", LUA_MODIFIER_MOTION_NONE)

SERVER_UPDATE_DELAY = 10

function ProgressTracker:Init()
	print("[ProgressTracker] init")
	ProgressTracker = ProgressTracker or {}
	ProgressTracker.events_specs = LoadKeyValues("scripts/vscripts/common/battlepass/tracker/event_types.kv")
	for name, event_spec in pairs(self.events_specs) do
		if event_spec["Kind"] then
			event_spec["Kind"] = ProgressTracker:ParseKvToNumber(event_spec["Kind"])
		else
			event_spec["Kind"] = 0
		end

		if event_spec["Team"] then
			event_spec["Team"] = ProgressTracker:ParseKvToNumber(event_spec["Team"])
		else
			event_spec["Team"] = 0
		end

		if event_spec["Flags"] then
			event_spec["Flags"] = ProgressTracker:ParseKvToNumber(event_spec["Flags"])
		else
			event_spec["Flags"] = 0
		end
	end

	ProgressTracker.event_listeners = {}
	ProgressTracker.event_callbacks_map = {}
	ProgressTracker.server_update_scheduled = {}

	ProgressTracker.dummy_events_names = {
		["MODIFIER_EVENT_ON_ATTACK_LANDED"] = {MODIFIER_EVENT_ON_ATTACK_LANDED, "OnAttackLanded"},
		["MODIFIER_EVENT_ON_TAKEDAMAGE"] = {MODIFIER_EVENT_ON_TAKEDAMAGE, "OnTakeDamage"},
		["MODIFIER_EVENT_ON_DEATH"] = {MODIFIER_EVENT_ON_DEATH, "OnDeath"},
		["MODIFIER_EVENT_ON_HERO_KILLED"] = {MODIFIER_EVENT_ON_HERO_KILLED, "OnHeroKilled"},
		["MODIFIER_EVENT_ON_ABILITY_FULLY_CAST"] = {MODIFIER_EVENT_ON_ABILITY_FULLY_CAST, "OnAbilityFullyCast"},
		-- ["MODIFIER_EVENT_ON_UNIT_MOVED"] = {MODIFIER_EVENT_ON_UNIT_MOVED, "OnUnitMoved"},
	}

	-- entity used to listen to modifier events, to propagate them later
	ProgressTracker.thinker = CreateModifierThinker(
		nil,
		nil,
		"modifier_tracker_dummy",
		nil,
		Vector(0, 0, 0),
		DOTA_TEAM_NEUTRALS,
		false
	)
end

function ProgressTracker:ParseKvToNumber(str)
	local types = string.split(str, "|")
	local values = {}
	for i, m_type in pairs(types) do
		m_type = string.trim(m_type)
		table.insert(values, _G[m_type])
	end

	return bit.bor(unpack(values))
end



--[[
dummy gets event call
-> propagates to tracker
-> tracker calls all associated callbacks
-> they filter and apply changes
-> tracker schedules quests and achievements changes to submit to server, if they were
]]

-- TODO: achievements and quests schema casing is uneven, should switch those to camelCase too

function ProgressTracker:SetupListeners(data, player_entry)
	if not data then return end
	if not data.type then return end
	print("[ProgressTracker] Trackable Name:", data.name)
	if player_entry.completed then
		print("[ProgressTracker]", player_entry.steamId, "already completed trackable, ignoring")
		return
	end
	local m_type = data.type
	local event_spec = ProgressTracker.events_specs[m_type]
	if not event_spec then
		print("[ProgressTracker] event spec for event type <" .. m_type .. "> not found.")
		return
	end

	local event_name = event_spec["EventListener"]
	if not event_name then
		print("[ProgressTracker] <EventListener> for event type <" .. m_type .. "> not found.")
		return
	end

	if event_name ~= "EVENT_CUSTOM" then
		if not ProgressTracker.event_listeners[event_name] then
			ProgressTracker.event_listeners[event_name] = {}
		end
		table.insert(
			ProgressTracker.event_listeners[event_name],
			{
				callback = ProgressTracker:GetEventCallback(event_name, m_type),
				definition = data,
				player_entry = player_entry,
				spec = event_spec,
			}
		)
	end
end


function ProgressTracker:ProcessQuests(data)
	print("[ProgressTracker] processing quests")
	for steam_id, quests_list in pairs(data) do
		for i, val in pairs(quests_list) do
			if val.questId then
				val.init_progress = val.progress
				local quest_def = BP_Quests:GetQuestDefinition(val.questId)
				self:SetupListeners(quest_def, val)
			end
		end
	end
end


-- TODO: achievements tracking should be differently setuped
-- since we save achievements that only has some progress, unlike quests that are given out in the moment of player init
-- having a list of all achievements that should be tracked individially per player
function ProgressTracker:ProcessAchievements(player_data, data)
	print("[ProgressTracker] processing achievements")
	for _, achievement in pairs(data) do
		for steam_id, player_id in pairs(Battlepass.playerid_map) do
			local player_achievements = player_data[steam_id]
			local player_achievement = BP_Achievements:GetPlayerAchievementById(player_id, achievement.id)
			if player_achievement then
				player_achievement.init_progress = player_achievement.progress
				self:SetupListeners(achievement, player_achievement)
			else
				local temp_entry = {
					id = -1,
					achievementId = achievement.id,
					steamId = steam_id,
					completed = false,
					progress = 0,
					init_progress = 0,
					tier = 1,
				}
				table.insert(BP_Achievements.players_achievements[steam_id], temp_entry)
				self:SetupListeners(achievement, temp_entry)
			end
		end
	end
end


function ProgressTracker:EventTriggered(event_name, data)
	if not self.event_listeners[event_name] then return end
	for i, callback_data in pairs(self.event_listeners[event_name]) do
		local player_id = Battlepass:GetPlayerId(callback_data.player_entry.steamId)
		if player_id and callback_data.callback then
			local hero = PlayerResource:GetSelectedHeroEntity(player_id)
			if IsValidEntity(hero) and not callback_data.player_entry.completed then
				local filter_result = self:FilterCall(data, callback_data.spec, hero)
				if filter_result then
					local status, callback_result = ErrorTracking.Try(
						callback_data.callback, ProgressTracker, data, callback_data.definition, callback_data.player_entry, callback_data.spec, hero
					)
				end
			end
		end
	end
end

function ProgressTracker:FilterCall(event_data, spec, hero)
	local key = spec["DataAccessor"]
	if not key then return true end

	local object = event_data[key]

	local result = UnitFilter(
		object,
		spec["Team"],
		spec["Kind"],
		spec["Flags"],
		hero:GetTeamNumber()
	)

	-- print("Unit Filter result:", result )
	if result ~= 0 then return false end

	local lua_function = spec["LuaCheck"]

	if lua_function and object[lua_function] then
		local func_res = object[lua_function](object)
		-- print(lua_function, "result", func_res)
		if not func_res then return false end
	end

	return true
end


function ProgressTracker:GetEventCallback(event_name, event_type)
	local event_spec = self.events_specs[event_type]
	local defined_callback = event_spec["Callback"]

	if defined_callback then
		return ProgressTracker[defined_callback]
	end
	-- print("GENERAL CALLBACK EVENT NAME:", ProgressTracker.dummy_events_names[event_name][2])
	local callback_name = ProgressTracker.dummy_events_names[event_name][2]
	if callback_name then
		return ProgressTracker[callback_name]
	end
end


function ProgressTracker:UpdateProgress(player_entry, definition, progress_increment)
	player_entry.progress = player_entry.progress + progress_increment
	local description = definition.description or {}
	if player_entry.achievementId then
		local goal = description.goal or description["t"..player_entry.tier] or 100
		if player_entry.progress >= goal then
			local next_tier = player_entry.tier + 1
			local next_goal = description["t"..next_tier]
			if next_goal then
				player_entry.tier = next_tier
			else
				player_entry.progress = goal
				player_entry.completed = true
			end
		end
		return
	end
	local goal = description.goal or 100
	if player_entry.progress >= goal then
		-- print(player_entry.steamId, "reached goal of ", goal)
		player_entry.progress = goal
		player_entry.completed = true
	end
end

--[[
function ProgressTracker:ScheduleServerUpdate(player_id)
	if ProgressTracker.update_timer then
		Timers:RemoveTimer(ProgressTracker.update_timer)
	end

	ProgressTracker.server_update_scheduled[player_id] = true
	ProgressTracker.update_timer = Timers:CreateTimer(SERVER_UPDATE_DELAY, function()
		ProgressTracker.update_timer = nil
		print("Sending server update")
		local players = {}
		for p_id = 0, 23 do
			if PlayerResource:IsValidPlayerID(p_id) and ProgressTracker.server_update_scheduled[p_id] then
				print("adding ", p_id, "to players")
				local quests = BP_Quests:GetPlayerQuests(p_id, true)
				local achievements = BP_Achievements:GetPlayerAchievements(p_id, true)
				if next(quests) ~= nil or next(achievements) ~= nil then
					local steam_id = tostring(PlayerResource:GetSteamID(p_id))
					table.insert(players, { steamId = steam_id, quests = quests, achievements = achievements })
				end
			end
		end
		print("SUBMIT DATA:")
		table.print(players)
		print("----------------------------------------------------------------------------------------------------")
		WebApi:Send("battlepass/update-achievements-quests", { players = players })
		WebApi.scheduledUpdateSettingsPlayers = {}
	end)
end
]]

function ProgressTracker:SendServerUpdate()
	--print("Sending server update")
	local players = {}
	for p_id = 0, 23 do
		if PlayerResource:IsValidPlayerID(p_id) then
			print("adding ", p_id, "to players")
			local quests = BP_Quests:GetPlayerQuests(p_id, true)
			local achievements = BP_Achievements:GetPlayerAchievements(p_id, true)
			if next(quests) ~= nil or next(achievements) ~= nil then
				local steam_id = tostring(PlayerResource:GetSteamID(p_id))
				table.insert(players, { steamId = steam_id, quests = quests, achievements = achievements })
			end
		end
	end
	if not players or #players == 0 then print("no quests / achievements require server sync") return end
	--print("SUBMIT DATA:")
	table.print(players)
	--print("----------------------------------------------------------------------------------------------------")
	WebApi:Send("battlepass/update-achievements-quests", { players = players }, function(data)
		print("successfully updated achievements and quests!")
	end)
end
