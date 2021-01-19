ErrorTracking = ErrorTracking or {}
ErrorTracking.collectedErrors = ErrorTracking.collectedErrors or {}

if not IsInToolsMode() then
	debug.oldTraceback = debug.oldTraceback or debug.traceback
	debug.traceback = function(...)
		local stack = debug.oldTraceback(...)
		ErrorTracking.Collect(stack)

		for playerId = 0, 23 do
			if PlayerResource:IsValidPlayerID(playerId) and Supporters:IsDeveloper(playerId) then
				local player = PlayerResource:GetPlayer(playerId)
				if player then
					CustomGameEventManager:Send_ServerToPlayer(player, "server_print", { message = stack })
				end
			end
		end

		return stack
	end
end

function ErrorTracking.Collect(stack)
	stack = stack:gsub(": at 0x%x+", ": at 0x")
	ErrorTracking.collectedErrors[stack] = (ErrorTracking.collectedErrors[stack] or 0) + 1
end

local function printTryError(...)
	local stack = debug.traceback(...)
	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("emitError"), function() error(stack, 0) end, 0)
	return stack
end

local handleTryError = IsInToolsMode() and printTryError or debug.traceback
function ErrorTracking.Try(callback, ...)
	return xpcall(callback, handleTryError, ...)
end

Timers:CreateTimer({
	useGameTime = false,
	callback = function()
		if next(ErrorTracking.collectedErrors) ~= nil then
			WebApi:Send("match/script-errors", {
				matchId = tonumber(tostring(GameRules:Script_GetMatchID())),
				errors = ErrorTracking.collectedErrors,
				customGame = WebApi.customGame
			})
			ErrorTracking.collectedErrors = {}
		end
		return 60
	end
})
