--[[
    Custom API for message in chat. It supports all HTML style (like color).
    ------------------------------------------
    CustomChat:MessageToAll(textData, SenderID) - Message to all chat
    CustomChat:MessageToTeam(textData, teamNumber, SenderID) - Message to select team chat
    ------------------------------------------

    You need use textData like this:

    local data = "Hero learn new ability - %%some_ability_with_localization%%"

    All parts between %%...%% will be localized for each client separately
]]--

if CustomChat == nil then CustomChat = class({}) end

function CustomChat:Init()
    CustomGameEventManager:RegisterListener("alt_ping_ability",function(_, data)
        self:AltPingAbility(data)
    end)
    CustomGameEventManager:RegisterListener("can_choose_ability",function(_, data)
        self:CanChooseAbility(data)
    end)
    CustomGameEventManager:RegisterListener("bet_on_team_allias",function(_, data)
        self:BetOnTeamAllias(data)
    end)
end

function CustomChat:AltPingAbility(data)
	local PlayerID = data.PlayerID
	if not PlayerID then return end
    self:MessageToAll(data.textData, PlayerID)
end

function CustomChat:CanChooseAbility(data)
	local PlayerID = data.PlayerID
	if not PlayerID then return end
	local player = PlayerResource:GetPlayer(PlayerID)
	if not player or player:IsNull() then return end
    self:MessageToTeam(data.textData, player:GetTeam(), PlayerID)
end

function CustomChat:BetOnTeamAllias(data)
	local PlayerID = data.PlayerID
	if not PlayerID then return end
	local player = PlayerResource:GetPlayer(PlayerID)
	if not player or player:IsNull() then return end
    self:MessageToTeam(data.textData, player:GetTeam(), PlayerID)
end

function CustomChat:MessageToAll(textData, SenderID)
	if not SenderID then return end
    CustomGameEventManager:Send_ServerToAllClients("custom_chat_message", { textData = textData, PlayerID = SenderID })
end

function CustomChat:MessageToTeam(textData, teamNumber, SenderID)
    for id=0,DOTA_MAX_PLAYERS do
        if PlayerResource:IsValidPlayer(id) then
        	local player = PlayerResource:GetPlayer(id)
        	if player and not player:IsNull() and (player:GetTeam() == teamNumber) then
            	CustomGameEventManager:Send_ServerToPlayer(
            		player, 
            		"custom_chat_message", 
            		{ textData = textData, PlayerID = SenderID, isTeam = true }
            	)
        	end
        end
    end
end
