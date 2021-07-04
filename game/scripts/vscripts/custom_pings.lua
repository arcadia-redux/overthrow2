CustomPings = CustomPings or class({})

C_PING_DEFAULT = 0
C_PING_DANGER = 1
C_PING_WAYPOINT = 2
C_PING_RETREAT = 3
C_PING_ATTACK = 4
C_PING_ENEMY_WARD = 5
C_PING_FRIENDLY_WARD = 6

PING_PARTICLES = {
	[C_PING_DEFAULT] = "particles/custom_pings/custom_ping_world.vpcf",
	[C_PING_DANGER] = "particles/custom_pings/custom_ping_danger.vpcf",
	[C_PING_WAYPOINT] = "particles/custom_pings/custom_ping_waypoint.vpcf",
	[C_PING_RETREAT] = "particles/custom_pings/custom_ping_retreat.vpcf",
	[C_PING_ATTACK] = "particles/ui_mouseactions/ping_attack.vpcf",
	[C_PING_ENEMY_WARD] = "particles/ui_mouseactions/ping_enemyward.vpcf",
	[C_PING_FRIENDLY_WARD] = "particles/ui_mouseactions/ping_friendlyward.vpcf",
}

function CustomPings:Init()
	self.players_color = {}
	
	CustomGameEventManager:RegisterListener("custom_ping:ping",function(_, data)
		self:Ping(data)
	end)
end

function CustomPings:Ping(data)
	local player_id = data.PlayerID
	if not player_id then return end

	local team = PlayerResource:GetTeam(player_id)
	if not team then return end

	local ping_type = data.type
	if not ping_type then return end

	local pos_x = data.pos["0"]
	local pos_y = data.pos["1"]
	local pos_for_ping = Vector(pos_x, pos_y, GetGroundHeight(Vector(pos_x, pos_y, 0), nil))

	if PING_PARTICLES[ping_type] then
		local ping_particle = ParticleManager:CreateParticleForTeam(PING_PARTICLES[ping_type], PATTACH_CUSTOMORIGIN, nil, team )
		ParticleManager:SetParticleControl(ping_particle, 0, pos_for_ping)
		ParticleManager:SetParticleControl(ping_particle, 5, Vector(3, 0, 0))
		if ping_type == C_PING_RETREAT then
			ParticleManager:SetParticleControl(ping_particle, 7, Vector(255, 10, 10))
		else
			local color = self:GetColor(player_id)
			ParticleManager:SetParticleControl(ping_particle, 7, Vector(color[1], color[2], color[3]))
		end
		Timers:CreateTimer(3.5, function()
			ParticleManager:DestroyParticle( ping_particle, false)
			ParticleManager:ReleaseParticleIndex( ping_particle )
		end)
	end

	CustomGameEventManager:Send_ServerToTeam(team, "custom_ping:ping_client", {
		pos = pos_for_ping,
		type = ping_type,
		player_id = player_id,
	})
end

-- Example for color: {255, 0, 0}
function CustomPings:SetColor(player_id, table_rgb_color)
	if not player_id or not table_rgb_color then return end
	self.players_color[player_id] = table_rgb_color
end

function CustomPings:GetColor(player_id)
	return self.players_color[player_id] and self.players_color[player_id] or {0, 0, 0}
end
