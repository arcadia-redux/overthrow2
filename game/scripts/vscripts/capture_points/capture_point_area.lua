capture_point_area = class({})

local tTeamsItems = {}

function capture_point_area:IsHidden() return false end
function capture_point_area:IsPurgable() return false end
function capture_point_area:DestroyOnExpire() return false end

------------------------------------------------------------------------------
function capture_point_area:OnCreated()
	if not IsServer() then return end	
	local hParent = self:GetParent()
	self.nCaptureProgress = 0
	self.nRecaptutingTime = 0
	self.nMovingTime = 0
	self.nLifeTime = 0
	
	self.nCapturingTeam = DOTA_TEAM_NEUTRALS
	
	hParent:SetAbsOrigin(INIT_POSITION_FOR_ITEM)
	self.vStartPos = INIT_POSITION_FOR_ITEM

	local minXY, maxXY = COverthrowGameMode.m_GoldRadiusMin,  COverthrowGameMode.m_GoldRadiusMax
	self.vEndPos = GetRandomPathablePositionWithin(INIT_POSITION_FOR_ITEM, maxXY, minXY)
	if not self.vEndPos then
		self:StopPoint()
		return
	end
	self.vEndPos.z = 0
	self:ApplyHorizontalMotionController()
	self:ApplyVerticalMotionController()
end
------------------------------------------------------------------------------
function capture_point_area:StartSearch()
	if not IsServer() then return end
	local hParent = self:GetParent()
	Timers:CreateTimer(0.01, function()
		self.pCaptureRingEffect = ParticleManager:CreateParticle(PATH_CAPTURE_POINTS .. "capture_point_ring.vpcf", PATTACH_ABSORIGIN, hParent)

		ParticleManager:SetParticleControl(self.pCaptureRingEffect, 3, BASE_COLOR)
		ParticleManager:SetParticleControl(self.pCaptureRingEffect, 9, Vector(RADIUS_CAPTURE_POINT, 0, 0))

		self.vPosition = hParent:GetAbsOrigin()
		self:StartIntervalThink(INTERVAL_THINK)
	end)
end
------------------------------------------------------------------------------
function capture_point_area:OnIntervalThink()
	if not IsServer() then return end
	
	local tTargets = FindUnitsInRadius (
		DOTA_TEAM_NEUTRALS, 
		self.vPosition, 
		nil, 
		RADIUS_CAPTURE_POINT, 
		DOTA_UNIT_TARGET_TEAM_ENEMY, 
		DOTA_UNIT_TARGET_HERO, 
		DOTA_UNIT_TARGET_FLAG_NONE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
		FIND_ANY_ORDER, 
		false
	)
	local tPlayersInTeamsInRadius = {}
	for _, hTarget in pairs(tTargets) do
		if not tPlayersInTeamsInRadius[hTarget:GetTeamNumber()] then 
			tPlayersInTeamsInRadius[hTarget:GetTeamNumber()] = {} 
		end
		table.insert(tPlayersInTeamsInRadius[hTarget:GetTeamNumber()], hTarget)
	end

	local nTeamsCount = 0
	local nTemporallyCapturingTeam = DOTA_TEAM_NEUTRALS
	for nTeamNumber, _ in pairs(tPlayersInTeamsInRadius) do
		nTemporallyCapturingTeam = nTeamNumber
		nTeamsCount = nTeamsCount + 1
	end

	if nTeamsCount == 1 then
		if self.nCapturingTeam ~= nTemporallyCapturingTeam then
			if self.nRecaptutingTime <= 0 then
				self.nRecaptutingTime = self.nCaptureProgress
			end
		else
			self.nRecaptutingTime = 0
		end
		if self.nRecaptutingTime <= 0 then
			self.nCapturingTeam = nTemporallyCapturingTeam
		end
		self:StartCapturePoint(nTemporallyCapturingTeam)
	else
		if self.pCaptureInProgressEffect then
			ParticleManager:DestroyParticle(self.pCaptureInProgressEffect, false)
			self.pCaptureInProgressEffect = nil
		end

		if nTeamsCount == 0 then
			if self.nCaptureProgress > 0 then
				if self.nRecaptutingTime > 0 then
					self.nCaptureProgress = self.nRecaptutingTime
				end
				self.nCaptureProgress = math.max(self.nCaptureProgress - INTERVAL_THINK, 0)
				self.nRecaptutingTime = 0
				self:StartClock(DOTA_TEAM_NEUTRALS)
			else
				if self.pCaptureClockEffect then
					ParticleManager:DestroyParticle(self.pCaptureClockEffect, false)
					self.pCaptureClockEffect = nil
				end
			end
			self.nLifeTime = self.nLifeTime + INTERVAL_THINK
			if self.nLifeTime >= NEUTRAL_ITEM_MAX_TIME then
				self:StopPoint()
			end
		end
	end
end
------------------------------------------------------------------------------
function capture_point_area:SetRingColor(nTeamNumber)
	ParticleManager:SetParticleControl(self.pCaptureRingEffect, 3, TEAMS_COLORS[nTeamNumber])
end
------------------------------------------------------------------------------
function capture_point_area:StartCapturePoint(nTeamNumber)
	if not self.pCaptureInProgressEffect then
		self.pCaptureInProgressEffect = ParticleManager:CreateParticle(PATH_CAPTURE_POINTS .. "capture_point_ring_capturing.vpcf", PATTACH_ABSORIGIN, self:GetParent())
	end
	ParticleManager:SetParticleControl(self.pCaptureInProgressEffect, 9, Vector(RADIUS_CAPTURE_POINT, 0, 0))
	ParticleManager:SetParticleControl(self.pCaptureInProgressEffect, 3, TEAMS_COLORS[nTeamNumber])

	if self.nRecaptutingTime <= 0 then
		self.nCaptureProgress = self.nCaptureProgress + INTERVAL_THINK
		self:SetRingColor(nTeamNumber)
		if self.nCaptureProgress >= TIME_FOR_CAPTURE_POINT then
			self:AddRewardForTeam(nTeamNumber)
		end
	else
		self.nRecaptutingTime = self.nRecaptutingTime - INTERVAL_THINK
		self.nCaptureProgress = self.nCaptureProgress - INTERVAL_THINK
		if self.nRecaptutingTime <= 0 then
			self.nCaptureProgress = 0
			self:SetRingColor(nTeamNumber)
		end
	end
	self:StartClock(nTeamNumber)
end
------------------------------------------------------------------------------
function capture_point_area:StartClock(nTeamNumber)
	local fCreateTimeParticle = function()
		self.pCaptureClockEffect = ParticleManager:CreateParticle(PATH_CAPTURE_POINTS .. "capture_point_ring_clock.vpcf", PATTACH_ABSORIGIN, self:GetParent())
		ParticleManager:SetParticleControl(self.pCaptureClockEffect, 9, Vector(RADIUS_CAPTURE_POINT, 0, 0))
	end
	if not self.pCaptureClockEffect then
		fCreateTimeParticle()
	end

	if self.nCaptureProgress == 0 then
		ParticleManager:DestroyParticle(self.pCaptureClockEffect, false)
		self.pCaptureClockEffect = nil
		fCreateTimeParticle()
		self:SetRingColor(DOTA_TEAM_NEUTRALS)
	end
	
	ParticleManager:SetParticleControl(self.pCaptureClockEffect, 11, Vector(0, 0, 1))
	ParticleManager:SetParticleControl(self.pCaptureClockEffect, 3, TEAMS_COLORS[nTeamNumber])

	local nTime = self.nCaptureProgress
	if self.nRecaptutingTime > 0 then
		nTime = self.nRecaptutingTime
	end
	local theta = nTime / TIME_FOR_CAPTURE_POINT * 2 * math.pi
	ParticleManager:SetParticleControlForward(self.pCaptureClockEffect, 1, Vector(math.cos(theta), math.sin(theta), 0))
end
------------------------------------------------------------------------------
function capture_point_area:OnDestroy()
	local tParticles = {
		self.pCaptureClockEffect,
		self.pCaptureInProgressEffect,
		self.pCaptureRingEffect,
	}
	for _, particle in pairs(tParticles) do
		if particle then
			ParticleManager:DestroyParticle(particle, false)
		end
	end
end
------------------------------------------------------------------------------
function capture_point_area:AddRewardForTeam(nTeamNumber)
	if not IsServer() then return end
	local hParent = self:GetParent()
	if hParent.bAddedReward then return end
	hParent.bAddedReward = true
	self:GiveItemToTeam(nTeamNumber)
	self:StopPoint()
	--local pRewardBoom = ParticleManager:CreateParticle("particles/econ/events/ti10/blink_dagger_start_ti10_lvl2_sparkles.vpcf", PATTACH_ABSORIGIN, self:GetParent())
	--ParticleManager:SetParticleControl(pRewardBoom, 0, hParent:GetAbsOrigin())
end
------------------------------------------------------------------------------
function capture_point_area:StopPoint()
	local hParent = self:GetParent()
	self:Destroy()
	hParent:SetModel(INVISIBLE_MODEL)
	hParent:SetOriginalModel(INVISIBLE_MODEL)
	hParent:ForceKill(false)
end
------------------------------------------------------------------------------
function capture_point_area:GetItemsTable(nItemTier)
	local tBasicItemsList = table.deepcopy(NEUTRAL_ITEMS[nItemTier])
	local bUseBasicList = false
	for nIndex, sItemName in pairs(tBasicItemsList) do
		if tTeamsItems[self.nCapturingTeam][sItemName] then
			tBasicItemsList[nIndex] = nil
		else
			bUseBasicList = true
		end
	end
	if not bUseBasicList then
		local nNextTier = nItemTier + 1
		if nNextTier <= MAX_TIER then
			return self:GetItemsTable(nNextTier)
		else
			return {table = NEUTRAL_ITEMS[MAX_TIER], tier = MAX_TIER }
		end
	end
	return {table = tBasicItemsList, tier = nItemTier}
end
------------------------------------------------------------------------------
function capture_point_area:GiveItemToTeam(nTeamNumber)
	local player_id
	local d_inventroty
	for _player_id = 0, 23 do
		_d_inventroty = GetDummyInventory(_player_id)
		if PlayerResource:GetTeam(_player_id) == nTeamNumber and _d_inventroty then
			player_id = _player_id
			d_inventroty = _d_inventroty
		end
	end
	
	local tSortedTeams = COverthrowGameMode:GetSortedTeams()
	local nItemTier = 1
	for i = 1, #tSortedTeams do
		if tSortedTeams[i].team == nTeamNumber then
			if i <= (1 + math.max(#tSortedTeams - 3, 0) / 3) then
			elseif i >= (#tSortedTeams - math.max(#tSortedTeams - 3, 0) / 3) then
				nItemTier = nItemTier + 1
			end
		end
	end

	if COverthrowGameMode.leadingTeamScore >= (COverthrowGameMode.TEAM_KILLS_TO_WIN * 3 / 4) then
		nItemTier = nItemTier + 2
	elseif COverthrowGameMode.leadingTeamScore >= (COverthrowGameMode.TEAM_KILLS_TO_WIN / 2) then
		nItemTier = nItemTier + 1
	end
	nItemTier = math.min(nItemTier, 5)
	print_d("TIER FOR NEUTRAL DROP " .. nItemTier)
	if not NEUTRAL_ITEMS[nItemTier] then return end
	print_d("--CHECK IS OKAY--")
	tTeamsItems[nTeamNumber] = tTeamsItems[nTeamNumber] or {}
	local tItems = self:GetItemsTable(nItemTier)
	local sItemName = table.random(tItems.table)
	print_d("ITEMS TABLE:")
	for id, itemName in pairs(tItems.table) do
		print_d(	"  > ID: [" .. id .. "] Name: " .. itemName)
	end
	if not tTeamsItems[nTeamNumber][sItemName] then
		tTeamsItems[nTeamNumber][sItemName] = true
	end
	print_d("  >> CHOOSED DROP: [" .. sItemName .. "]")
	print_d("  >> TEAM FOR DROP: [" .. nTeamNumber .. "]")
	
	if player_id then 
		print_d("  >> TRY FOUND PLAYER BY ID: [" .. player_id .. "]") 
	else
		print_d("  >> FAIL BY FOUND PLAYER: [" .. player_id .. "]")
	end
	
	if not d_inventroty then
		print_d("  >> NO DUMMY INV, NEED RECREATE: [" .. player_id .. "]")
		local hero = PlayerResource:GetSelectedHeroEntity(player_id)
		CreateDummyInventoryForPlayer(player_id, hero)
		d_inventroty = GetDummyInventory(player_id)
	end
	
	if d_inventroty and sItemName then
		print_d("  >> POPUP NOTIFICATION FOR ITEM: [" .. sItemName .. "]")
		CustomGameEventManager:Send_ServerToAllClients( "OnPickedUpItem", {position = self:GetParent():GetAbsOrigin(), itemName = sItemName, tier = tItems.tier} )
		DropItem(sItemName, player_id, nTeamNumber)
	end
end
------------------------------------------------------------------------------
function capture_point_area:CheckState()
	local state = {
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
		[MODIFIER_STATE_MAGIC_IMMUNE] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_OUT_OF_GAME] = true,
	}
	return state
end
------------------------------------------------------------------------------
function capture_point_area:UpdateHorizontalMotion( me, dt )
	if not IsServer() then return end

	if not self:GetParent() or not self:GetParent():IsAlive() then
		self:GetParent():InterruptMotionControllers(true)
		return
	end

	self.nMovingTime = self.nMovingTime + dt

	if self.nMovingTime > NEUTRAL_ITEM_FLY_TIME then
		self.nMovingTime = NEUTRAL_ITEM_FLY_TIME
	end

	local fPct = self.nMovingTime/NEUTRAL_ITEM_FLY_TIME

	local vDir = (self.vEndPos - self.vStartPos)
	local nDistance = (self.vEndPos - self.vStartPos):Length()

	vDir.z = vDir.z + 10
	vDir = vDir:Normalized()

	local vPos = self.vStartPos + vDir*nDistance*fPct

	self:GetParent():SetAbsOrigin(vPos)

	if fPct > 0.97 then
		self:GetParent():InterruptMotionControllers(true)
		self:StartSearch()
	end
end
------------------------------------------------------------------------------
function capture_point_area:UpdateVerticalMotion( me, dt )
	if not IsServer() then return end

	if not self:GetParent() or not self:GetParent():IsAlive() then
		self:GetParent():InterruptMotionControllers(true)
		return
	end

	self.nMovingTime = self.nMovingTime + dt

	if self.nMovingTime > NEUTRAL_ITEM_FLY_TIME then
		self.nMovingTime = NEUTRAL_ITEM_FLY_TIME
	end

	local fPct = self.nMovingTime/NEUTRAL_ITEM_FLY_TIME

	local vDir = (self.vEndPos - self.vStartPos)
	local nDistance = (self.vEndPos - self.vStartPos):Length()

	vDir.z = vDir.z + 10
	vDir = vDir:Normalized()

	local vPos = self.vStartPos + vDir*nDistance*fPct

	local nOffset = 0

	if fPct < 0.5 then
		nOffset = fPct * MAX_OFFSET_FOR_ITEM * 2
	else
		nOffset = (1 - fPct) * MAX_OFFSET_FOR_ITEM * 2
	end
	vPos.z = vPos.z + nOffset

	self:GetParent():SetAbsOrigin(vPos)
	if fPct > 0.97 then
		self:GetParent():InterruptMotionControllers(true)
		self:StartSearch()
	end
end
------------------------------------------------------------------------------
