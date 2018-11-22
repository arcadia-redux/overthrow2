--[[
Overthrow Game Mode
]]

_G.nCOUNTDOWNTIMER = 901
_G.DISABLE_PAUSES = true
TRUSTED_HOSTS = {
	["76561198036748162"] = true,
	["76561198003571172"] = true,
	["76561198065780626"] = true, --https://www.twitch.tv/canko/
}

_G.DISCONNECT_TIMES = {}

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
require( "events" )
require( "items" )
require( "utility_functions" )
require("patreons")
require("smart_random")
require("statcollection/init")

LinkLuaModifier("modifier_core_pumpkin_regeneration", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_core_spawn_movespeed", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_core_courier", LUA_MODIFIER_MOTION_NONE)

---------------------------------------------------------------------------
-- Precache
---------------------------------------------------------------------------
function Precache( context )
	--Cache the gold bags
		PrecacheItemByNameSync( "item_bag_of_gold", context )
		PrecacheResource( "particle", "particles/items2_fx/veil_of_discord.vpcf", context )

		PrecacheItemByNameSync( "item_treasure_chest", context )
		PrecacheModel( "item_treasure_chest", context )

	--Cache the creature models
		PrecacheUnitByNameSync( "npc_dota_creature_basic_zombie", context )
        PrecacheModel( "npc_dota_creature_basic_zombie", context )

        PrecacheUnitByNameSync( "npc_dota_creature_berserk_zombie", context )
        PrecacheModel( "npc_dota_creature_berserk_zombie", context )

        PrecacheUnitByNameSync( "npc_dota_treasure_courier", context )
        PrecacheModel( "npc_dota_treasure_courier", context )

	--Cache new particles
       	PrecacheResource( "particle", "particles/econ/events/nexon_hero_compendium_2014/teleport_end_nexon_hero_cp_2014.vpcf", context )
       	PrecacheResource( "particle", "particles/leader/leader_overhead.vpcf", context )
       	PrecacheResource( "particle", "particles/last_hit/last_hit.vpcf", context )
       	PrecacheResource( "particle", "particles/units/heroes/hero_zuus/zeus_taunt_coin.vpcf", context )
       	PrecacheResource( "particle", "particles/addons_gameplay/player_deferred_light.vpcf", context )
       	PrecacheResource( "particle", "particles/items_fx/black_king_bar_avatar.vpcf", context )
       	PrecacheResource( "particle", "particles/treasure_courier_death.vpcf", context )
       	PrecacheResource( "particle", "particles/econ/wards/f2p/f2p_ward/f2p_ward_true_sight_ambient.vpcf", context )
       	PrecacheResource( "particle", "particles/econ/items/lone_druid/lone_druid_cauldron/lone_druid_bear_entangle_dust_cauldron.vpcf", context )
       	PrecacheResource( "particle", "particles/newplayer_fx/npx_landslide_debris.vpcf", context )
       	PrecacheResource( "particle", "particles/custom/items/hand_of_midas_cast.vpcf", context )
       	PrecacheResource( "particle", "particles/custom/items/hand_of_midas_coin.vpcf", context )
       	PrecacheResource( "particle", "particles/custom/items/core_pumpkin_owner.vpcf", context )
       	PrecacheResource( "particle", "particles/econ/events/fall_major_2015/teleport_end_fallmjr_2015_ground_flash.vpcf", context )

	--Cache particles for traps
		PrecacheResource( "particle_folder", "particles/units/heroes/hero_dragon_knight", context )
		PrecacheResource( "particle_folder", "particles/units/heroes/hero_venomancer", context )
		PrecacheResource( "particle_folder", "particles/units/heroes/hero_axe", context )
		PrecacheResource( "particle_folder", "particles/units/heroes/hero_life_stealer", context )

	--Cache sounds for traps
		PrecacheResource( "soundfile", "soundevents/soundevents_custom.vsndevts", context )
		PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_dragon_knight.vsndevts", context )
		PrecacheResource( "soundfile", "soundevents/soundevents_conquest.vsndevts", context )
end

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
	elseif GetMapName() == "desert_octet" then
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 8 )
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 8 )
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_1, 8 )
		self.m_GoldRadiusMin = 300
		self.m_GoldRadiusMax = 1400
		self.m_GoldDropPercent = 12
	elseif GetMapName() == "desert_quintet" then
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 5 )
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 5 )
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_1, 5 )
		self.m_GoldRadiusMin = 300
		self.m_GoldRadiusMax = 1400
		self.m_GoldDropPercent = 8
	elseif GetMapName() == "temple_quartet" then
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 4 )
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 4 )
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_1, 4 )
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_2, 4 )
		self.m_GoldRadiusMin = 300
		self.m_GoldRadiusMax = 1400
		self.m_GoldDropPercent = 10
	else
		self.m_GoldRadiusMin = 250
		self.m_GoldRadiusMax = 550
		self.m_GoldDropPercent = 4
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
	GameRules:GetGameModeEntity():SetLoseGoldOnDeath( false )
	GameRules:GetGameModeEntity():SetFountainPercentageHealthRegen( 0 )
	GameRules:GetGameModeEntity():SetFountainPercentageManaRegen( 0 )
	GameRules:GetGameModeEntity():SetFountainConstantManaRegen( 0 )
	GameRules:GetGameModeEntity():SetExecuteOrderFilter( Dynamic_Wrap( COverthrowGameMode, "ExecuteOrderFilter" ), self )
	GameRules:GetGameModeEntity():SetModifierGainedFilter( Dynamic_Wrap( COverthrowGameMode, "ModifierGainedFilter" ), self )
	GameRules:GetGameModeEntity():SetModifyGoldFilter( Dynamic_Wrap( COverthrowGameMode, "ModifyGoldFilter" ), self )
	GameRules:GetGameModeEntity():SetRuneSpawnFilter( Dynamic_Wrap( COverthrowGameMode, "RuneSpawnFilter" ), self )
	GameRules:GetGameModeEntity():SetDraftingHeroPickSelectTimeOverride( 60 )
	if IsInToolsMode() then
		GameRules:GetGameModeEntity():SetDraftingBanningTimeOverride(0)
	end
	GameRules:LockCustomGameSetupTeamAssignment(true)
	GameRules:SetCustomGameSetupAutoLaunchDelay(1)


	ListenToGameEvent( "game_rules_state_change", Dynamic_Wrap( COverthrowGameMode, 'OnGameRulesStateChange' ), self )
	ListenToGameEvent( "npc_spawned", Dynamic_Wrap( COverthrowGameMode, "OnNPCSpawned" ), self )
	ListenToGameEvent( "dota_team_kill_credit", Dynamic_Wrap( COverthrowGameMode, 'OnTeamKillCredit' ), self )
	ListenToGameEvent( "entity_killed", Dynamic_Wrap( COverthrowGameMode, 'OnEntityKilled' ), self )
	ListenToGameEvent( "dota_item_picked_up", Dynamic_Wrap( COverthrowGameMode, "OnItemPickUp"), self )
	ListenToGameEvent( "dota_npc_goal_reached", Dynamic_Wrap( COverthrowGameMode, "OnNpcGoalReached" ), self )

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

	self.pumpkin_spawns = {}
	for _, entity in ipairs(Entities:FindAllByName("item_pumpkin_spawn")) do
		table.insert(self.pumpkin_spawns, {
			position = entity:GetAbsOrigin(),
			nextSpawn = 0
		})
	end

	local firstPlayerLoaded
	ListenToGameEvent("player_connect_full", function()
		if firstPlayerLoaded then return end
		firstPlayerLoaded = true
		self:BeforeMatch()
	end, nil)
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
	end, nil)
	ListenToGameEvent("player_connect_full", function(data)
		local playerId = data.PlayerID
		local player = PlayerResource:GetPlayer(playerId)
		local isHost = GameRules:PlayerHasCustomGameHostPrivileges(player)
		if TRUSTED_HOSTS[tostring(PlayerResource:GetSteamID(playerId))] and isHost then
			DISABLE_PAUSES = false
			GameRules:LockCustomGameSetupTeamAssignment(false)
			GameRules:SetCustomGameSetupAutoLaunchDelay(15)
		end
	end, nil)
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

	COverthrowGameMode:EndMatch(victoryTeam)
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
	for _, t in ipairs(sortedTeams) do
		-- Scaleform UI Scoreboard
		FireGameEvent("score_board", {
			team_id = t.team,
			team_score = t.score
		})
	end
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
	if GameRules:IsGamePaused() then
		if DISABLE_PAUSES then
			GameRules:SendCustomMessage("Pauses are disabled", -1, -1)
			PauseGame(false)
		end
		return 1
	end

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
				COverthrowGameMode:EndGame( self.leadingTeam )
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

	self.m_GatheredShuffledTeams = ShuffledList( foundTeamsList )

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

--------------------------------------------------------------------------------
-- Event: Filter for inventory full
--------------------------------------------------------------------------------
function COverthrowGameMode:ExecuteOrderFilter( filterTable )
	--[[
	for k, v in pairs( filterTable ) do
		print("EO: " .. k .. " " .. tostring(v) )
	end
	]]

	local orderType = filterTable["order_type"]
	if ( orderType ~= DOTA_UNIT_ORDER_PICKUP_ITEM or filterTable["issuer_player_id_const"] == -1 ) then
		return true
	else
		local item = EntIndexToHScript( filterTable["entindex_target"] )
		local unit = EntIndexToHScript(filterTable.units["0"])
		if not item then return true end
		local pickedItem = item:GetContainedItem()
		if not pickedItem then return true end

		local itemName = pickedItem:GetAbilityName()
		if (unit and unit:IsCourier()) and (
			itemName == "item_bag_of_gold" or
			itemName == "item_treasure_chest" or
			itemName == "item_core_pumpkin"
		) then
			local position = item:GetAbsOrigin()
			filterTable["position_x"] = position.x
			filterTable["position_y"] = position.y
			filterTable["position_z"] = position.z
			filterTable["order_type"] = DOTA_UNIT_ORDER_MOVE_TO_POSITION
			return true
		end

		if itemName == "item_treasure_chest" then
			local player = PlayerResource:GetPlayer(filterTable["issuer_player_id_const"])
			local hero = player:GetAssignedHero()
			if hero:GetNumItemsInInventory() <= DOTA_ITEM_SLOT_9 then
				return true
			else
				local position = item:GetAbsOrigin()
				filterTable["position_x"] = position.x
				filterTable["position_y"] = position.y
				filterTable["position_z"] = position.z
				filterTable["order_type"] = DOTA_UNIT_ORDER_MOVE_TO_POSITION
				return true
			end
		end
	end
	return true
end

function COverthrowGameMode:ModifierGainedFilter(filterTable)
	if filterTable.name_const == "modifier_tiny_toss" then
		local parent = EntIndexToHScript(filterTable.entindex_parent_const)
		local caster = EntIndexToHScript(filterTable.entindex_caster_const)
		local ability = EntIndexToHScript(filterTable.entindex_ability_const)

		if PlayerResource:IsDisableHelpSetForPlayerID(parent:GetPlayerOwnerID(), caster:GetPlayerOwnerID()) then
			ability:EndCooldown()
			ability:RefundManaCost()
			DisplayError(caster:GetPlayerOwnerID(), "dota_hud_error_target_has_disable_help")
			return false
		end
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

CustomGameEventManager:RegisterListener("set_disable_help", function(_, data)
	local to = data.to;
	if PlayerResource:IsValidPlayerID(to) then
		local playerId = data.PlayerID;
		local disable = data.disable == 1
		PlayerResource:SetUnitShareMaskForPlayer(playerId, to, 4, disable)

		local disableHelp = CustomNetTables:GetTableValue("disable_help", tostring(playerId)) or {}
		disableHelp[tostring(to)] = disable
		CustomNetTables:SetTableValue("disable_help", tostring(playerId), disableHelp)
	end
end)

function COverthrowGameMode:GetSortedTeams()
	local sortedTeams = {}
	for _, team in pairs(self.m_GatheredShuffledTeams) do
		table.insert(sortedTeams, { team = team, score = GetTeamHeroKills(team) })
	end

	table.sort(sortedTeams, function(a, b) return a.score > b.score end)
	return sortedTeams
end

function COverthrowGameMode:BeforeMatch()
	local players = {}
	for i = 0, 23 do
		if PlayerResource:IsValidPlayerID(i) then
			table.insert(players, tostring(PlayerResource:GetSteamID(i)))
		end
	end

	SendWebApiRequest("before-match", { mapName = GetMapName(), players = players }, function(data)
		local publicStats = {}
		for _,player in ipairs(data.players) do
			local playerId = GetPlayerIdBySteamId(player.steamId)
			Patreons:SetPlayerLevel(playerId, player.patreonLevel)
			SmartRandom:SetPlayerInfo(playerId, player.smartRandomHeroes, player.smartRandomHeroesError)

			publicStats[playerId] = {
				streak = player.streak,
				bestStreak = player.bestStreak,
				patreonLevel = player.patreonLevel,
				averageKills = player.averageKills,
				averageDeaths = player.averageDeaths,
				averageAssists = player.averageAssists,
				wins = player.wins,
				loses = player.loses,
			}
		end
		CustomNetTables:SetTableValue("game_state", "player_stats", publicStats)
	end)

	SendWebApiRequest("same-hero-day", nil, function(sameHeroDayHoursLeft)
		Patreons:SetSameHeroDayHoursLeft(sameHeroDayHoursLeft)
	end)
end

function COverthrowGameMode:EndMatch(winnerTeam)
	if not WEB_API_TESTING then
		if GameRules:IsCheatMode() then return end
		if GameRules:GetDOTATime(false, true) < 60 then return end
	end
	if winnerTeam < DOTA_TEAM_FIRST or winnerTeam > DOTA_TEAM_CUSTOM_MAX then return end
	if winnerTeam == DOTA_TEAM_NEUTRALS or winnerTeam == DOTA_TEAM_NOTEAM then return end

	local requestBody = {
		matchId = WEB_API_TESTING and RandomInt(1, 10000000) or tonumber(tostring(GameRules:GetMatchID())),
		duration = math.floor(GameRules:GetDOTATime(false, true)),
		mapName = GetMapName(),
		winner = winnerTeam,

		players = {}
	}

	for playerId = 0, 23 do
		if PlayerResource:IsValidTeamPlayerID(playerId) and not PlayerResource:IsFakeClient(playerId) then
			local playerData = {
				playerId = playerId,
				steamId = tostring(PlayerResource:GetSteamID(playerId)),
				team = PlayerResource:GetTeam(playerId),

				hero = PlayerResource:GetSelectedHeroName(playerId),
				pickReason = SmartRandom.PickReasons[playerId] or (PlayerResource:HasRandomed(playerId) and "random" or "pick"),
				kills = PlayerResource:GetKills(playerId),
				deaths = PlayerResource:GetDeaths(playerId),
				assists = PlayerResource:GetAssists(playerId),
				level = 0,
				items = {},
			}

			local hero = PlayerResource:GetSelectedHeroEntity(playerId)
			if IsValidEntity(hero) then
				playerData.level = hero:GetLevel()
				for slot = DOTA_ITEM_SLOT_1, DOTA_STASH_SLOT_6 do
					local item = hero:GetItemInSlot(slot)
					if item then
						table.insert(playerData.items, {
							slot = slot,
							name = item:GetAbilityName(),
							charges = item:GetCurrentCharges()
						})
					end
				end
			end

			table.insert(requestBody.players, playerData)
		end
	end
	if WEB_API_TESTING or #requestBody.players >= 5 then
		SendWebApiRequest("end-match", requestBody)
	end
end
