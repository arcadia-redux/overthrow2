--[[
Overthrow Game Mode
]]
_G.nCOUNTDOWNTIMER = 901
TRUSTED_HOSTS = {
	["76561198036748162"] = true,
	["76561198003571172"] = true,
	["76561198065780626"] = true, --https://www.twitch.tv/canko/
}

_G.DISCONNECT_TIMES = {}

_G.newStats = newStats or {}

_G.pairKillCounts = {}
LOCK_ANTI_FEED_TIME_SEC = 120
_G.timesOfTheLastKillings = {}

_G.personalCouriers = {}
_G.mainTeamCouriers = {}
_G.tPlayersMuted = {}

---------------------------------------------------------------------------
-- COverthrowGameMode class
---------------------------------------------------------------------------
if COverthrowGameMode == nil then
	_G.COverthrowGameMode = class({}) -- put COverthrowGameMode in the global scope
	--refer to: http://stackoverflow.com/questions/6586145/lua-require-with-global-local
end

---------------------------------------------------------------------------
-- Required .lua files
---------------------------------------------------------------------------
require("common/init")
require("utility_functions")
require("events")
require("items")
require("gpm_lib")
require("capture_points/capture_points_const")
require("neutral_items_drop_choice")

require("chat_commands/admin_commands")

WebApi.customGame = "Overthrow"

LinkLuaModifier("modifier_core_pumpkin_regeneration", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_core_spawn_movespeed", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_silencer_new_int_steal", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_patreon_courier", "couriers/modifier_patreon_courier", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_core_courier", "couriers/modifier_core_courier", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_courier_quartet", "couriers/modifier_courier_quartet", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_alert_before_kick_lua", LUA_MODIFIER_MOTION_NONE)

Precache = require( "precache" )

function Activate()
	-- Create our game mode and initialize it
	COverthrowGameMode:InitGameMode()
	-- Custom Spawn
	COverthrowGameMode:CustomSpawnCamps()
end

function COverthrowGameMode:CustomSpawnCamps()
	for name,_ in pairs(spawncamps) do
	spawnunits(name)
	end
end

---------------------------------------------------------------------------
-- Initializer
---------------------------------------------------------------------------
function COverthrowGameMode:InitGameMode()
	print( "Overthrow is loaded." )

--	CustomNetTables:SetTableValue( "test", "value 1", {} );
--	CustomNetTables:SetTableValue( "test", "value 2", { a = 1, b = 2 } );

	self.m_TeamColors = {}
	self.m_TeamColors[DOTA_TEAM_GOODGUYS] = { 61, 210, 150 }	--		Teal
	self.m_TeamColors[DOTA_TEAM_BADGUYS]  = { 243, 201, 9 }		--		Yellow
	self.m_TeamColors[DOTA_TEAM_CUSTOM_1] = { 197, 77, 168 }	--      Pink
	self.m_TeamColors[DOTA_TEAM_CUSTOM_2] = { 255, 108, 0 }		--		Orange
	self.m_TeamColors[DOTA_TEAM_CUSTOM_3] = { 52, 85, 255 }		--		Blue
	self.m_TeamColors[DOTA_TEAM_CUSTOM_4] = { 101, 212, 19 }	--		Green
	self.m_TeamColors[DOTA_TEAM_CUSTOM_5] = { 129, 83, 54 }		--		Brown
	self.m_TeamColors[DOTA_TEAM_CUSTOM_6] = { 27, 192, 216 }	--		Cyan
	self.m_TeamColors[DOTA_TEAM_CUSTOM_7] = { 199, 228, 13 }	--		Olive
	self.m_TeamColors[DOTA_TEAM_CUSTOM_8] = { 140, 42, 244 }	--		Purple

	for team = 0, (DOTA_TEAM_COUNT-1) do
		color = self.m_TeamColors[ team ]
		if color then
			SetTeamCustomHealthbarColor( team, color[1], color[2], color[3] )
		end
	end

	self.m_VictoryMessages = {}
	self.m_VictoryMessages[DOTA_TEAM_GOODGUYS] = "#VictoryMessage_GoodGuys"
	self.m_VictoryMessages[DOTA_TEAM_BADGUYS]  = "#VictoryMessage_BadGuys"
	self.m_VictoryMessages[DOTA_TEAM_CUSTOM_1] = "#VictoryMessage_Custom1"
	self.m_VictoryMessages[DOTA_TEAM_CUSTOM_2] = "#VictoryMessage_Custom2"
	self.m_VictoryMessages[DOTA_TEAM_CUSTOM_3] = "#VictoryMessage_Custom3"
	self.m_VictoryMessages[DOTA_TEAM_CUSTOM_4] = "#VictoryMessage_Custom4"
	self.m_VictoryMessages[DOTA_TEAM_CUSTOM_5] = "#VictoryMessage_Custom5"
	self.m_VictoryMessages[DOTA_TEAM_CUSTOM_6] = "#VictoryMessage_Custom6"
	self.m_VictoryMessages[DOTA_TEAM_CUSTOM_7] = "#VictoryMessage_Custom7"
	self.m_VictoryMessages[DOTA_TEAM_CUSTOM_8] = "#VictoryMessage_Custom8"

	self.m_GatheredShuffledTeams = {}
	self.numSpawnCamps = 5
	self.specialItem = ""
	self.spawnTime = 120
	self.nNextSpawnItemNumber = 1
	self.hasWarnedSpawn = false
	self.allSpawned = false
	self.leadingTeam = -1
	self.runnerupTeam = -1
	self.leadingTeamScore = 0
	self.runnerupTeamScore = 0
	self.isGameTied = true
	self.countdownEnabled = false
	self.itemSpawnIndex = 1
	self.itemSpawnLocation = Entities:FindByName( nil, "greevil" )
	self.heroSelectionStage = 0
	self.couriers = {}

	self.TEAM_KILLS_TO_WIN = 25
	self.CLOSE_TO_VICTORY_THRESHOLD = 5

	---------------------------------------------------------------------------

	self:GatherAndRegisterValidTeams()
	self:BuildCoreTeleportNightTargets()

	GameRules:GetGameModeEntity().COverthrowGameMode = self

	-- Adding Many Players
	if GetMapName() == "core_quartet" then
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 4 )
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 4 )
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_1, 4 )
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_2, 4 )
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_3, 4 )
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_4, 4 )
		self.m_GoldRadiusMin = 300
		self.m_GoldRadiusMax = 1400
		self.m_GoldDropPercent = 12
		self.m_NeutralItemDropPercent = 8
	elseif GetMapName() == "desert_octet" then
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 8 )
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 8 )
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_1, 8 )
		self.m_GoldRadiusMin = 300
		self.m_GoldRadiusMax = 1400
		self.m_GoldDropPercent = 12
		self.m_NeutralItemDropPercent = 8
	elseif GetMapName() == "desert_quintet" then
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 5 )
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 5 )
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_1, 5 )
		self.m_GoldRadiusMin = 300
		self.m_GoldRadiusMax = 1400
		self.m_GoldDropPercent = 8
		self.m_NeutralItemDropPercent = 6
	elseif GetMapName() == "temple_quartet" then
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 4 )
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 4 )
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_1, 4 )
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_2, 4 )
		self.m_GoldRadiusMin = 300
		self.m_GoldRadiusMax = 1400
		self.m_GoldDropPercent = 10
		self.m_NeutralItemDropPercent = 5
	elseif GetMapName() == "temple_sextet" then
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 6 )
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 6 )
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_1, 6 )
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_2, 6 )
		self.m_GoldRadiusMin = 300
		self.m_GoldRadiusMax = 1400
		self.m_GoldDropPercent = 12
		self.m_NeutralItemDropPercent = 8
	else
		self.m_GoldRadiusMin = 250
		self.m_GoldRadiusMax = 550
		self.m_GoldDropPercent = 4
		self.m_NeutralItemDropPercent = 4
	end

	-- Show the ending scoreboard immediately
	GameRules:SetCustomGameEndDelay( 0 )
	GameRules:SetCustomVictoryMessageDuration( 10 )
	GameRules:SetPreGameTime( 10 )
	GameRules:SetStrategyTime(IsInToolsMode() and 30 or 0)
	GameRules:SetShowcaseTime( 0.0 )
	--GameRules:SetHideKillMessageHeaders( true )
	GameRules:GetGameModeEntity():SetTopBarTeamValuesOverride( true )
	GameRules:GetGameModeEntity():SetTopBarTeamValuesVisible( false )
	GameRules:SetHideKillMessageHeaders( true )
	GameRules:SetUseUniversalShopMode( true )
	GameRules:SetCustomGameBansPerTeam(12)
	GameRules:GetGameModeEntity():SetLoseGoldOnDeath( false )
	GameRules:GetGameModeEntity():SetFountainPercentageHealthRegen( 0 )
	GameRules:GetGameModeEntity():SetFountainPercentageManaRegen( 0 )
	GameRules:GetGameModeEntity():SetFountainConstantManaRegen( 0 )
    GameRules:GetGameModeEntity():SetItemAddedToInventoryFilter( Dynamic_Wrap( COverthrowGameMode, "ItemAddedToInventoryFilter" ), self )
	GameRules:GetGameModeEntity():SetExecuteOrderFilter( Dynamic_Wrap( COverthrowGameMode, "ExecuteOrderFilter" ), self )
	GameRules:GetGameModeEntity():SetModifierGainedFilter( Dynamic_Wrap( COverthrowGameMode, "ModifierGainedFilter" ), self )
	GameRules:GetGameModeEntity():SetModifyGoldFilter( Dynamic_Wrap( COverthrowGameMode, "ModifyGoldFilter" ), self )
	GameRules:GetGameModeEntity():SetRuneSpawnFilter( Dynamic_Wrap( COverthrowGameMode, "RuneSpawnFilter" ), self )
	GameRules:GetGameModeEntity():SetDamageFilter( Dynamic_Wrap( COverthrowGameMode, "DamageFilter" ), self )
	GameRules:GetGameModeEntity():SetModifyExperienceFilter( Dynamic_Wrap(COverthrowGameMode, "FilterModifyExperience" ), self )
	GameRules:GetGameModeEntity():SetPauseEnabled(IsInToolsMode())
	GameRules:GetGameModeEntity():SetFreeCourierModeEnabled(true)

	GameRules:GetGameModeEntity():SetDraftingHeroPickSelectTimeOverride( 60 )
	GameRules:LockCustomGameSetupTeamAssignment(true)
	GameRules:SetCustomGameSetupAutoLaunchDelay(1)
	if IsInToolsMode() then
		GameRules:GetGameModeEntity():SetDraftingBanningTimeOverride(0)
		GameRules:SetCustomGameSetupAutoLaunchDelay(3)
	end

	ListenToGameEvent( "game_rules_state_change", Dynamic_Wrap( COverthrowGameMode, 'OnGameRulesStateChange' ), self )
	ListenToGameEvent( "npc_spawned", Dynamic_Wrap( COverthrowGameMode, "OnNPCSpawned" ), self )
	ListenToGameEvent( "dota_team_kill_credit", Dynamic_Wrap( COverthrowGameMode, 'OnTeamKillCredit' ), self )
	ListenToGameEvent( "entity_killed", Dynamic_Wrap( COverthrowGameMode, 'OnEntityKilled' ), self )
	ListenToGameEvent( "dota_item_picked_up", Dynamic_Wrap( COverthrowGameMode, "OnItemPickUp"), self )
	ListenToGameEvent( "dota_npc_goal_reached", Dynamic_Wrap( COverthrowGameMode, "OnNpcGoalReached" ), self )
	ListenToGameEvent( "player_chat", Dynamic_Wrap( COverthrowGameMode, "OnPlayerChat" ), self )
	ListenToGameEvent('dota_player_gained_level', Dynamic_Wrap(COverthrowGameMode, 'OnLevelUp'), self)

	CustomGameEventManager:RegisterListener("overthrow_item_choice_made", Dynamic_Wrap(COverthrowGameMode, "FinishItemPick"))

	Convars:RegisterCommand( "overthrow_force_item_drop", function(...) self:ForceSpawnItem() end, "Force an item drop.", FCVAR_CHEAT )
	Convars:RegisterCommand( "overthrow_force_gold_drop", function(...) self:ForceSpawnGold() end, "Force gold drop.", FCVAR_CHEAT )
	Convars:RegisterCommand( "overthrow_set_timer", function(...) return SetTimer( ... ) end, "Set the timer.", FCVAR_CHEAT )
	Convars:RegisterCommand( "overthrow_force_end_game", function(...) return self:EndGame( DOTA_TEAM_GOODGUYS ) end, "Force the game to end.", FCVAR_CHEAT )
	Convars:SetInt( "dota_server_side_animation_heroesonly", 0 )

	COverthrowGameMode:SetUpFountains()
	GameRules:GetGameModeEntity():SetThink( "OnThink", self, 1 )

	-- Spawning monsters
	spawncamps = {}
	for i = 1, self.numSpawnCamps do
		local campname = "camp"..i.."_path_customspawn"
		spawncamps[campname] =
		{
			NumberToSpawn = RandomInt(3,5),
			WaypointName = "camp"..i.."_path_wp1"
		}
	end

	p3bonus = {}
	for i = 0, PlayerResource:GetPlayerCount()-1 do
		p3bonus[i] = false
	end

	self.treasure_chest_spawns = {}
	self.current_chest = 0

	self.current_treasure_chest_rewards = {}

	self.pumpkin_spawns = {}
	for _, entity in ipairs(Entities:FindAllByName("item_pumpkin_spawn")) do
		table.insert(self.pumpkin_spawns, {
			position = entity:GetAbsOrigin(),
			nextSpawn = 0
		})
	end

	self.core_torches_main = Entities:FindAllByName("torch_main_entrance")
	self.core_torches_side = Entities:FindAllByName("torch_side_entrance")

	ListenToGameEvent("player_chat", function(data)

		if data.text == "-goblinsgreed" then
			local playerId = data.playerid
			local hero = PlayerResource:GetSelectedHeroEntity(playerId)
			local goblinsGreed = hero:FindAbilityByName("alchemist_goblins_greed_custom")
			if not goblinsGreed then return end

			local now = GameRules:GetDOTATime(false, true)
			if goblinsGreed.nextTime and goblinsGreed.nextTime < now then return end
			goblinsGreed.nextTime = now + 5

			local message = "Alchemist's bonus gold: " .. (goblinsGreed.coinBonusGold or 0) .. " from coins, " .. math.floor(goblinsGreed.gainBonusGold or 0) .. " from other sources"
			GameRules:SendCustomMessage(message, PlayerResource:GetTeam(playerId), -1)
		end

		if data.text == "-imout" then
			if tostring(PlayerResource:GetSteamID(data.playerid)) == "76561198054179075" then
				GameRules:SetSafeToLeave(true)
			end
		end
	end, nil)

	ListenToGameEvent("player_connect_full", function(data)
		local playerId = data.PlayerID
		local player = PlayerResource:GetPlayer(playerId)
		local isHost = GameRules:PlayerHasCustomGameHostPrivileges(player)
		local steamId = tostring(PlayerResource:GetSteamID(playerId))
		if TRUSTED_HOSTS[steamId] and isHost then
			GameRules:GetGameModeEntity():SetPauseEnabled(true)
			GameRules:LockCustomGameSetupTeamAssignment(false)
			GameRules:SetCustomGameSetupAutoLaunchDelay(15)
			if steamId == "76561198036748162" then --No Bans for Admiral Bulldog
				GameRules:GetGameModeEntity():SetDraftingBanningTimeOverride(0)
			end
		end
		local playerHero = PlayerResource:GetSelectedHeroEntity(playerId)
		if playerHero then
			CreateDummyInventoryForPlayer(playerId, playerHero)
		end
	end, nil)

	_G.kicks = {
		false,
		false,
		false,
		false,
		false
	}

	UniquePortraits:Init()
	Battlepass:Init()
end

---------------------------------------------------------------------------
-- Fix feed on tower
---------------------------------------------------------------------------
function COverthrowGameMode:DamageFilter(event)
	local death_unit = EntIndexToHScript(event.entindex_victim_const)
	local uniqueKey
	if event.entindex_attacker_const and event.entindex_victim_const then
		uniqueKey = event.entindex_attacker_const .. "_" .. event.entindex_victim_const

		local checkLastKill = true

		local deathUnitHasKill = _G.timesOfTheLastKillings[death_unit]

		if deathUnitHasKill then
			checkLastKill = (GameRules:GetGameTime() - _G.timesOfTheLastKillings[death_unit]) >= LOCK_ANTI_FEED_TIME_SEC
		end

		if _G.pairKillCounts[uniqueKey] and death_unit:IsRealHero() and (PlayerResource:GetSelectedHeroEntity(death_unit:GetPlayerID()) == death_unit) and checkLastKill then
			if death_unit:GetHealth() <= event.damage then
				_G.pairKillCounts[uniqueKey] = (_G.pairKillCounts[uniqueKey]) + 1
				death_unit:Kill(nil, death_unit)
				if _G.pairKillCounts[uniqueKey] == 2 then
					GameRules:SendCustomMessage("#stop_to_feed_on_enemy_base", death_unit:GetTeamNumber(), 0)
				end
			end
		end
	end

	return true
end

function COverthrowGameMode:FilterModifyExperience( event )
	local hero = EntIndexToHScript(event.hero_entindex_const)

	if hero and hero.IsTempestDouble and hero:IsTempestDouble() then
		return false
	end

	return true
end

function CDOTA_BaseNPC_Hero:AddExperienceCustom(xp, reason, applyBotDifficultyScaling, incrementTotal)
	if self:IsTempestDouble() then
		return
	end
	self:AddExperience(xp, reason, applyBotDifficultyScaling, incrementTotal)
end
---------------------------------------------------------------------------
-- Set up fountain regen
---------------------------------------------------------------------------
function COverthrowGameMode:SetUpFountains()

	LinkLuaModifier( "modifier_fountain_aura_lua", LUA_MODIFIER_MOTION_NONE )
	LinkLuaModifier( "modifier_fountain_aura_effect_lua", LUA_MODIFIER_MOTION_NONE )
	LinkLuaModifier( "modifier_disconnect_invulnerable", LUA_MODIFIER_MOTION_NONE )

	local fountainEntities = Entities:FindAllByClassname( "ent_dota_fountain")
	for _,fountainEnt in pairs( fountainEntities ) do
		--print("fountain unit " .. tostring( fountainEnt ) )
		fountainEnt:AddNewModifier( fountainEnt, fountainEnt, "modifier_fountain_aura_lua", {} )
	end
end

---------------------------------------------------------------------------
-- Get the color associated with a given teamID
---------------------------------------------------------------------------
function COverthrowGameMode:ColorForTeam( teamID )
	local color = self.m_TeamColors[ teamID ]
	if color == nil then
		color = { 255, 255, 255 } -- default to white
	end
	return color
end

---------------------------------------------------------------------------
---------------------------------------------------------------------------
function COverthrowGameMode:EndGame( victoryTeam )
	local overBoss = Entities:FindByName( nil, "@overboss" )
	if overBoss then
		local celebrate = overBoss:FindAbilityByName( 'dota_ability_celebrate' )
		if celebrate then
			overBoss:CastAbilityNoTarget( celebrate, -1 )
		end
	end
	print_d("FINALLY --- End Game. Team Leader: "..nTeamID)
	WebApi:AfterMatch(victoryTeam)
	GameRules:SetGameWinner( victoryTeam )
end


---------------------------------------------------------------------------
-- Put a label over a player's hero so people know who is on what team
---------------------------------------------------------------------------
function COverthrowGameMode:UpdatePlayerColor( nPlayerID )
	if not PlayerResource:HasSelectedHero( nPlayerID ) then
		return
	end

	local hero = PlayerResource:GetSelectedHeroEntity( nPlayerID )
	if hero == nil then
		return
	end

	local teamID = PlayerResource:GetTeam( nPlayerID )
	local color = self:ColorForTeam( teamID )
	PlayerResource:SetCustomPlayerColor( nPlayerID, color[1], color[2], color[3] )
end


---------------------------------------------------------------------------
-- Simple scoreboard using debug text
---------------------------------------------------------------------------
function COverthrowGameMode:UpdateScoreboard()
	local sortedTeams = self:GetSortedTeams()
	-- for _, t in ipairs(sortedTeams) do
	-- 	-- Scaleform UI Scoreboard
	-- 	FireGameEvent("score_board", {
	-- 		team_id = t.team,
	-- 		team_score = t.score
	-- 	})
	-- end
	-- Leader effects (moved from OnTeamKillCredit)
	local leader = sortedTeams[1].team
	self.leadingTeam = leader
	self.runnerupTeam = sortedTeams[2].team
	self.leadingTeamScore = sortedTeams[1].score
	self.runnerupTeamScore = sortedTeams[2].score
	self.isGameTied = sortedTeams[1].score == sortedTeams[2].score

	local allHeroes = HeroList:GetAllHeroes()
	for _,entity in pairs( allHeroes) do
		if entity:GetTeamNumber() == leader and sortedTeams[1].score ~= sortedTeams[2].score then
			if entity:IsAlive() == true then
				-- Attaching a particle to the leading team heroes
				local existingParticle = entity:Attribute_GetIntValue( "particleID", -1 )
	   			if existingParticle == -1 then
	   				local particleLeader = ParticleManager:CreateParticle( "particles/leader/leader_overhead.vpcf", PATTACH_OVERHEAD_FOLLOW, entity )
					ParticleManager:SetParticleControlEnt( particleLeader, PATTACH_OVERHEAD_FOLLOW, entity, PATTACH_OVERHEAD_FOLLOW, "follow_overhead", entity:GetAbsOrigin(), true )
					entity:Attribute_SetIntValue( "particleID", particleLeader )
				end
			else
				local particleLeader = entity:Attribute_GetIntValue( "particleID", -1 )
				if particleLeader ~= -1 then
					ParticleManager:DestroyParticle( particleLeader, true )
					entity:DeleteAttribute( "particleID" )
				end
			end
		else
			local particleLeader = entity:Attribute_GetIntValue( "particleID", -1 )
			if particleLeader ~= -1 then
				ParticleManager:DestroyParticle( particleLeader, true )
				entity:DeleteAttribute( "particleID" )
			end
		end
	end
end

---------------------------------------------------------------------------
-- Update player labels and the scoreboard
---------------------------------------------------------------------------
function COverthrowGameMode:OnThink()
	for nPlayerID = 0, (DOTA_MAX_TEAM_PLAYERS-1) do
		self:UpdatePlayerColor( nPlayerID )
	end

	self:UpdateScoreboard()

	local time = GameRules:GetDOTATime(false, true)
	if self.heroSelectionStage == 1 and time > -2 then
		self.heroSelectionStage = 2
	end
	if self.heroSelectionStage == 2 and time < -20 then
		self.heroSelectionStage = 3
		SmartRandom:PrepareAutoPick()
	end
	if self.heroSelectionStage == 3 and time > -2 then
		self.heroSelectionStage = 4
		SmartRandom:AutoPick()
	end

	if self.countdownEnabled then
		CountdownTimer()
		if nCOUNTDOWNTIMER == 30 then
			CustomGameEventManager:Send_ServerToAllClients( "timer_alert", {} )
		end
		if nCOUNTDOWNTIMER <= 0 then
			--Check to see if there's a tie
			if self.isGameTied == false then
				GameRules:SetCustomVictoryMessage( self.m_VictoryMessages[self.leadingTeam] )
				print_d("TIME OFF, BUT NOT KILL LIMIT --- End Game. Team Leader: "..self.leadingTeam)
				WebApi:AfterMatch(self.leadingTeam)
				GameRules:SetGameWinner( self.leadingTeam )
				self.countdownEnabled = false
			else
				self.TEAM_KILLS_TO_WIN = self.leadingTeamScore + 1
				local broadcast_killcount =
				{
					killcount = self.TEAM_KILLS_TO_WIN
				}
				CustomGameEventManager:Send_ServerToAllClients( "overtime_alert", broadcast_killcount )
			end
		end
	end

	if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		--Spawn Gold Bags
		COverthrowGameMode:ThinkGoldDrop()
		COverthrowGameMode:ThinkSpecialItemDrop()
		COverthrowGameMode:ThinkPumpkins()
	end

	for playerId = 0, 23 do
		if PlayerResource:IsValidPlayerID(playerId) then
			local connectionState = GetConnectionState(playerId)
			if not DISCONNECT_TIMES[playerId] then
				if connectionState == DOTA_CONNECTION_STATE_DISCONNECTED or connectionState == DOTA_CONNECTION_STATE_ABANDONED then
					DISCONNECT_TIMES[playerId] = GameRules:GetDOTATime(false, true)
				end
			elseif connectionState == DOTA_CONNECTION_STATE_CONNECTED then
				DISCONNECT_TIMES[playerId] = nil
			end
		end
	end

	if GetMapName() == "core_quartet" then
		local timeOfDay = GameRules:IsDaytime() and "day" or "night"

		for _, teamId in ipairs({ DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS, DOTA_TEAM_CUSTOM_1, DOTA_TEAM_CUSTOM_2, DOTA_TEAM_CUSTOM_3, DOTA_TEAM_CUSTOM_4 }) do
			local position = Entities:FindByName(nil, "teleport_" .. teamId .. "_" .. timeOfDay):GetAbsOrigin()
			AddFOWViewer(teamId, position, 500, 2, true)
		end

		if self.previousTimeOfDay ~= timeOfDay then
			self.previousTimeOfDay = timeOfDay

			for _, point in ipairs(Entities:FindAllByName("door_particle")) do
				local particleId = ParticleManager:CreateParticle("particles/in_particles/core_door_open.vpcf", PATTACH_WORLDORIGIN, nil)
				ParticleManager:SetParticleControl(particleId, 0, point:GetAbsOrigin())
			end

			for _, v in ipairs(self.core_torches_revealers or {}) do
				UTIL_Remove(v)
			end
			self.core_torches_revealers = {}
			local torches = GameRules:IsDaytime() and self.core_torches_main or self.core_torches_side
			for _, teamId in ipairs({ DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS, DOTA_TEAM_CUSTOM_1, DOTA_TEAM_CUSTOM_2, DOTA_TEAM_CUSTOM_3, DOTA_TEAM_CUSTOM_4 }) do
				for _, v in pairs(torches) do
					table.insert(self.core_torches_revealers, CreateUnitByName("npc_torch_vision_revealer", v:GetAbsOrigin(), true, nil, nil, teamId))
				end
			end

			for _, v in ipairs(self.core_torches_particles or {}) do
				ParticleManager:DestroyParticle(v, false)
			end
			self.core_torches_particles = {}
			for _, v in pairs(torches) do
				local particleId = ParticleManager:CreateParticle("particles/world_environmental_fx/lamp_flame_braser.vpcf", PATTACH_WORLDORIGIN, nil)
				ParticleManager:SetParticleControl(particleId, 0, v:GetAbsOrigin())
				table.insert(self.core_torches_particles, particleId)
			end
		end
	end

	return 1
end

---------------------------------------------------------------------------
-- Scan the map to see which teams have spawn points
---------------------------------------------------------------------------
function COverthrowGameMode:GatherAndRegisterValidTeams()
--	print( "GatherValidTeams:" )

	local foundTeams = {}
	for _, playerStart in pairs( Entities:FindAllByClassname( "info_player_start_dota" ) ) do
		foundTeams[  playerStart:GetTeam() ] = true
	end
	self.teams = foundTeams
	local numTeams = TableCount(foundTeams)
	print( "GatherValidTeams - Found spawns for a total of " .. numTeams .. " teams" )

	local foundTeamsList = {}
	for t, _ in pairs( foundTeams ) do
		table.insert( foundTeamsList, t )
	end

	if numTeams == 0 then
		print( "GatherValidTeams - NO team spawns detected, defaulting to GOOD/BAD" )
		table.insert( foundTeamsList, DOTA_TEAM_GOODGUYS )
		table.insert( foundTeamsList, DOTA_TEAM_BADGUYS )
		numTeams = 2
	end

	local maxPlayersPerValidTeam = math.floor( 10 / numTeams )

	self.m_GatheredShuffledTeams = table.shuffled( foundTeamsList )

	print( "Final shuffled team list:" )
	for _, team in pairs( self.m_GatheredShuffledTeams ) do
		print( " - " .. team .. " ( " .. GetTeamName( team ) .. " )" )
	end

	print( "Setting up teams:" )
	for team = 0, (DOTA_TEAM_COUNT-1) do
		local maxPlayers = 0
		if ( nil ~= TableFindKey( foundTeamsList, team ) ) then
			maxPlayers = maxPlayersPerValidTeam
		end
		print( " - " .. team .. " ( " .. GetTeamName( team ) .. " ) -> max players = " .. tostring(maxPlayers) )
		GameRules:SetCustomGameTeamMaxPlayers( team, maxPlayers )
	end
end

-- Spawning individual camps
function COverthrowGameMode:spawncamp(campname)
	spawnunits(campname)
end

-- Simple Custom Spawn
function spawnunits(campname)
	local spawndata = spawncamps[campname]
	local NumberToSpawn = spawndata.NumberToSpawn --How many to spawn
	local SpawnLocation = Entities:FindByName( nil, campname )
	local waypointlocation = Entities:FindByName ( nil, spawndata.WaypointName )
	if SpawnLocation == nil then
		return
	end

	local randomCreature =
		{
			"basic_zombie",
			"berserk_zombie"
		}
	local r = randomCreature[RandomInt(1,#randomCreature)]
	--print(r)
	for i = 1, NumberToSpawn do
		local creature = CreateUnitByName( "npc_dota_creature_" ..r , SpawnLocation:GetAbsOrigin() + RandomVector( RandomFloat( 0, 200 ) ), true, nil, nil, DOTA_TEAM_NEUTRALS )
		--print ("Spawning Camps")
		creature:SetInitialGoalEntity( waypointlocation )
	end
end

function COverthrowGameMode:ExecuteOrderFilter( filterTable )
	local orderType = filterTable.order_type
	local playerId = filterTable.issuer_player_id_const
	local target = filterTable.entindex_target ~= 0 and EntIndexToHScript(filterTable.entindex_target) or nil
	local ability = filterTable.entindex_ability ~= 0 and EntIndexToHScript(filterTable.entindex_ability) or nil
	-- `entindex_ability` is item id in some orders without entity
	if ability and not ability.GetAbilityName then ability = nil end
	local unit
	-- TODO: Are there orders without a unit?
	if filterTable.units and filterTable.units["0"] then
		unit = EntIndexToHScript(filterTable.units["0"])
	end

	if orderType == DOTA_UNIT_ORDER_CAST_TARGET then
		if target:GetName() == "npc_dota_seasonal_ti9_drums" then
			CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerId), "display_custom_error", { message = "#dota_hud_error_cant_cast_on_other" })
			return
		end
	end

	local itemsToBeDestroy = {
		["item_disable_help_custom"] = true,
		["item_mute_custom"] = true,
	}

	--if filterTable then
	--	filterTable = EditFilterToCourier(filterTable)
	--end

	if orderType == DOTA_UNIT_ORDER_GIVE_ITEM then
		if unit:IsTempestDouble() or target:IsTempestDouble() then return false end

		if ItemIsNeutral(ability:GetAbilityName()) then
			local targetID = target:GetPlayerOwnerID()
			if targetID and targetID~=playerId then
				if CheckCountOfNeutralItemsForPlayer(targetID) >= MAX_NEUTRAL_ITEMS_FOR_PLAYER then
					DisplayError(playerId, "#unit_still_have_a_lot_of_neutral_items")
					return
				end
			end
		end
	end

	if orderType == DOTA_UNIT_ORDER_DROP_ITEM or orderType == DOTA_UNIT_ORDER_EJECT_ITEM_FROM_STASH then
		if ability and itemsToBeDestroy[ability:GetAbilityName()] then
			ability:Destroy()
		end
	end

	if orderType == 25 then
		if ability and itemsToBeDestroy[ability:GetAbilityName()] then
			ability:Destroy()
		end
	end

	if orderType == DOTA_UNIT_ORDER_PICKUP_ITEM and playerId ~= -1 then
		if not target then return true end
		local pickedItem = target:GetContainedItem()
		if not pickedItem then return true end

		local itemName = pickedItem:GetAbilityName()
		if (unit and unit:IsCourier()) and (
			itemName == "item_bag_of_gold" or
			itemName == "item_treasure_chest" or
			itemName == "item_core_pumpkin"
		) then
			local position = target:GetAbsOrigin()
			filterTable["position_x"] = position.x
			filterTable["position_y"] = position.y
			filterTable["position_z"] = position.z
			filterTable["order_type"] = DOTA_UNIT_ORDER_MOVE_TO_POSITION
			return true
		end

		if itemName and itemName == "item_treasure_chest" and unit and unit:GetName() == "npc_dota_lone_druid_bear" then
			local position = target:GetAbsOrigin()
			filterTable["position_x"] = position.x
			filterTable["position_y"] = position.y
			filterTable["position_z"] = position.z
			filterTable["order_type"] = DOTA_UNIT_ORDER_MOVE_TO_POSITION
			return true
		end

		if ItemIsNeutral(itemName) then
			if CheckCountOfNeutralItemsForPlayer(playerId) >= MAX_NEUTRAL_ITEMS_FOR_PLAYER then
				DisplayError(playerId, "#player_still_have_a_lot_of_neutral_items")
				return
			end
		end
	end

	if orderType == 38 then
		if ItemIsNeutral(ability:GetAbilityName()) then
			if CheckCountOfNeutralItemsForPlayer(playerId) >= MAX_NEUTRAL_ITEMS_FOR_PLAYER then
				DisplayError(playerId, "#player_still_have_a_lot_of_neutral_items")
				return
			end
		end
	end

	local disableHelpResult = DisableHelp.ExecuteOrderFilter(orderType, ability, target, unit)
	if disableHelpResult == false then
		return false
	end

	if unit and unit:IsCourier()then
		if (orderType == DOTA_UNIT_ORDER_DROP_ITEM or orderType == DOTA_UNIT_ORDER_GIVE_ITEM) and IsValidEntity(ability) and ability:IsItem() then
			local purchaser = ability:GetPurchaser()
			if purchaser and purchaser:GetPlayerID() ~= playerId then
				-- CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerId), "display_custom_error", { message = "#hud_error_courier_cant_order_item" })
				return false
			end
		end
	end

	if orderType == DOTA_UNIT_ORDER_GIVE_ITEM and unit and unit:IsRealHero() and ( Supporters:GetLevel( unit:GetPlayerID() ) > 0 or IsInToolsMode() ) then
		if ability and ability:IsItem() and target and target:HasInventory() then
			unit:DropItemAtPositionImmediate( ability, target:GetAbsOrigin() + target:GetForwardVector() )
			Timers:CreateTimer( 0, function()
				ability:GetContainer():Destroy()
				target:AddItem( ability )
			end )

			return false
		end
	end

	return true
end

function COverthrowGameMode:ModifierGainedFilter(filterTable)
	local disableHelpResult = DisableHelp.ModifierGainedFilter(filterTable)
	if disableHelpResult == false then
		return false
	end

	if filterTable.name_const == "modifier_alert_before_kick" then
		local unit = filterTable.entindex_parent_const ~= 0 and EntIndexToHScript(filterTable.entindex_parent_const)
		unit:AddNewModifier(unit, unit, "modifier_alert_before_kick_lua", { duration = filterTable.duration })
	end
	local parent = filterTable.entindex_parent_const and filterTable.entindex_parent_const ~= 0 and EntIndexToHScript(filterTable.entindex_parent_const)
	local caster = filterTable.entindex_caster_const and filterTable.entindex_caster_const ~= 0 and EntIndexToHScript(filterTable.entindex_caster_const)

	if caster and parent and caster.bonusDebuffTime and (parent:GetTeamNumber() ~= caster:GetTeamNumber()) and filterTable.duration > 0 then
		filterTable.duration = filterTable.duration/100*caster.bonusDebuffTime + filterTable.duration
	end

	if parent and parent:GetUnitName() == "npc_dummy_inventory" and filterTable.name_const ~= "modifier_dummy_inventory_custom" then
		return false
	end

	return true
end

function COverthrowGameMode:ModifyGoldFilter(filterTable)
	local playerId = filterTable.player_id_const
	local hero = PlayerResource:GetSelectedHeroEntity(playerId)
	if hero then
		local goblinsGreed = hero:FindAbilityByName("alchemist_goblins_greed_custom")
		if goblinsGreed and goblinsGreed:GetLevel() > 0 then
			local bonusGold = filterTable.gold * (goblinsGreed:GetSpecialValueFor("gold_gain_multiplier") - 1)
			filterTable.gold = filterTable.gold + bonusGold
			goblinsGreed.gainBonusGold = (goblinsGreed.gainBonusGold or 0) + bonusGold

			if filterTable.gold > goblinsGreed:GetSpecialValueFor("message_min_gold") then
				SendOverheadEventMessage(PlayerResource:GetPlayer(playerId), OVERHEAD_ALERT_GOLD, hero, filterTable.gold, nil)
			end
		end
	end
	return true
end

local enabledRuneTypes = {
	DOTA_RUNE_DOUBLEDAMAGE,
	DOTA_RUNE_HASTE,
	DOTA_RUNE_ILLUSION,
	DOTA_RUNE_INVISIBILITY,
	DOTA_RUNE_REGENERATION,
	DOTA_RUNE_ARCANE,
}
function COverthrowGameMode:RuneSpawnFilter(filterTable)
	filterTable.rune_type = enabledRuneTypes[RandomInt(1, #enabledRuneTypes)]
	return true
end

function COverthrowGameMode:GetSortedTeams()
	local sortedTeams = {}
	for _, team in pairs(self.m_GatheredShuffledTeams) do
		table.insert(sortedTeams, { team = team, score = GetTeamHeroKills(team) })
	end

	table.sort(sortedTeams, function(a, b) return a.score > b.score end)
	return sortedTeams
end

local allCoreTeams = {
	DOTA_TEAM_BADGUYS,
	DOTA_TEAM_GOODGUYS,
	DOTA_TEAM_CUSTOM_1,
	DOTA_TEAM_CUSTOM_2,
	DOTA_TEAM_CUSTOM_3,
	DOTA_TEAM_CUSTOM_4,
}

function COverthrowGameMode:BuildCoreTeleportNightTargets()
	local combinations = {}

	local function iter(combination)
		if #combination + 1 <= #allCoreTeams then
			for _, team in ipairs(allCoreTeams) do
				if not table.includes(combination, team) then
					local copy = {}
					for i, v in ipairs(combination) do copy[i] = v end
					table.insert(copy, team)
					iter(copy)
				end
			end
			return
		end

		local valid = true
		for i, team in ipairs(combination) do
			local teamBefore = combination[i == 1 and 6 or i - 1]
			local teamAfter = combination[i == 6 and 1 or i + 1]

			local idInTeams
			for coreTeamId, coreTeam in ipairs(allCoreTeams) do
				if coreTeam == team then
					idInTeams = coreTeamId
					break
				end
			end
			local originalTeamBefore = allCoreTeams[idInTeams == 1 and 6 or idInTeams - 1]
			local originalTeamAfter = allCoreTeams[idInTeams == 6 and 1 or idInTeams + 1]

			if teamBefore == originalTeamBefore or teamBefore == originalTeamAfter or teamAfter == originalTeamBefore or teamAfter == originalTeamAfter then
				valid = false
				break
			end
		end
		if valid then
			table.insert(combinations, combination)
		end
	end
	iter({})

	self.coreTeleportNightTarget = combinations[RandomInt(1, #combinations)]
end

function COverthrowGameMode:GetCoreTeleportTarget(teamId)
	if GameRules:IsDaytime() then
		return Entities:FindByName(nil, "teleport_" .. teamId .. "_day"):GetAbsOrigin()
	end

	for oldTeamIndex, oldTeam in ipairs(allCoreTeams) do
		if oldTeam == teamId then
			local mappedTeam = self.coreTeleportNightTarget[oldTeamIndex]
			return Entities:FindByName(nil, "teleport_" .. mappedTeam .. "_day"):GetAbsOrigin()
		end
	end
end

local blockedChatPhraseCode = {
	[796] = true,
}

function COverthrowGameMode:OnPlayerChat(keys)
	local text = keys.text
	local playerid = keys.playerid
	if text == "-2" then
		COverthrowGameMode:P3Act(playerid)
	end
	if string.sub(text, 0,4) == "-ch " then
		local data = {}
		data.num = tonumber(string.sub(text, 5))
		if not blockedChatPhraseCode[data.num] then
			data.PlayerID = playerid
			SelectVO(data)
		end
	end

	local player = PlayerResource:GetPlayer(keys.playerid)

	local args = {}

	for i in string.gmatch(text, "%S+") do -- split string
		table.insert(args, i)
	end

	local command = args[1]
	table.remove(args, 1)

	local fixed_command = command.sub(command, 2)

	if Commands[fixed_command] then
		Commands[fixed_command](Commands, player, args)
	end
end

RegisterCustomEventListener("P3ButtonClick", function(keys)
	COverthrowGameMode:P3Act(keys.PlayerID)
end)

function COverthrowGameMode:P3Act(playerid)
	if p3bonus[playerid] ~= true then
		p3bonus[playerid] = true
		_G.nCOUNTDOWNTIMER = _G.nCOUNTDOWNTIMER + 30
		self.TEAM_KILLS_TO_WIN = self.TEAM_KILLS_TO_WIN + 2
		CustomNetTables:SetTableValue( "game_state", "victory_condition", { kills_to_win = self.TEAM_KILLS_TO_WIN } );
		CustomNetTables:SetTableValue( "game_state", "players_who_acted_on_victory_condition", p3bonus );
		GameRules:SendCustomMessage("#time_extended", -1, 0)
		EmitGlobalSound("Hero_Sniper.Tutorial_Intro_c")
	end
	local allPlayersVoted = true
	for playerId,state in pairs(p3bonus) do
		local playerConnectionState = PlayerResource:GetConnectionState(playerId)
		if state == false and (playerConnectionState == DOTA_CONNECTION_STATE_CONNECTED or playerConnectionState == DOTA_CONNECTION_STATE_NOT_YET_CONNECTED) then
			allPlayersVoted = false
		end
	end
	if allPlayersVoted then
		for playerId,_ in pairs(p3bonus) do
			p3bonus[playerId] = false
		end
		CustomNetTables:SetTableValue( "game_state", "players_who_acted_on_victory_condition", p3bonus );
	end
end

function DoesHeroHasFreeSlot(unit)
	for i=0,15 do
		if unit:GetItemInSlot(i) == nil then
			return true
		end
	end
	return false
end

local no_points_levels = {
	[17] = 1,
	[19] = 1,
	[21] = 1,
	[22] = 1,
}
function COverthrowGameMode:OnLevelUp(keys)
	local hero = EntIndexToHScript(keys.hero_entindex)
	local level = keys.level
	if no_points_levels[level] and hero:GetUnitName() == "npc_dota_hero_treant" then
		hero:SetAbilityPoints(hero:GetAbilityPoints() + 1)
	end
end

function COverthrowGameMode:ItemAddedToInventoryFilter( filterTable )
	if filterTable["item_entindex_const"] == nil then
		return true
	end
 	if filterTable["inventory_parent_entindex_const"] == nil then
		return true
	end
	local hInventoryParent = EntIndexToHScript( filterTable["inventory_parent_entindex_const"] )
	local hItem = EntIndexToHScript( filterTable["item_entindex_const"] )
	if hItem ~= nil and hInventoryParent ~= nil then
		local itemName = hItem:GetName()
		if hInventoryParent:IsRealHero() then
			local plyID = hInventoryParent:GetPlayerID()
			if not plyID then return true end
			local pitems = {
			--	"item_patreon_1",
			--	"item_patreon_2",
			--	"item_patreon_3",
			--	"item_patreon_4",
			--	"item_patreon_5",
			--	"item_patreon_6",
			--	"item_patreon_7",
			--	"item_patreon_8",
				"item_patreonbundle_1",
				"item_patreonbundle_2"
			}

			local supporter_level = Supporters:GetLevel(plyID)
			local pitem = false
			for i=1,#pitems do
				if itemName == pitems[i] then
					pitem = true
					break
				end
			end
			if pitem == true then
				if supporter_level < 1 then
					CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(plyID), "display_custom_error", { message = "#nopatreonerror" })
					UTIL_Remove(hItem)
					return false
				end
			end
			if itemName == "item_banhammer" then
				if supporter_level < 2 then
					CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(plyID), "display_custom_error", { message = "#nopatreonerror2" })
					UTIL_Remove(hItem)
					return false
				else
					if GameRules:GetDOTATime(false,false) < 1 then
						CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(plyID), "display_custom_error", { message = "#notyettime" })
						UTIL_Remove(hItem)
						return false
					end
				end
			end
			if itemName == "item_patreon_courier" then
				BlockToBuyCourier(plyID, hItem)
				return false
			end
		else
			local pitems = {
				"item_patreonbundle_1",
				"item_patreonbundle_2",
				"item_banhammer"
			}
			for i=1,#pitems do
				if itemName == pitems[i] then
					local prsh = hItem:GetPurchaser()
					if prsh ~= nil then
						if prsh:IsRealHero() then
							local prshID = prsh:GetPlayerID()
							if not prshID then
								UTIL_Remove(hItem)
								return false
							end
							if itemName == "item_patreon_courier" then
								BlockToBuyCourier(prshID, hItem)
								return false
							end
							local supporter_level = Supporters:GetLevel(prshID)
							if not supporter_level then
								UTIL_Remove(hItem)
								return false
							end
							if itemName == "item_banhammer" then
								if supporter_level < 2 then
									CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(prshID), "display_custom_error", { message = "#nopatreonerror2" })
									UTIL_Remove(hItem)
									return false
								else
									if GameRules:GetDOTATime(false,false) < 1 then
										CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(prshID), "display_custom_error", { message = "#notyettime" })
										UTIL_Remove(hItem)
										return false
									end
								end
							else
								if supporter_level < 1 then
									CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(prshID), "display_custom_error", { message = "#nopatreonerror" })
									UTIL_Remove(hItem)
									return false
								end
							end
						else
							UTIL_Remove(hItem)
							return false
						end
					else
						UTIL_Remove(hItem)
						return false
					end
				end
			end
		end

		local purchaser = hItem:GetPurchaser()
		if purchaser then
			local prshID = purchaser:GetPlayerID()
			local correctInventory = hInventoryParent:IsMainHero() or hInventoryParent:GetClassname() == "npc_dota_lone_druid_bear" or hInventoryParent:IsCourier()

			if (filterTable["item_parent_entindex_const"] > 0) and hItem and correctInventory then
				if not purchaser:CheckPersonalCooldown(hItem) then
					purchaser:RefundItem(hItem)
					return false
				end

				if not purchaser:IsMaxItemsForPlayer(hItem) then
					purchaser:RefundItem(hItem)
					return false
				end

				if hItem:ItemIsFastBuying(prshID) then
					return hItem:TransferToBuyer(hInventoryParent)
				end
			end
		end

	end

	if hItem and hItem.neutralDropInBase then
		hItem.neutralDropInBase = false
		local inventoryIsCorrect = hInventoryParent:IsMainHero() or hInventoryParent:GetClassname() == "npc_dota_lone_druid_bear" or hInventoryParent:IsCourier()
		local playerId = inventoryIsCorrect and hInventoryParent:GetPlayerOwnerID()
		if playerId then
			NotificationToAllPlayerOnTeam({
				PlayerID = playerId,
				item = filterTable.item_entindex_const,
			})
		end
	end

	return true
end

RegisterCustomEventListener("GetKicks", function(data)
	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(data.id), "setkicks", {kicks = _G.kicks})
end)

msgtimer = {}
RegisterCustomEventListener("OnTimerClick", function(keys)
	if msgtimer[keys.PlayerID] and GameRules:GetGameTime() - msgtimer[keys.PlayerID] < 3 then
		return
	end
	msgtimer[keys.PlayerID] = GameRules:GetGameTime()

	local time = math.abs(math.floor(_G.nCOUNTDOWNTIMER))
	local min = math.floor(time / 60)
	local sec = time - min * 60
	if min < 10 then min = "0" .. min end
	if sec < 10 then sec = "0" .. sec end
	Say(PlayerResource:GetPlayer(keys.PlayerID), min .. ":" .. sec, true)
end)

votimer = {}
vousedcol = {}
SelectVO = function(keys)
	local supporter_level = Supporters:GetLevel(keys.PlayerID)
	print(keys.num)
	local heroes = {
		"abaddon",
		"alchemist",
		"ancient_apparition",
		"antimage",
		"arc_warden",
		"axe",
		"bane",
		"batrider",
		"beastmaster",
		"bloodseeker",
		"bounty_hunter",
		"brewmaster",
		"bristleback",
		"broodmother",
		"centaur",
		"chaos_knight",
		"chen",
		"clinkz",
		"rattletrap",
		"crystal_maiden",
		"dark_seer",
		"dark_willow",
		"dazzle",
		"death_prophet",
		"disruptor",
		"doom_bringer",
		"dragon_knight",
		"drow_ranger",
		"earth_spirit",
		"earthshaker",
		"elder_titan",
		"ember_spirit",
		"enchantress",
		"enigma",
		"faceless_void",
		"grimstroke",
		"gyrocopter",
		"hoodwink",
		"huskar",
		"invoker",
		"wisp",
		"jakiro",
		"juggernaut",
		"keeper_of_the_light",
		"kunkka",
		"legion_commander",
		"leshrac",
		"lich",
		"life_stealer",
		"lina",
		"lion",
		"lone_druid",
		"luna",
		"lycan",
		"magnataur",
		"mars",
		"medusa",
		"meepo",
		"mirana",
		"monkey_king",
		"morphling",
		"naga_siren",
		"furion",
		"necrolyte",
		"night_stalker",
		"nyx_assassin",
		"ogre_magi",
		"omniknight",
		"oracle",
		"obsidian_destroyer",
		"pangolier",
		"phantom_assassin",
		"phantom_lancer",
		"phoenix",
		"puck",
		"pudge",
		"pugna",
		"queenofpain",
		"razor",
		"riki",
		"rubick",
		"sand_king",
		"shadow_demon",
		"nevermore",
		"shadow_shaman",
		"silencer",
		"skywrath_mage",
		"slardar",
		"slark",
		"snapfire",
		"sniper",
		"spectre",
		"spirit_breaker",
		"storm_spirit",
		"sven",
		"techies",
		"templar_assassin",
		"terrorblade",
		"tidehunter",
		"shredder",
		"tinker",
		"tiny",
		"treant",
		"troll_warlord",
		"tusk",
		"abyssal_underlord",
		"undying",
		"ursa",
		"vengefulspirit",
		"venomancer" ,
		"viper",
		"visage",
		"void_spirit",
		"warlock",
		"weaver",
		"windrunner",
		"winter_wyvern",
		"witch_doctor",
		"skeleton_king",
		"zuus"
	}
	local selectedid = 1
	local selectedid2 = nil
	local selectedstr = nil
	local startheronums = 110
	if keys.num >= startheronums then
		local locnum = keys.num - startheronums
		local mesarrs = {
			"_laugh",
			"_thank",
			"_deny",
			"_1",
			"_2",
			"_3",
			"_4",
			"_5"
		}
		selectedstr = heroes[math.floor(locnum/8)+1]..mesarrs[math.fmod(locnum,8)+1]
		print(math.floor(locnum/8))
		print(selectedstr)
		selectedid = math.floor(locnum/8)+2
		selectedid2 = math.fmod(locnum,8)+1
	else
		if keys.num < (startheronums-8) then
			local mesarrs = {
				--dp1
				"Applause",
				"Crash_and_Burn",
				"Crickets",
				"Party_Horn",
				"Rimshot",
				"Charge",
				"Drum_Roll",
				"Frog",
				--dp2
				"Headshake",
				"Kiss",
				"Ow",
				"Snore",
				"Bockbock",
				"Crybaby",
				"Sad_Trombone",
				"Yahoo",
				--misc
				"",
				"Sleighbells",
				"Sparkling_Celebration",
				"Greevil_Laughter",
				"Frostivus_Magic",
				"Ceremonial_Drums",
				"Oink_Oink",
				"Celebratory_Gong",
				--en an
				"patience",
				"wow",
				"all_dead",
				"brutal",
				"disastah",
				"oh_my_lord",
				"youre_a_hero",
				--en an2
				"that_was_questionable",
				"playing_to_win",
				"what_just_happened",
				"looking_spicy",
				"no_chill",
				"ding_ding_ding",
				"absolutely_perfect",
				"lets_play",
				--ch an
				"duiyou_ne",
				"wan_bu_liao_la",
				"po_liang_lu",
				"tian_huo",
				"jia_you",
				"zou_hao_bu_song",
				"liu_liu_liu",
				--ch an2
				"hu_lu_wa",
				"ni_qi_bu_qi",
				"gao_fu_shuai",
				"gan_ma_ne_xiong_di",
				"bai_tuo_shei_qu",
				"piao_liang",
				"lian_dou_xiu_wai_la",
				"zai_jian_le_bao_bei",
				--ru an
				"bozhe_ti_posmotri",
				"zhil_do_konsta",
				"ay_ay_ay",
				"ehto_g_g",
				"eto_prosto_netchto",
				"krasavchik",
				"bozhe_kak_eto_bolno",
				--ru an2
				"oy_oy_bezhat",
				"eto_nenormalno",
				"eto_sochno",
				"kreasa_kreasa",
				"kak_boyge_te_byechenya",
				"eto_ge_popayx_feeda",
				"da_da_da_nyet",
				"wot_eto_bru",
				--bp19
				"kooka_laugh",
				"monkey_biz",
				"orangutan_kiss",
				"skeeter",
				"crowd_groan",
				"head_bonk",
				"record_scratch",
				"ta_da",
				--epic
				"easiest_money",
				"echo_slama_jama",
				"next_level",
				"oy_oy_oy",
				"ta_daaaa",
				"ceeb",
				"goodness_gracious",
				--epic2
				"nakupuuu",
				"whats_cooking",
				"eughahaha",
				"glados_chat_21",
				"glados_chat_01",
				"glados_chat_07",
				"glados_chat_04",
				"",
				--kor cas
				"kor_yes_no",
				"kor_scan",
				"kor_immortality",
				"kor_roshan",
				"kor_yolo",
				"kor_million_dollar_house",
				"",
				"",
			}
			selectedstr = mesarrs[keys.num]
			selectedid2 = keys.num
		else
			local locnum = keys.num - (startheronums-8)
			local nowheroname = string.sub(PlayerResource:GetSelectedHeroEntity(keys.PlayerID):GetName(), 15)
			local mesarrs = {
				"_laugh",
				"_thank",
				"_deny",
				"_1",
				"_2",
				"_3",
				"_4",
				"_5"
			}
			local herolocid = 2
			for i=1, #heroes do
				if nowheroname == heroes[i] then
					break
				end
				herolocid = herolocid + 1
			end
			selectedstr = nowheroname..mesarrs[locnum+1]
			selectedid = herolocid
			print(selectedid)
			selectedid2 = locnum+1
		end
	end
	if selectedstr ~= nil and selectedid2 ~= nil then
		local heroesvo = {
			{
				--dp1
				"soundboard.applause",
				"soundboard.crash",
				"soundboard.cricket",
				"soundboard.party_horn",
				"soundboard.rimshot",
				"soundboard.charge",
				"soundboard.drum_roll",
				"soundboard.frog",
				--dp2
				"soundboard.headshake",
				"soundboard.kiss",
				"soundboard.ow",
				"soundboard.snore",
				"soundboard.bockbock",
				"soundboard.crybaby",
				"soundboard.sad_bone",
				"soundboard.yahoo",
				--misc
				"",
				"soundboard.sleighbells",
				"soundboard.new_year_celebration",
				"soundboard.greevil_laughs",
				"soundboard.frostivus_magic",
				"soundboard.new_year_drums",
				"soundboard.new_year_pig",
				"soundboard.new_year_gong",
				--en an
				"soundboard.patience",
				"soundboard.wow",
				"soundboard.all_dead",
				"soundboard.brutal",
				"soundboard.disastah",
				"soundboard.oh_my_lord",
				"soundboard.youre_a_hero",
				--en an2
				"soundboard.that_was_questionable",
				"soundboard.playing_to_win",
				"soundboard.what_just_happened",
				"soundboard.looking_spicy",
				"soundboard.no_chill",
				"custom_soundboard.ding_ding_ding",
				"soundboard.absolutely_perfect",
				"custom_soundboard.lets_play",
				--ch an
				"soundboard.duiyou_ne",
				"soundboard.wan_bu_liao_la",
				"soundboard.po_liang_lu",
				"soundboard.tian_huo",
				"soundboard.jia_you",
				"soundboard.zou_hao_bu_song",
				"soundboard.liu_liu_liu",
				--ch an2
				"soundboard.hu_lu_wa",
				"soundboard.ni_qi_bu_qi",
				"soundboard.gao_fu_shuai",
				"soundboard.gan_ma_ne_xiong_di",
				"soundboard.bai_tuo_shei_qu",
				"soundboard.piao_liang",
				"soundboard.lian_dou_xiu_wai_la",
				"soundboard.zai_jian_le_bao_bei",
				--ru an
				"soundboard.bozhe_ti_posmotri",
				"soundboard.zhil_do_konsta",
				"soundboard.ay_ay_ay",
				"soundboard.ehto_g_g",
				"soundboard.eto_prosto_netchto",
				"soundboard.krasavchik",
				"soundboard.bozhe_kak_eto_bolno",
				--ru an2
				"soundboard.oy_oy_bezhat",
				"soundboard.eto_nenormalno",
				"soundboard.eto_sochno",
				"soundboard.kreasa_kreasa",
				"soundboard.kak_boyge_te_byechenya",
				"soundboard.eto_ge_popayx_feeda",
				"soundboard.da_da_da_nyet",
				"soundboard.wot_eto_bru",
				--bp19
				"custom_soundboard.ti9_kooka_laugh",
				"custom_soundboard.ti9_monkey_biz",
				"custom_soundboard.ti9_orangutan_kiss",
				"custom_soundboard.ti9_skeeter",
				"custom_soundboard.ti9_crowd_groan",
				"custom_soundboard.ti9_head_bonk",
				"custom_soundboard.ti9_record_scratch",
				"custom_soundboard.ti9_ta_da",
				--epic
				"soundboard.easiest_money",
				"soundboard.echo_slama_jama",
				"soundboard.next_level",
				"soundboard.oy_oy_oy",
				"soundboard.ta_daaaa",
				"soundboard.ceeb",--need fix
				"soundboard.goodness_gracious",
				--epic2
				"soundboard.nakupuuu",
				"soundboard.whats_cooking",
				"soundboard.eughahaha",
				"custom_soundboard.glados_chat_01",
				"custom_soundboard.glados_chat_21",
				"custom_soundboard.glados_chat_04",
				"custom_soundboard.glados_chat_07",
				"",
				--kor cas
				"custom_soundboard.kor_yes_no",
				"custom_soundboard.kor_scan",
				"custom_soundboard.kor_immortality",
				"custom_soundboard.kor_roshan",
				"custom_soundboard.kor_yolo",
				"custom_soundboard.kor_million_dollar_house",
				"",
				"",
			},
			{
				"abaddon_abad_laugh_03",
				"abaddon_abad_failure_01",
				"abaddon_abad_deny_06",
				"abaddon_abad_lasthit_06",
				"abaddon_abad_death_03",
				"abaddon_abad_kill_05",
				"abaddon_abad_cast_01",
				"abaddon_abad_begin_02",
			},
			{
				"alchemist_alch_laugh_07",
				"alchemist_alch_win_03",
				"alchemist_alch_kill_02",
				"alchemist_alch_ability_rage_25",
				"alchemist_alch_kill_08",
				"alchemist_alch_ability_rage_14",
				"alchemist_alch_ability_failure_02",
				"alchemist_alch_respawn_06",
			},
			{
				"ancient_apparition_appa_laugh_01",
				"ancient_apparition_appa_lasthit_04",
				"ancient_apparition_appa_spawn_03",
				"ancient_apparition_appa_kill_03",
				"ancient_apparition_appa_death_13",
				"ancient_apparition_appa_purch_02",
				"ancient_apparition_appa_battlebegins_01",
				"ancient_apparition_appa_attack_05",
			},
			{
				"antimage_anti_laugh_05",
				"antimage_anti_respawn_09",
				"antimage_anti_deny_12",
				"antimage_anti_magicuser_01",
				"antimage_anti_ability_failure_02",
				"antimage_anti_kill_08",
				"antimage_anti_kill_13",
				"antimage_anti_rare_02",
			},
			{
				"arc_warden_arcwar_laugh_06",
				"arc_warden_arcwar_thanks_02",
				"arc_warden_arcwar_deny_10",
				"arc_warden_arcwar_flux_08",
				"arc_warden_arcwar_death_02",
				"arc_warden_arcwar_tempest_double_killed_04",
				"arc_warden_arcwar_failure_03",
				"arc_warden_arcwar_rival_05",
			},
			{
				"axe_axe_laugh_03",
				"axe_axe_drop_medium_01",
				"axe_axe_deny_08",
				"axe_axe_kill_06",
				"axe_axe_deny_16",
				"axe_axe_ability_failure_01",
				"axe_axe_rival_01",
				"axe_axe_rival_22",
				},
				{
				"bane_bane_battlebegins_01",
				"bane_bane_thanks_02",
				"bane_bane_ability_enfeeble_05",
				"bane_bane_spawn_02",
				"bane_bane_purch_04",
				"bane_bane_lasthit_11",
				"bane_bane_kill_13",
				"bane_bane_level_06",
				},
				{
				"batrider_bat_laugh_02",
				"batrider_bat_kill_10",
				"batrider_bat_cast_01",
				"batrider_bat_win_03",
				"batrider_bat_battlebegins_02",
				"batrider_bat_ability_napalm_06",
				"batrider_bat_kill_04",
				"batrider_bat_ability_failure_03",
				},
				{
				"beastmaster_beas_laugh_09",
				"beastmaster_beas_ability_summonsboar_04",
				"beastmaster_beas_rare_01",
				"beastmaster_beas_kill_07",
				"beastmaster_beas_immort_02",
				"beastmaster_beas_ability_animalsound_02",
				"beastmaster_beas_buysnecro_07",
				"beastmaster_beas_ability_animalsound_01",
				},
				{
				"bloodseeker_blod_laugh_02",
				"bloodseeker_blod_kill_10",
				"bloodseeker_blod_deny_09",
				"bloodseeker_blod_drop_rare_01",
				"bloodseeker_blod_respawn_10",
				"bloodseeker_blod_ability_rupture_02",
				"bloodseeker_blod_ability_rupture_04",
				"bloodseeker_blod_begin_01",
				},
				{
				"bounty_hunter_bount_laugh_07",
				"bounty_hunter_bount_ability_track_kill_02",
				"bounty_hunter_bount_rival_15",
				"bounty_hunter_bount_kill_14",
				"bounty_hunter_bount_bottle_01",
				"bounty_hunter_bount_ability_wind_attack_04",
				"bounty_hunter_bount_ability_track_02",
				"bounty_hunter_bount_level_09",
				},
				{
				"brewmaster_brew_laugh_07",
				"brewmaster_brew_ability_primalsplit_11",
				"brewmaster_brew_ability_failure_03",
				"brewmaster_brew_level_07",
				"brewmaster_brew_level_08",
				"brewmaster_brew_kill_03",
				"brewmaster_brew_respawn_01",
				"brewmaster_brew_spawn_05",
				},
				{
				"bristleback_bristle_laugh_02",
				"bristleback_bristle_levelup_04",
				"bristleback_bristle_rival_31",
				"bristleback_bristle_happy_04",
				"bristleback_bristle_deny_08",
				"bristleback_bristle_attack_22",
				"bristleback_bristle_kill_03",
				"bristleback_bristle_spawn_03",
				},
				{
				"broodmother_broo_laugh_06",
				"broodmother_broo_ability_spawn_05",
				"broodmother_broo_invis_02",
				"broodmother_broo_kill_16",
				"broodmother_broo_kill_01",
				"broodmother_broo_ability_spawn_10",
				"broodmother_broo_ability_spawn_06",
				"broodmother_broo_kill_17",
				},
				{
				"centaur_cent_laugh_04",
				"centaur_cent_thanks_02",
				"centaur_cent_hoof_stomp_03",
				"centaur_cent_happy_02",
				"centaur_cent_failure_03",
				"centaur_cent_rival_21",
				"centaur_cent_doub_edge_05",
				"centaur_cent_levelup_06",
				},
				{
				"chaos_knight_chaknight_laugh_15",
				"chaos_knight_chaknight_levelup_04",
				"chaos_knight_chaknight_rival_10",
				"chaos_knight_chaknight_kill_10",
				"chaos_knight_chaknight_ally_04",
				"chaos_knight_chaknight_ability_phantasm_03",
				"chaos_knight_chaknight_purch_02",
				"chaos_knight_chaknight_battlebegins_01",
				},
				{
				"chen_chen_laugh_09",
				"chen_chen_thanks_02",
				"chen_chen_cast_04",
				"chen_chen_kill_04",
				"chen_chen_death_04",
				"chen_chen_bottle_02",
				"chen_chen_battlebegins_01",
				"chen_chen_respawn_06",
				},
				{
				"clinkz_clinkz_laugh_02",
				"clinkz_clinkz_thanks_04",
				"clinkz_clinkz_deny_07",
				"clinkz_clinkz_kill_06",
				"clinkz_clinkz_rival_01",
				"clinkz_clinkz_rival_07",
				"clinkz_clinkz_win_01",
				"clinkz_clinkz_kill_02",
				},
				{
				"rattletrap_ratt_kill_14",
				"rattletrap_ratt_level_13",
				"rattletrap_ratt_deny_09",
				"rattletrap_ratt_ability_flare_12",
				"rattletrap_ratt_ability_batt_14",
				"rattletrap_ratt_ability_batt_09",
				"rattletrap_ratt_respawn_18",
				"rattletrap_ratt_win_05",
				},
				{
				"crystalmaiden_cm_laugh_06",
				"crystalmaiden_cm_thanks_02",
				"crystalmaiden_cm_deny_02",
				"crystalmaiden_cm_kill_09",
				"crystalmaiden_cm_levelup_04",
				"crystalmaiden_cm_respawn_05",
				"crystalmaiden_cm_respawn_06",
				"crystalmaiden_cm_levelup_03",
				},
				{
				"dark_seer_dkseer_laugh_10",
				"dark_seer_dkseer_move_03",
				"dark_seer_dkseer_deny_06",
				"dark_seer_dkseer_kill_01",
				"dark_seer_dkseer_firstblood_02",
				"dark_seer_dkseer_happy_02",
				"dark_seer_dkseer_ability_wallr_05",
				"dark_seer_dkseer_rare_02",
				},
				{
				"dark_willow_sylph_wheel_laugh_01",
				"dark_willow_sylph_drop_rare_02",
				"dark_willow_sylph_respawn_01",
				"dark_willow_sylph_wheel_deny_02",
				"dark_willow_sylph_kill_06",
				"dark_willow_sylph_wheel_all_05",
				"dark_willow_sylph_wheel_all_02",
				"dark_willow_sylph_wheel_all_10",
				},
				{
				"dazzle_dazz_laugh_02",
				"dazzle_dazz_purch_03",
				"dazzle_dazz_deny_08",
				"dazzle_dazz_kill_05",
				"dazzle_dazz_lasthit_08",
				"dazzle_dazz_ability_shadowave_02",
				"dazzle_dazz_kill_10",
				"dazzle_dazz_respawn_09",
				},
				{
				"death_prophet_dpro_laugh_012",
				"death_prophet_dpro_denyghost_04",
				"death_prophet_dpro_deny_16",
				"death_prophet_dpro_kill_11",
				"death_prophet_dpro_fail_05",
				"death_prophet_dpro_exorcism_15",
				"death_prophet_dpro_kill_18",
				"death_prophet_dpro_levelup_10",
				},
				{
				"disruptor_dis_laugh_03",
				"disruptor_dis_purch_02",
				"disruptor_dis_staticstorm_06",
				"disruptor_dis_respawn_10",
				"disruptor_dis_kill_10",
				"disruptor_dis_underattack_02",
				"disruptor_dis_rare_02",
				"disruptor_dis_illus_02",
				},
				{
				"doom_bringer_doom_laugh_10",
				"doom_bringer_doom_happy_01",
				"doom_bringer_doom_ability_lvldeath_03",
				"doom_bringer_doom_level_05",
				"doom_bringer_doom_respawn_12",
				"doom_bringer_doom_lose_04",
				"doom_bringer_doom_ability_fail_02",
				"doom_bringer_doom_respawn_08",
				},
				{
				"dragon_knight_drag_laugh_07",
				"dragon_knight_drag_level_05",
				"dragon_knight_drag_purch_01",
				"dragon_knight_drag_kill_11",
				"dragon_knight_drag_lasthit_09",
				"dragon_knight_drag_kill_01",
				"dragon_knight_drag_move_05",
				"dragon_knight_drag_ability_eldrag_06",
				},
				{
				"drowranger_dro_laugh_04",
				"drowranger_dro_win_04",
				"drowranger_dro_deny_02",
				"drowranger_drow_kill_13",
				"drowranger_drow_rival_13",
				"drowranger_dro_kill_05",
				"drowranger_dro_win_03",
				"drowranger_drow_kill_17",
				},
				{
				"earth_spirit_earthspi_laugh_06",
				"earth_spirit_earthspi_thanks_04",
				"earth_spirit_earthspi_deny_05",
				"earth_spirit_earthspi_rollingboulder_20",
				"earth_spirit_earthspi_invis_03",
				"earth_spirit_earthspi_lasthit_10",
				"earth_spirit_earthspi_failure_06",
				"earth_spirit_earthspi_illus_02",
				},
				{
				"earthshaker_erth_laugh_03",
				"earthshaker_erth_move_06",
				"earthshaker_erth_death_09",
				"earthshaker_erth_kill_08",
				"earthshaker_erth_respawn_06",
				"earthshaker_erth_ability_echo_06",
				"earthshaker_erth_rival_20",
				"earthshaker_erth_rare_05",
				},
				{
				"elder_titan_elder_laugh_05",
				"elder_titan_elder_purch_03",
				"elder_titan_elder_deny_06",
				"elder_titan_elder_lose_05",
				"elder_titan_elder_failure_01",
				"elder_titan_elder_move_11",
				"elder_titan_elder_failure_02",
				"elder_titan_elder_kill_04",
				},
				{
				"ember_spirit_embr_laugh_12",
				"ember_spirit_embr_levelup_01",
				"ember_spirit_embr_itemrare_01",
				"ember_spirit_embr_attack_06",
				"ember_spirit_embr_kill_12",
				"ember_spirit_embr_move_02",
				"ember_spirit_embr_rival_03",
				"ember_spirit_embr_failure_02",
				},
				{
				"enchantress_ench_laugh_05",
				"enchantress_ench_win_03",
				"enchantress_ench_deny_13",
				"enchantress_ench_death_08",
				"enchantress_ench_deny_14",
				"enchantress_ench_kill_08",
				"enchantress_ench_deny_15",
				"enchantress_ench_rare_01",
				},
				{
				"enigma_enig_laugh_03",
				"enigma_enig_respawn_05",
				"enigma_enig_purch_01",
				"enigma_enig_ability_black_03",
				"enigma_enig_lasthit_01",
				"enigma_enig_rival_20",
				"enigma_enig_drop_medium_01",
				"enigma_enig_ability_black_01",
				},
				{
				"faceless_void_face_laugh_07",
				"faceless_void_face_win_03",
				"faceless_void_face_lose_03",
				"faceless_void_face_kill_01",
				"faceless_void_face_kill_11",
				"faceless_void_face_ability_chronos_failure_08",
				"faceless_void_face_rare_03",
				"faceless_void_face_ability_chronos_failure_07",
				},
				{
				"grimstroke_grimstroke_laugh_11",
				"grimstroke_grimstroke_wheel_thanks_01",
				"grimstroke_grimstroke_kill_11",
				"grimstroke_grimstroke_wheel_deny_03",
				"grimstroke_grimstroke_spawn_14",
				"grimstroke_grimstroke_kill_10",
				"grimstroke_grimstroke_wheel_deny_01",
				"grimstroke_grimstroke_taunt_01",
				},
				{
				"gyrocopter_gyro_laugh_11",
				"gyrocopter_gyro_flak_cannon_09",
				"gyrocopter_gyro_failure_03",
				"gyrocopter_gyro_homing_missile_destroyed_02",
				"gyrocopter_gyro_respawn_12",
				"gyrocopter_gyro_deny_05",
				"gyrocopter_gyro_kill_15",
				"gyrocopter_gyro_kill_02",
				},
				{
				"hoodwink_hoodwink_wheel_laugh_04",
				"hoodwink_hoodwink_wheel_thanks_02_02",
				"hoodwink_hoodwink_wheel_deny_01",
				"hoodwink_hoodwink_net_hit_12",
				"hoodwink_hoodwink_kill_23",
				"hoodwink_hoodwink_levelup_26",
				"hoodwink_hoodwink_attack_25",
				"hoodwink_hoodwink_lasthit_03",
				},
				{
				"huskar_husk_laugh_09",
				"huskar_husk_purch_01",
				"huskar_husk_ability_lifebrk_01",
				"huskar_husk_kill_06",
				"huskar_husk_ability_brskrblood_03",
				"huskar_husk_ability_lifebrk_05",
				"huskar_husk_lasthit_07",
				"huskar_husk_kill_04",
				},
				{
				"invoker_invo_laugh_06",
				"invoker_invo_purch_01",
				"invoker_invo_ability_invoke_01",
				"invoker_invo_kill_01",
				"invoker_invo_attack_05",
				"invoker_invo_failure_06",
				"invoker_invo_lasthit_06",
				"invoker_invo_rare_04",
				},
				{
				"wisp_laugh",
				"wisp_thanks",
				"wisp_deny",
				"wisp_ally",
				"wisp_win",
				"wisp_lose",
				"wisp_no_mana_not_yet01",
				"wisp_battlebegins",
				},
				{
				"jakiro_jak_deny_13",
				"jakiro_jak_bottle_01",
				"jakiro_jak_rare_03",
				"jakiro_jak_deny_12",
				"jakiro_jak_level_05",
				"jakiro_jak_bottle_03",
				"jakiro_jak_ability_failure_07",
				"jakiro_jak_brother_02",
				},
				{
				"juggernaut_jug_laugh_05",
				"juggernaut_jugg_set_complete_06",
				"juggernaut_jugg_set_complete_04",
				"juggernaut_jugg_taunt_06",
				"juggernaut_jugg_set_complete_03",
				"juggernaut_jug_ability_stunteleport_03",
				"juggernaut_jug_kill_09",
				"juggernaut_jugg_set_complete_05",
				},
				{
				"keeper_of_the_light_keep_laugh_06",
				"keeper_of_the_light_keep_thanks_04",
				"keeper_of_the_light_keep_nomana_06",
				"keeper_of_the_light_keep_kill_18",
				"keeper_of_the_light_keep_deny_12",
				"keeper_of_the_light_keep_deny_16",
				"keeper_of_the_light_keep_kill_09",
				"keeper_of_the_light_keep_cast_02",
				},
				{
				"kunkka_kunk_laugh_06",
				"kunkka_kunk_thanks_03",
				"kunkka_kunk_kill_04",
				"kunkka_kunk_attack_08",
				"kunkka_kunk_kill_10",
				"kunkka_kunk_ability_tidebrng_02",
				"kunkka_kunk_ally_06",
				"kunkka_kunk_kill_13",
				},
				{
				"legion_commander_legcom_laugh_05",
				"legion_commander_legcom_itemcommon_02",
				"legion_commander_legcom_deny_07",
				"legion_commander_legcom_move_15",
				"legion_commander_legcom_ally_11",
				"legion_commander_legcom_duel_08",
				"legion_commander_legcom_duelfailure_06",
				"legion_commander_legcom_kill_14",
				},
				{
				"leshrac_lesh_deny_14",
				"leshrac_lesh_bottle_01",
				"leshrac_lesh_kill_13",
				"leshrac_lesh_lasthit_08",
				"leshrac_lesh_deny_13",
				"leshrac_lesh_purch_01",
				"leshrac_lesh_cast_01",
				"leshrac_lesh_kill_11",
				},
				{
				"lich_lich_level_09",
				"lich_lich_ability_armor_01",
				"lich_lich_kill_05",
				"lich_lich_immort_02",
				"lich_lich_attack_03",
				"lich_lich_ability_nova_01",
				"lich_lich_kill_09",
				"lich_lich_ability_icefrog_01",
				},
				{
				"life_stealer_lifest_laugh_07",
				"life_stealer_lifest_levelup_11",
				"life_stealer_lifest_ability_infest_burst_08",
				"life_stealer_lifest_ability_infest_burst_05",
				"life_stealer_lifest_ability_rage_06",
				"life_stealer_lifest_attack_02",
				"life_stealer_lifest_kill_13",
				"life_stealer_lifest_ability_infest_burst_06",
				},
				{
				"lina_lina_laugh_09",
				"lina_lina_kill_01",
				"lina_lina_kill_05",
				"lina_lina_kill_02",
				"lina_lina_spawn_08",
				"lina_lina_kill_03",
				"lina_lina_drop_common_01",
				"lina_lina_purch_02",
				},
				{
				"lion_lion_laugh_01",
				"lion_lion_move_12",
				"lion_lion_deny_06",
				"lion_lion_kill_05",
				"lion_lion_cast_03",
				"lion_lion_kill_02",
				"lion_lion_kill_04",
				"lion_lion_respawn_01",
				},
				{
				"lone_druid_lone_druid_laugh_05",
				"lone_druid_lone_druid_level_03",
				"lone_druid_lone_druid_ability_trueform_09",
				"lone_druid_lone_druid_ability_rabid_04",
				"lone_druid_lone_druid_ability_failure_02",
				"lone_druid_lone_druid_purch_02",
				"lone_druid_lone_druid_death_03",
				"lone_druid_lone_druid_bearform_ability_trueform_04",
				},
				{
				"luna_luna_laugh_09",
				"luna_luna_levelup_03",
				"luna_luna_drop_common",
				"luna_luna_kill_06",
				"luna_luna_ability_failure_03",
				"luna_luna_drop_medium",
				"luna_luna_shiwiz_02",
				"luna_luna_ability_eclipse_08",
				},
				{
				"lycan_lycan_laugh_14",
				"lycan_lycan_kill_04",
				"lycan_lycan_immort_02",
				"lycan_lycan_kill_01",
				"lycan_lycan_level_05",
				"lycan_lycan_attack_02",
				"lycan_lycan_attack_05",
				"lycan_lycan_cast_02",
				},
				{
				"magnataur_magn_laugh_06",
				"magnataur_magn_purch_04",
				"magnataur_magn_failure_08",
				"magnataur_magn_kill_01",
				"magnataur_magn_failure_10",
				"magnataur_magn_lasthit_02",
				"magnataur_magn_failure_03",
				"magnataur_magn_rare_05",
				},
				{
				"mars_mars_laugh_08",
				"mars_mars_thanks_03",
				"mars_mars_lose_05",
				"mars_mars_kill_09",
				"mars_mars_kill_10",
				"mars_mars_ability4_09",
				"mars_mars_song_02",
				"mars_mars_wheel_all_11",
				},
				{
				"medusa_medus_laugh_05",
				"medusa_medus_items_15",
				"medusa_medus_deny_01",
				"medusa_medus_kill_09",
				"medusa_medus_failure_01",
				"medusa_medus_deny_12",
				"medusa_medus_begin_03",
				"medusa_medus_illus_02",
				},
				{
				"meepo_meepo_deny_16",
				"meepo_meepo_drop_medium",
				"meepo_meepo_earthbind_05",
				"meepo_meepo_failure_03",
				"meepo_meepo_purch_05",
				"meepo_meepo_lose_05",
				"meepo_meepo_respawn_08",
				"meepo_meepo_lose_04",
				},
				{
				"mirana_mir_laugh_03",
				"mirana_mir_drop_common_01",
				"mirana_mir_illus_03",
				"mirana_mir_kill_09",
				"mirana_mir_kill_02",
				"mirana_mir_attack_08",
				"mirana_mir_rare_04",
				"mirana_mir_kill_04",
				},
				{
				"monkey_king_monkey_laugh_17",
				"monkey_king_monkey_drop_common_01",
				"monkey_king_monkey_regen_02",
				"monkey_king_monkey_win_02",
				"monkey_king_monkey_death_01",
				"monkey_king_monkey_drop_medium_01",
				"monkey_king_monkey_deny_brood_01",
				"monkey_king_monkey_ability5_07",
				},
				{
				"morphling_mrph_laugh_08",
				"morphling_mrph_ability_repfriend_02",
				"morphling_mrph_cast_01",
				"morphling_mrph_attack_09",
				"morphling_mrph_regen_02",
				"morphling_mrph_respawn_02",
				"morphling_mrph_kill_09",
				"morphling_mrph_kill_06",
				},
				{
				"naga_siren_naga_laugh_04",
				"naga_siren_naga_kill_02",
				"naga_siren_naga_kill_12",
				"naga_siren_naga_cast_01",
				"naga_siren_naga_rival_21",
				"naga_siren_naga_deny_08",
				"naga_siren_naga_rival_14",
				"naga_siren_naga_death_07",
				},
				{
				"furion_furi_laugh_01",
				"furion_furi_equipping_04",
				"furion_furi_equipping_05",
				"furion_furi_kill_01",
				"furion_furi_kill_03",
				"furion_furi_equipping_02",
				"furion_furi_deny_07",
				"furion_furi_kill_11",
				},
				{
				"necrolyte_necr_laugh_07",
				"necrolyte_necr_breath_02",
				"necrolyte_necr_purch_04",
				"necrolyte_necr_kill_03",
				"necrolyte_necr_rare_05",
				"necrolyte_necr_lose_03",
				"necrolyte_necr_respawn_12",
				"necrolyte_necr_rare_04",
				},
				{
				"night_stalker_nstalk_laugh_06",
				"night_stalker_nstalk_purch_03",
				"night_stalker_nstalk_respawn_05",
				"night_stalker_nstalk_purch_01",
				"night_stalker_nstalk_cast_01",
				"night_stalker_nstalk_attack_11",
				"night_stalker_nstalk_battlebegins_01",
				"night_stalker_nstalk_spawn_03",
				},
				{
				"nyx_assassin_nyx_laugh_07",
				"nyx_assassin_nyx_items_11",
				"nyx_assassin_nyx_death_03",
				"nyx_assassin_nyx_burn_05",
				"nyx_assassin_nyx_chitter_02",
				"nyx_assassin_nyx_waiting_01",
				"nyx_assassin_nyx_rival_25",
				"nyx_assassin_nyx_levelup_10",
				},
				{
				"ogre_magi_ogmag_laugh_14",
				"ogre_magi_ogmag_rival_04",
				"ogre_magi_ogmag_illus_02",
				"ogre_magi_ogmag_ability_multi_05",
				"ogre_magi_ogmag_kill_11",
				"ogre_magi_ogmag_rival_05",
				"ogre_magi_ogmag_rival_03",
				"ogre_magi_ogmag_kill_03",
				},
				{
				"omniknight_omni_laugh_10",
				"omniknight_omni_death_13",
				"omniknight_omni_level_09",
				"omniknight_omni_kill_09",
				"omniknight_omni_ability_degaura_04",
				"omniknight_omni_kill_02",
				"omniknight_omni_kill_12",
				"omniknight_omni_ability_degaura_05",
				},
				{
				"oracle_orac_laugh_13",
				"oracle_orac_kill_09",
				"oracle_orac_death_11",
				"oracle_orac_lasthit_04",
				"oracle_orac_itemare_02",
				"oracle_orac_respawn_06",
				"oracle_orac_kill_22",
				"oracle_orac_randomprophecies_02",
				},
				{
				"outworld_destroyer_odest_laugh_04",
				"outworld_destroyer_odest_begin_02",
				"outworld_destroyer_odest_win_04",
				"outworld_destroyer_odest_attack_11",
				"outworld_destroyer_odest_death_10",
				"outworld_destroyer_odest_rival_13",
				"outworld_destroyer_odest_death_12",
				"outworld_destroyer_odest_lasthit_03",
				},
				{
				"pangolin_pangolin_laugh_14",
				"pangolin_pangolin_kill_08",
				"pangolin_pangolin_levelup_11",
				"pangolin_pangolin_kill_06",
				"pangolin_pangolin_ability3_04",
				"pangolin_pangolin_ability4_08",
				"pangolin_pangolin_doubledam_03",
				"pangolin_pangolin_ally_09",
				},
				{
				"phantom_assassin_phass_laugh_07",
				"phantom_assassin_phass_happy_09",
				"phantom_assassin_phass_kill_02",
				"phantom_assassin_phass_kill_10",
				"phantom_assassin_phass_kill_01",
				"phantom_assassin_phass_ability_blur_02",
				"phantom_assassin_phass_deny_14",
				"phantom_assassin_phass_level_06",
				},
				{
				"phantom_lancer_plance_laugh_03",
				"phantom_lancer_plance_drop_rare",
				"phantom_lancer_plance_lasthit_06",
				"phantom_lancer_plance_cast_02",
				"phantom_lancer_plance_illus_02",
				"phantom_lancer_plance_respawn_05",
				"phantom_lancer_plance_win_02",
				"phantom_lancer_plance_kill_10",
				},
				{
				"phoenix_phoenix_bird_laugh",
				"phoenix_phoenix_bird_emote_good",
				"phoenix_phoenix_bird_denied",
				"phoenix_phoenix_bird_victory",
				"phoenix_phoenix_bird_death_defeat",
				"phoenix_phoenix_bird_inthebag",
				"phoenix_phoenix_bird_emote_bad",
				"phoenix_phoenix_bird_level_up",
				},
				{
				"puck_puck_laugh_01",
				"puck_puck_spawn_04",
				"puck_puck_kill_09",
				"puck_puck_ability_orb_03",
				"puck_puck_spawn_05",
				"puck_puck_lose_04",
				"puck_puck_ability_dreamcoil_05",
				"puck_puck_win_04",
				},
				{
				"pudge_pud_laugh_05",
				"pudge_pud_thanks_02",
				"pudge_pud_ability_rot_07",
				"pudge_pud_attack_08",
				"pudge_pud_rare_05",
				"pudge_pud_acknow_05",
				"pudge_pud_lasthit_07",
				"pudge_pud_kill_07",
				},
				{
				"pugna_pugna_laugh_01",
				"pugna_pugna_level_06",
				"pugna_pugna_cast_05",
				"pugna_pugna_ability_nblast_05",
				"pugna_pugna_respawn_03",
				"pugna_pugna_battlebegins_01",
				"pugna_pugna_ability_nward_07",
				"pugna_pugna_ability_life_08",
				},
				{
				"queenofpain_pain_laugh_04",
				"queenofpain_pain_spawn_02",
				"queenofpain_pain_kill_08",
				"queenofpain_pain_kill_12",
				"queenofpain_pain_attack_04",
				"queenofpain_pain_cast_01",
				"queenofpain_pain_taunt_01",
				"queenofpain_pain_respawn_04",
				},
				{
				"razor_raz_laugh_05",
				"razor_raz_ability_static_05",
				"razor_raz_cast_01",
				"razor_raz_kill_03",
				"razor_raz_kill_10",
				"razor_raz_lasthit_02",
				"razor_raz_kill_05",
				"razor_raz_kill_09",
				},
				{
				"riki_riki_laugh_03",
				"riki_riki_kill_01",
				"riki_riki_kill_03",
				"riki_riki_cast_01",
				"riki_riki_ability_blink_05",
				"riki_riki_ability_invis_03",
				"riki_riki_respawn_07",
				"riki_riki_kill_14",
				},
				{
				"rubick_rubick_laugh_06",
				"rubick_rubick_move_12",
				"rubick_rubick_lasthit_06",
				"rubick_rubick_levelup_04",
				"rubick_rubick_rival_07",
				"rubick_rubick_itemcommon_02",
				"rubick_rubick_failure_02",
				"rubick_rubick_itemrare_01",
				},
				{
				"sandking_skg_laugh_07",
				"sandking_sand_thanks_03",
				"sandking_skg_ability_caustic_04",
				"sandking_skg_kill_04",
				"sandking_skg_win_04",
				"sandking_skg_ability_epicenter_01",
				"sandking_skg_kill_09",
				"sandking_skg_kill_03",
				},
				{
				"shadow_demon_shadow_demon_laugh_03",
				"shadow_demon_shadow_demon_doubdam_02",
				"shadow_demon_shadow_demon_kill_10",
				"shadow_demon_shadow_demon_attack_13",
				"shadow_demon_shadow_demon_attack_03",
				"shadow_demon_shadow_demon_ability_soul_catcher_01",
				"shadow_demon_shadow_demon_lasthit_07",
				"shadow_demon_shadow_demon_kill_14",
				},
				{
				"nevermore_nev_laugh_02",
				"nevermore_nev_thanks_02",
				"nevermore_nev_deny_03",
				"nevermore_nev_kill_11",
				"nevermore_nev_ability_presence_02",
				"nevermore_nev_lasthit_02",
				"nevermore_nev_attack_07",
				"nevermore_nev_attack_11",
				},
				{
				"shadowshaman_shad_blink_02",
				"shadowshaman_shad_level_03",
				"shadowshaman_shad_ability_voodoo_06",
				"shadowshaman_shad_kill_03",
				"shadowshaman_shad_ability_entrap_03",
				"shadowshaman_shad_refresh_02",
				"shadowshaman_shad_ability_voodoo_08",
				"shadowshaman_shad_attack_07",
				},
				{
				"silencer_silen_laugh_13",
				"silencer_silen_level_06",
				"silencer_silen_deny_11",
				"silencer_silen_ability_silence_05",
				"silencer_silen_ability_failure_04",
				"silencer_silen_ability_curse_02",
				"silencer_silen_death_10",
				"silencer_silen_respawn_02",
				},
				{
				"skywrath_mage_drag_laugh_01",
				"skywrath_mage_drag_lasthit_07",
				"skywrath_mage_drag_deny_04",
				"skywrath_mage_drag_failure_01",
				"skywrath_mage_drag_fastres_01",
				"skywrath_mage_drag_thanks_02",
				"skywrath_mage_drag_inthebag_01",
				"skywrath_mage_drag_cast_02",
				},
				{
				"slardar_slar_laugh_05",
				"slardar_slar_kill_07",
				"slardar_slar_kill_01",
				"slardar_slar_longdistance_02",
				"slardar_slar_cast_02",
				"slardar_slar_deny_05",
				"slardar_slar_kill_03",
				"slardar_slar_win_05",
				},
				{
				"slark_slark_laugh_01",
				"slark_slark_illus_02",
				"slark_slark_cast_03",
				"slark_slark_rival_03",
				"slark_slark_failure_05",
				"slark_slark_kill_08",
				"slark_slark_drop_rare_01",
				"slark_slark_happy_07",
				},
				{
				"snapfire_snapfire_laugh_02_02",
				"snapfire_snapfire_wheel_thanks_02",
				"snapfire_snapfire_spawn_25",
				"snapfire_snapfire_wheel_all_03",
				"snapfire_snapfire_wheel_all_07",
				"snapfire_snapfire_whawiz_01",
				"snapfire_snapfire_rival_67",
				"snapfire_snapfire_spawn_24",
				},
				{
				"sniper_snip_laugh_08",
				"sniper_snip_level_06",
				"sniper_snip_ability_fail_04",
				"sniper_snip_tf2_04",
				"sniper_snip_ability_shrapnel_06",
				"sniper_snip_rare_04",
				"sniper_snip_kill_05",
				"sniper_snip_ability_shrapnel_03",
				},
				{
				"spectre_spec_laugh_13",
				"spectre_spec_ability_haunt_01",
				"spectre_spec_deny_01",
				"spectre_spec_death_07",
				"spectre_spec_lasthit_01",
				"spectre_spec_doubdam_02",
				"spectre_spec_kill_02",
				"spectre_spec_kill_01",
				},
				{
				"spirit_breaker_spir_laugh_06",
				"spirit_breaker_spir_level_07",
				"spirit_breaker_spir_ability_bash_03",
				"spirit_breaker_spir_purch_03",
				"spirit_breaker_spir_cast_01",
				"spirit_breaker_spir_lose_05",
				"spirit_breaker_spir_lasthit_07",
				"spirit_breaker_spir_ability_failure_02",
				},
				{
				"stormspirit_ss_laugh_06",
				"stormspirit_ss_win_03",
				"stormspirit_ss_kill_02",
				"stormspirit_ss_attack_06",
				"stormspirit_ss_ability_lightning_06",
				"stormspirit_ss_kill_03",
				"stormspirit_ss_ability_static_02",
				"stormspirit_ss_lasthit_04",
				},
				{
				"sven_sven_laugh_11",
				"sven_sven_thanks_01",
				"sven_sven_ability_teleport_01",
				"sven_sven_kill_02",
				"sven_sven_kill_05",
				"sven_sven_rare_07",
				"sven_sven_win_04",
				"sven_sven_respawn_02",
				},
				{
				"techies_tech_kill_23",
				"techies_tech_settrap_08",
				"techies_tech_failure_06",
				"techies_tech_suicidesquad_09",
				"techies_tech_detonatekill_02",
				"techies_tech_trapgoesoff_10",
				"techies_tech_ally_03",
				"techies_tech_kill_07",
				},
				{
				"templar_assassin_temp_laugh_02",
				"templar_assassin_temp_lasthit_06",
				"templar_assassin_temp_kill_10",
				"templar_assassin_temp_kill_12",
				"templar_assassin_temp_psionictrap_04",
				"templar_assassin_temp_levelup_01",
				"templar_assassin_temp_psionictrap_06",
				"templar_assassin_temp_refraction_04",
				},
				{
				"terrorblade_terr_laugh_07",
				"terrorblade_terr_conjureimage_03",
				"terrorblade_terr_purch_02",
				"terrorblade_terr_sunder_03",
				"terrorblade_terr_reflection_06",
				"terrorblade_terr_failure_05",
				"terrorblade_terr_kill_14",
				"terrorblade_terr_doubdam_04",
				},
				{
				"tidehunter_tide_laugh_05",
				"tidehunter_tide_battlebegins_02",
				"tidehunter_tide_ability_ravage_02",
				"tidehunter_tide_kill_12",
				"tidehunter_tide_level_18",
				"tidehunter_tide_bottle_01",
				"tidehunter_tide_rival_25",
				"tidehunter_tide_rare_01",
				},
				{
				"shredder_timb_laugh_04",
				"shredder_timb_thanks_03",
				"shredder_timb_kill_10",
				"shredder_timb_happy_05",
				"shredder_timb_drop_rare_02",
				"shredder_timb_whirlingdeath_05",
				"shredder_timb_rival_08",
				"shredder_timb_haste_02",
				},
				{
				"tinker_tink_laugh_10",
				"tinker_tink_thanks_03",
				"tinker_tink_levelup_06",
				"tinker_tink_ability_laser_03",
				"tinker_tink_respawn_01",
				"tinker_tink_kill_03",
				"tinker_tink_respawn_03",
				"tinker_tink_ability_laser_01",
				},
				{
				"tiny_tiny_laugh_05",
				"tiny_tiny_spawn_03",
				"tiny_tiny_ability_toss_11",
				"tiny_tiny_attack_03",
				"tiny_tiny_kill_09",
				"tiny_tiny_ability_toss_07",
				"tiny_tiny_attack_06",
				"tiny_tiny_level_02",
				},
				{
				"treant_treant_laugh_07",
				"treant_treant_freakout",
				"treant_treant_failure_03",
				"treant_treant_attack_07",
				"treant_treant_ability_naturesguise_06",
				"treant_treant_cast_02",
				"treant_treant_kill_05",
				"treant_treant_failure_01",
				},
				{
				"troll_warlord_troll_laugh_05",
				"troll_warlord_troll_battletrance_05",
				"troll_warlord_troll_deny_09",
				"troll_warlord_troll_kill_03",
				"troll_warlord_troll_ally_08",
				"troll_warlord_troll_ally_11",
				"troll_warlord_troll_death_05",
				"troll_warlord_troll_unknown_09",
				},
				{
				"tusk_tusk_laugh_06",
				"tusk_tusk_kill_26",
				"tusk_tusk_snowball_17",
				"tusk_tusk_rival_19",
				"tusk_tusk_snowball_24",
				"tusk_tusk_move_26",
				"tusk_tusk_kill_22",
				"tusk_tusk_snowball_23",
				},
				{
				"abyssal_underlord_abys_laugh_02",
				"abyssal_underlord_abys_thanks_03",
				"abyssal_underlord_abys_failure_01",
				"abyssal_underlord_abys_move_02",
				"abyssal_underlord_abys_kill_13",
				"abyssal_underlord_abys_rival_01",
				"abyssal_underlord_abys_move_12",
				"abyssal_underlord_abys_darkrift_03",
				},
				{
				"undying_undying_levelup_10",
				"undying_undying_thanks_04",
				"undying_undying_kill_09",
				"undying_undying_respawn_03",
				"undying_undying_gummy_vit_01",
				"undying_undying_respawn_05",
				"undying_undying_deny_14",
				"undying_undying_failure_02",
				},
				{
				"ursa_ursa_laugh_20",
				"ursa_ursa_respawn_12",
				"ursa_ursa_kill_10",
				"ursa_ursa_failure_02",
				"ursa_ursa_spawn_05",
				"ursa_ursa_kill_07",
				"ursa_ursa_levelup_07",
				"ursa_ursa_lasthit_08",
				},
				{
				"vengefulspirit_vng_deny_11",
				"vengefulspirit_vng_kill_01",
				"vengefulspirit_vng_respawn_06",
				"vengefulspirit_vng_regen_02",
				"vengefulspirit_vng_rare_09",
				"vengefulspirit_vng_deny_03",
				"vengefulspirit_vng_rare_10",
				"vengefulspirit_vng_rare_05",
				},
				{
				"venomancer_venm_laugh_02",
				"venomancer_venm_ability_ward_02",
				"venomancer_venm_purch_01",
				"venomancer_venm_kill_03",
				"venomancer_venm_ability_fail_07",
				"venomancer_venm_cast_02",
				"venomancer_venm_rosh_04",
				"venomancer_venm_attack_11",
				},
				{
				"viper_vipe_laugh_06",
				"viper_vipe_respawn_07",
				"viper_vipe_deny_06",
				"viper_vipe_kill_03",
				"viper_vipe_move_14",
				"viper_vipe_lasthit_05",
				"viper_vipe_ability_viprstrik_02",
				"viper_vipe_rare_03",
				},
				{
				"visage_visa_laugh_14",
				"visage_visa_happy_07",
				"visage_visa_rival_09",
				"visage_visa_kill_13",
				"visage_visa_failure_01",
				"visage_visa_rival_02",
				"visage_visa_spawn_05",
				"visage_visa_happy_03",
				},
				{
				"void_spirit_voidspir_laugh_05",
				"void_spirit_voidspir_thanks_04",
				"void_spirit_voidspir_spawn_14",
				"void_spirit_voidspir_rival_114",
				"void_spirit_voidspir_rival_113",
				"void_spirit_voidspir_rival_72",
				"void_spirit_voidspir_rival_71",
				"void_spirit_voidspir_wheel_all_10_02",
				},
				{
				"warlock_warl_laugh_06",
				"warlock_warl_ability_reign_07",
				"warlock_warl_defusal_04",
				"warlock_warl_kill_05",
				"warlock_warl_incant_18",
				"warlock_warl_kill_07",
				"warlock_warl_lasthit_02",
				"warlock_warl_doubdemon_06",
				},
				{
				"weaver_weav_laugh_04",
				"weaver_weav_win_03",
				"weaver_weav_ability_timelap_05",
				"weaver_weav_kill_07",
				"weaver_weav_fastres_01",
				"weaver_weav_respawn_02",
				"weaver_weav_kill_03",
				"weaver_weav_lasthit_07",
			},
			{
				"windrunner_wind_laugh_08",
				"windrunner_wind_lasthit_04",
				"windrunner_wind_deny_06",
				"windrunner_wind_kill_11",
				"windrunner_wind_ability_shackleshot_01",
				"windrunner_wind_kill_06",
				"windrunner_wind_lose_06",
				"windrunner_wind_attack_04",
			},
			{
				"winter_wyvern_winwyv_laugh_03",
				"winter_wyvern_winwyv_thanks_01",
				"winter_wyvern_winwyv_deny_08",
				"winter_wyvern_winwyv_death_09",
				"winter_wyvern_winwyv_lasthit_07",
				"winter_wyvern_winwyv_kill_03",
				"winter_wyvern_winwyv_winterscurse_11",
				"winter_wyvern_winwyv_levelup_08",
			},
			{
				"witchdoctor_wdoc_laugh_02",
				"witchdoctor_wdoc_level_08",
				"witchdoctor_wdoc_killspecial_01",
				"witchdoctor_wdoc_killspecial_03",
				"witchdoctor_wdoc_move_06",
				"witchdoctor_wdoc_ability_cask_03",
				"witchdoctor_wdoc_kill_11",
				"witchdoctor_wdoc_laugh_03",
			},
			{
				"skeleton_king_wraith_laugh_04",
				"skeleton_king_wraith_ally_01",
				"skeleton_king_wraith_move_08",
				"skeleton_king_wraith_attack_03",
				"skeleton_king_wraith_purch_03",
				"skeleton_king_wraith_rare_06",
				"skeleton_king_wraith_items_02",
				"skeleton_king_wraith_win_03",
			},
			{
				"zuus_zuus_laugh_01",
				"zuus_zuus_level_03",
				"zuus_zuus_win_05",
				"zuus_zuus_cast_02",
				"zuus_zuus_kill_05",
				"zuus_zuus_death_07",
				"zuus_zuus_ability_thunder_01",
				"zuus_zuus_rival_13",
			}
		}
		if vousedcol[keys.PlayerID] == nil then vousedcol[keys.PlayerID] = 0 end
		if votimer[keys.PlayerID] ~= nil then
			if GameRules:GetGameTime() - votimer[keys.PlayerID] > 5 + vousedcol[keys.PlayerID] and (phraseDoesntHasCooldown == nil or phraseDoesntHasCooldown == true) then
				local chat = LoadKeyValues("scripts/hero_chat_wheel_english.txt")
				--EmitAnnouncerSound(heroesvo[selectedid][selectedid2])
				ChatSound(heroesvo[selectedid][selectedid2], keys.PlayerID)
				--GameRules:SendCustomMessage("<font color='#70EA72'>".."test".."</font>",-1,0)
				Say(PlayerResource:GetPlayer(keys.PlayerID), chat["dota_chatwheel_message_"..selectedstr], false)
				votimer[keys.PlayerID] = GameRules:GetGameTime()
				vousedcol[keys.PlayerID] = vousedcol[keys.PlayerID] + 1
			else
				local remaining_cd = " ("..string.format("%.1f", 5 + vousedcol[keys.PlayerID] - (GameRules:GetGameTime() - votimer[keys.PlayerID])).."s)"
				CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(keys.PlayerID), "display_custom_error", { message = "#wheel_cooldown"..remaining_cd })
			end
		else
			local chat = LoadKeyValues("scripts/hero_chat_wheel_english.txt")
			--EmitAnnouncerSound(heroesvo[selectedid][selectedid2])
			ChatSound(heroesvo[selectedid][selectedid2], keys.PlayerID)
			Say(PlayerResource:GetPlayer(keys.PlayerID), chat["dota_chatwheel_message_"..selectedstr], false)
			votimer[keys.PlayerID] = GameRules:GetGameTime()
			vousedcol[keys.PlayerID] = vousedcol[keys.PlayerID] + 1
		end
	end
end

function ChatSound(phrase, playerId)
	local all_heroes = HeroList:GetAllHeroes()
	for _, hero in pairs(all_heroes) do
		if hero:IsRealHero() and hero:IsControllableByAnyPlayer() and hero:GetPlayerID() and (not _G.tPlayersMuted[hero:GetPlayerID()] or not _G.tPlayersMuted[hero:GetPlayerID()][playerId]) then
			EmitAnnouncerSoundForPlayer(phrase, hero:GetPlayerID())
		end
	end
end

RegisterCustomEventListener("SelectVO", SelectVO)

RegisterCustomEventListener("set_mute_player", function(data)
	local fromId = data.PlayerID
	local toId = data.toPlayerId
	local disable = data.disable
	_G.tPlayersMuted[fromId] = _G.tPlayersMuted[fromId] or {}
	if disable == 0 then
		_G.tPlayersMuted[fromId][toId] = nil
	else
		_G.tPlayersMuted[fromId][toId] = disable
	end
end)

RegisterCustomEventListener("patreon_update_chat_wheel_favorites", function(data)
	local playerId = data.PlayerID
	if not playerId then return end

	if WebApi.playerSettings and WebApi.playerSettings[data.PlayerID] then
		local favourites = data.favourites
		if not favourites then return end

		WebApi.playerSettings[data.PlayerID].chatWheelFavourites = favourites
		WebApi:ScheduleUpdateSettings(data.PlayerID)
	end
end)
