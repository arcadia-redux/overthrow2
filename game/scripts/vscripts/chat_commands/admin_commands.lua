Commands = Commands or class({})

local admin_ids = {
    [104356809] = 1, -- Sheodar
	[93913347] = 1, -- Darklord
}

function IsAdmin(player)
    local steam_account_id = PlayerResource:GetSteamAccountID(player:GetPlayerID())
    return (admin_ids[steam_account_id] == 1)
end

function Commands:short(player, arg)
	print("cheat kills")
    if not IsAdmin(player) then return end
	local killToWinNew = 5
	local p1 = tonumber(arg[1])

    if p1 and type(p1) == "number" then killToWinNew = p1 end
	print("cheat kills")
	COverthrowGameMode.TEAM_KILLS_TO_WIN = killToWinNew
	CustomNetTables:SetTableValue( "game_state", "victory_condition", { kills_to_win = killToWinNew } );
end