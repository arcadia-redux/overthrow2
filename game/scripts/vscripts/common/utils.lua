for _, listenerId in ipairs(registeredCustomEventListeners or {}) do
	CustomGameEventManager:UnregisterListener(listenerId)
end
registeredCustomEventListeners = {}
function RegisterCustomEventListener(eventName, callback)
	local listenerId = CustomGameEventManager:RegisterListener(eventName, function(_, args)
		callback(args)
	end)

	table.insert(registeredCustomEventListeners, listenerId)
end

for _, listenerId in ipairs(registeredGameEventListeners or {}) do
	StopListeningToGameEvent(listenerId)
end
registeredGameEventListeners = {}
function RegisterGameEventListener(eventName, callback)
	local listenerId = ListenToGameEvent(eventName, callback, nil)
	table.insert(registeredGameEventListeners, listenerId)
end

function DisplayError(playerId, message)
	local player = PlayerResource:GetPlayer(playerId)
	if player then
		CustomGameEventManager:Send_ServerToPlayer(player, "display_custom_error", { message = message })
	end
end

function string.starts(s, start)
	return string.sub(s, 1, #start) == start
end

function string.trim(s)
	return s:match'^()%s*$' and '' or s:match'^%s*(.*%S)'
end

function string.split(inputstr, separator)
	if separator == nil then
		separator = "%s"
	end
	local t={}
	for str in string.gmatch(inputstr, "([^"..separator.."]+)") do
		table.insert(t, str)
	end
	return t
end

function table.includes(t, value)
	for _, v in pairs(t) do
		if v == value then
			return true
		end
	end
	return false
end

function table.clone(t)
	local result = {}
	for k, v in pairs(t) do
		result[k] = v
	end
	return result
end

function table.shuffled(t)
	t = table.clone(t)
	for i = #t, 1, -1 do
		-- TODO: RandomInt
		local j = math.random(i)
		t[i], t[j] = t[j], t[i]
	end

	return t
end

function table.contains(t, v)
	for _, _v in pairs(t) do
		if _v == v then
			return true
		end
	end
end

function table.print(t, i)
	if not i then i = 0 end
	if not t then return end
    for k, v in pairs(t) do
    	if type(v) == "table" then
    		print(string.rep(" ", i) .. k .. " : ")
    		table.print(v, i+1)
    	else
        	print(string.rep(" ", i) .. k, v)
        end
    end
end

function table.random(t)
	local keys = {}
	for k, _ in pairs(t) do
		table.insert(keys, k)
	end
	local key = keys[RandomInt(1, # keys)]
	return t[key], key
end

function table.deepcopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[table.deepcopy(orig_key)] = table.deepcopy(orig_value)
		end
		setmetatable(copy, table.deepcopy(getmetatable(orig)))
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

function GetConnectionState(playerId)
	return PlayerResource:IsFakeClient(playerId) and DOTA_CONNECTION_STATE_CONNECTED or PlayerResource:GetConnectionState(playerId)
end

function GetPlayerIdBySteamId(id)
	for i = 0, 23 do
		if PlayerResource:IsValidPlayerID(i) and tostring(PlayerResource:GetSteamID(i)) == id then
			return i
		end
	end

	return -1
end

function GetRandomPathablePositionWithin( vPos, nRadius, nMinRadius )
	if IsServer() then
		local nMaxAttempts = 10
		local nAttempts = 0
		local vTryPos

		if nMinRadius == nil then
			nMinRadius = nRadius
		end

		repeat
			vTryPos = vPos + RandomVector( RandomFloat( nMinRadius, nRadius ) )

			nAttempts = nAttempts + 1
			if nAttempts >= nMaxAttempts then
				break
			end
		until ( GridNav:CanFindPath( vPos, vTryPos ) )

		return vTryPos
	end
end
