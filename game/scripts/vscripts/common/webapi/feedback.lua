Feedback = Feedback or {}
FEEDBACK_COOLDOWN = 30
function Feedback:Init()
	CustomGameEventManager:RegisterListener("feedback:send_feedback",function(_, keys)
		self:GetFeedbackFromPlayer(keys)
	end)
	CustomGameEventManager:RegisterListener("feedback:check_cooldown",function(_, keys)
		self:CheckCooldown(keys)
	end)
	self.feedbackCooldowns = {}
end

function Feedback:GetFeedbackFromPlayer(data)
	local playerId = data.PlayerID
	if not playerId then return end
	if not self.feedbackCooldowns[playerId] or 
		((GameRules:GetGameTime() - self.feedbackCooldowns[playerId]) > FEEDBACK_COOLDOWN) then
		self.feedbackCooldowns[playerId] = GameRules:GetGameTime()
		Timers:CreateTimer(FEEDBACK_COOLDOWN, function()
			CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerId), "feedback:update_cooldown", {cooldown = 0})
		end)
		local steamId = Battlepass.steamid_map[playerId]
		if not steamId then return end
		WebApi:Send(
			"match/suggestion",
			{
				steamId = steamId,
				content = data.text
			},
			function(data)
				print("Successfully send suggestion")
			end,
			function(e)
				print("error while send suggestion: ", e)
			end
		)
	end
end

function Feedback:CheckCooldown(data)
	local playerId = data.PlayerID
	if not playerId then return end
	local isCooldown = true
	if not self.feedbackCooldowns[playerId] or
		((GameRules:GetGameTime() - self.feedbackCooldowns[playerId]) > FEEDBACK_COOLDOWN) then
		isCooldown = false
	end
	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerId), "feedback:update_cooldown", {
		cooldown = isCooldown
	})
end
