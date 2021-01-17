MatchEvents = MatchEvents or {}
MatchEvents.DEFAULT_REQUEST_DELAY = IsInToolsMode() and 20 or 120
MatchEvents.RequestDelay = MatchEvents.RequestDelay or MatchEvents.DEFAULT_REQUEST_DELAY

function MatchEvents.ScheduleNextRequest()
	MatchEvents.RequestTimer = Timers:CreateTimer({
		useGameTime = false,
		endTime = MatchEvents.RequestDelay,
		callback = MatchEvents.SendRequest
	})
end

function MatchEvents.SendRequest()
	MatchEvents.RequestTimer = nil
	WebApi:Send(
		"match/events",
		{ matchId = tonumber(tostring(GameRules:GetMatchID())) },
		function(responses)
			MatchEvents.ScheduleNextRequest()
			for _, response in ipairs(responses) do
				MatchEvents.HandleResponse(response)
			end
		end,
		function() MatchEvents.ScheduleNextRequest() end
	)
end

MatchEvents.ResponseHandlers = MatchEvents.ResponseHandlers or {}
function MatchEvents.HandleResponse(response)
	local handler = MatchEvents.ResponseHandlers[response.kind]
	if not handler then
		error("No handler for " .. response.kind .. " response kind")
	end

	handler(response)
end

MatchEvents.ScheduleNextRequest()
