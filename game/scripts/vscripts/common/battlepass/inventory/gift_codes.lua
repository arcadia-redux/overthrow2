GiftCodes = GiftCodes or {}

function GiftCodes:Init()
	GiftCodes.player_gift_codes = {}
	for player_id = 0, 23 do
		GiftCodes.player_gift_codes[player_id] = GiftCodes.player_gift_codes[player_id] or {}
	end
	CustomGameEventManager:RegisterListener("gift_codes:get_codes",function(_, keys)
		self:UpdateCodeDataClient(keys.PlayerID)
	end)
	CustomGameEventManager:RegisterListener("gift_codes:refresh_codes",function(_, keys)
		self:GetCodesFromServer(keys.PlayerID)
	end)
	CustomGameEventManager:RegisterListener("gift_codes:redeem_code",function(_, keys)
		local player_id = keys.PlayerID
		if not keys.code or not player_id then return end

		self:RedeemGiftClode(player_id, keys.code, keys.is_reclaim, false)
	end)
	CustomGameEventManager:RegisterListener("gift_codes:send_code_to_player",function(_, keys)
		self:SendCodeFromPlayerToPlayer(keys)
	end)
end

function GiftCodes:SendCodeFromPlayerToPlayer(data)
	local sender_id = data.PlayerID
	local target_id = data.target_id
	local code = data.code

	local code_data = self.player_gift_codes[sender_id]
	if not code_data or not code_data[code] then return end
	GiftCodes:RedeemGiftClode(target_id, code,false, true)

	local sender_steam_id = Battlepass:GetSteamId(sender_id)
	if not sender_steam_id then return end
	
	GiftCodes:RedeemGiftCodeLocal(sender_id, code, sender_steam_id)
	GiftCodes:UpdateCodeDataClient(sender_id)

	CustomGameEventManager:Send_ServerToAllClients( "gift_codes:code_was_gift", {
		sender_id = sender_id,
		target_id = target_id,
		payment_kind = code_data[code].paymentKind or ""
	} )
end

function GiftCodes:SetCodesForPlayer(player_id, code_list)
	for _, code in pairs(code_list) do
		self.player_gift_codes[player_id][code.code] = code
	end
end

function GiftCodes:AddCodeForPlayer(player_id, code)
	self.player_gift_codes[player_id][code.code] = code
end

function GiftCodes:RedeemGiftCodeLocal(player_owner_id, code, steam_id_redeemer)
	self.player_gift_codes[player_owner_id][code].redeemerSteamId = steam_id_redeemer
end
function GiftCodes:UpdateCodeDataClient(player_id)
	if not self.player_gift_codes[player_id] then return end
	
	local player = PlayerResource:GetPlayer(player_id)
	if not player then return end
	
	CustomGameEventManager:Send_ServerToPlayer(player, "gift_codes:update_codes", self.player_gift_codes[player_id])
end

function GiftCodes:GetCodesFromServer(player_id)
	local steam_id = Battlepass:GetSteamId(player_id)
	if not steam_id then return end
	
	WebApi:Send(
		"match/get_gift_codes",
		{ steamId = steam_id },
		function(response)
			if not response then return end
			GiftCodes:SetCodesForPlayer(player_id, response)
			GiftCodes:UpdateCodeDataClient(player_id)
			print("Successfully got player codes")
		end,
		function(e)
			print("error while got player codes: ", e)
		end
	)
end

function GiftCodes:RedeemGiftClode(player_id, code, is_reclaim, is_gift)
	is_reclaim = toboolean(is_reclaim)
	
	local steam_id = Battlepass:GetSteamId(player_id)
	if not steam_id then return end
	
	local player = PlayerResource:GetPlayer(player_id)
	if not player then return end
	
	WebApi:Send(
		"match/redeem_gift_code",
		{ steamId = steam_id, code = code, customGame = WebApi.customGame, mapName = GetMapName() },
		function(response)
			if response.supporterState then
				Supporters:SetPlayerState(player_id, response.supporterState)
				BP_Inventory:UpdateLocalItems(Battlepass:GetSteamId(player_id))
				BP_Inventory:UpdateAvailableItems(player_id)
			end

			if response.level then
				BP_PlayerProgress.players[steam_id].level = response.level
			end

			if response.exp then
				BP_PlayerProgress.players[steam_id].current_exp = response.exp
				BP_PlayerProgress.players[steam_id].required_exp = response.expRequired
			end

			if response.purchasedItem then
				BP_Inventory:AddItemLocal(response.purchasedItem.itemName, response.purchasedItem.steamId, response.purchasedItem.count)
			end

			if response.glory then
				BP_PlayerProgress:ChangeGlory(player_id, response.glory - BP_PlayerProgress:GetGlory(player_id))
			end

			if response.fortune then
				BP_PlayerProgress:SetFortune(player_id, response.fortune)
				BP_Masteries:UpdateFortune(player_id)
			end
			BP_PlayerProgress:UpdatePlayerInfo(player_id)

			if is_reclaim or (self.player_gift_codes[player_id] and self.player_gift_codes[player_id][code]) then
				GiftCodes:RedeemGiftCodeLocal(player_id, code, steam_id)
				GiftCodes:UpdateCodeDataClient(player_id)
			end
			if not is_gift then
				CustomGameEventManager:Send_ServerToPlayer(player, "gift_codes:code_used_from_server", { reason = GIFT_CODE_ACTIVATED })
			end
			
			print("Code was used successfully")
		end,
		function(e)
			print("error while use gift code: ", e)
			if not is_reclaim and not is_gift then
				local reason = GIFT_CODE_INCORRECT
				if e.detail and string.find(e.detail, "Code is already redeemed by") then
					reason = GIFT_CODE_USED
				end
				CustomGameEventManager:Send_ServerToPlayer(player, "gift_codes:code_used_from_server", {reason = reason})
			end
		end
	)
end
