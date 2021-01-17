--[[
Players battle pass progress implementation should go here
This includes (but not limited to):
- experience (level)
- glory
- supplementary info like rerolls of abilities, heroes etc counts
- certain particles and items allowance by reaching certain level

Provides a shortcut to get player data via steamid:
	BP_PlayersProgress["6787120897182"].glory -- as overloaded index operator, takes in string steamid64
Or with player id
	BP_PlayersProgress:GetGlory(1) -- as separate function, takes in int player id
]]


BP_PlayerProgress = BP_PlayerProgress or {}


function BP_PlayerProgress:Init()
	BP_PlayerProgress.players = {}
end

function BP_PlayerProgress:OnDataArrival(players)
	if not players then print("[Battlepass] no player data supplied in incoming data!") return end

	BP_PlayerProgress.players = players
end

function BP_PlayerProgress:ChangeGlory(player_id, value)
	local steam_id = Battlepass:GetSteamId(player_id)
	if not self.players[steam_id] then return end
	self.players[steam_id].glory = self.players[steam_id].glory + value
end

function BP_PlayerProgress:GetGlory(player_id)
	local steam_id = Battlepass:GetSteamId(player_id)
	if not self.players[steam_id] then return end
	return self.players[steam_id].glory
end

function BP_PlayerProgress:GetFortune(player_id)
	local steam_id = Battlepass:GetSteamId(player_id)
	if not self.players[steam_id] then return end
	return self.players[steam_id].fortune
end

function BP_PlayerProgress:SetFortune(player_id, value)
	local steam_id = Battlepass:GetSteamId(player_id)
	if not self.players[steam_id] then return end
	self.players[steam_id].fortune = value
end

function BP_PlayerProgress:GetCurrentExp(player_id)
	local steam_id = Battlepass:GetSteamId(player_id)
	if not self.players[steam_id] then return end
	return self.players[steam_id].current_exp
end


function BP_PlayerProgress:GetRequiredExp(player_id)
	local steam_id = Battlepass:GetSteamId(player_id)
	if not self.players[steam_id] then return end
	return self.players[steam_id].required_exp
end


function BP_PlayerProgress:GetBPLevel(player_id)
	local steam_id = Battlepass:GetSteamId(player_id)
	if not self.players[steam_id] then return end
	return self.players[steam_id].level
end

function BP_PlayerProgress:UpdatePlayerInfo(player_id, blockRepeatPurchase)
	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(player_id), "battlepass_inventory:update_player_info", {
		playerLevel = self:GetBPLevel(player_id) or 0,
		playerCurrExp = self:GetCurrentExp(player_id) or 0,
		playerNeedExp = self:GetRequiredExp(player_id) or 0,
		boosterStatus = Supporters:GetLevel(player_id) or 0,
		boosterEndDate = Supporters:GetEndDate(player_id) or "",
		coins = self:GetGlory(player_id) or 0,
		blockRepeatPurchase = blockRepeatPurchase,
	})
	BP_Masteries:UpdateFortune(player_id)
	BP_Masteries:UpdateMasteriesForPlayer(player_id)
	BP_Masteries:UpdateEquippedMastery(player_id)
end

CONST_EXP_MULTIPLAYES_BY_SUPP_LVL = {
	[0] = 1,
	[1] = 2,
	[2] = 4,
}
CONST_PVE_ROUND_EXP = {
	[0] = 0,
	[1] = 2,
	[2] = 4,
}
CONST_PVE_BOSS_MULTIPLIER = 5

function BP_PlayerProgress:GetBPExpByRounds(nRoundFinished, playerId)
	local result = 0
	if nRoundFinished <= 20 then
		result =  nRoundFinished * CONST_PVE_ROUND_EXP[0]
	elseif nRoundFinished > 20 then
		local midRounds = math.min(nRoundFinished - 20, 30)
		local endRounds = math.max(nRoundFinished - 50, 0)
		local midBossesCount = math.floor(midRounds/10)
		local endBossesCount = math.floor(endRounds/10)
		local midBossesExp = midBossesCount * CONST_PVE_ROUND_EXP[1] * CONST_PVE_BOSS_MULTIPLIER
		local endBossesExp = endBossesCount * CONST_PVE_ROUND_EXP[2] * CONST_PVE_BOSS_MULTIPLIER

		local midRoundsExp = (midRounds - midBossesCount) * CONST_PVE_ROUND_EXP[1]
		local endRoundsExp = (endRounds - endBossesCount) * CONST_PVE_ROUND_EXP[2]

		result =  midRoundsExp + endRoundsExp + midBossesExp + endBossesExp
	end
	return result * CONST_EXP_MULTIPLAYES_BY_SUPP_LVL[Supporters:GetLevel(playerId)]
end

EXP_FOR_TOP_PLACES = {
	ffa = {
		[1] = 250,
		[2] = 225,
		[3] = 200,
		[4] = 175,
		[5] = 150,
		[6] = 125,
		[7] = 100,
		[8] = 75,
		[9] = 50,
		[10] = 25,
	},
	duos = {
		[1] = 250,
		[2] = 210,
		[3] = 170,
		[4] = 130,
		[5] = 90,
		[6] = 55,
		[7] = 25,
	},
}
function BP_PlayerProgress:GetBPExpByTop(place, playerId)
	local mapName = GetMapName()
	if EXP_FOR_TOP_PLACES[mapName] and EXP_FOR_TOP_PLACES[mapName][place] then
		return EXP_FOR_TOP_PLACES[mapName][place] * CONST_EXP_MULTIPLAYES_BY_SUPP_LVL[Supporters:GetLevel(playerId)]
	end
	return 0
end

setmetatable(BP_PlayerProgress, {
	__index = function(tbl, key)
		local pl_table = rawget(tbl, "players")
		if pl_table and pl_table[key] then return pl_table[key] end
		return rawget(tbl, key)
	end
})
