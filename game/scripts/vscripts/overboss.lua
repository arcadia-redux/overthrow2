function ThrowCoin( args )
--	print( "ThrowCoin" )
	local coinAttach = args.caster:ScriptLookupAttachment( "coin_toss_point" )
	local coinSpawn = Vector( 0, 0, 0 )
	if coinAttach ~= -1 then
		coinSpawn = args.caster:GetAttachmentOrigin( coinAttach )
	end
--	print( coinSpawn )

	if RandomInt(1, 7) == 1 then
		GameRules:GetGameModeEntity().COverthrowGameMode:LaunchCenterTreasure( coinSpawn )
	else
		GameRules:GetGameModeEntity().COverthrowGameMode:SpawnGoldEntity( coinSpawn )
	end
end