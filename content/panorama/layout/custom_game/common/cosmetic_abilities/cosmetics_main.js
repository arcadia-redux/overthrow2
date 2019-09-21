var currentUnit = null
var currentClass = null

function ToggleCosmeticMenu() {
	$.GetContextPanel().ToggleClass( "Open" )
}

function SetCosmeticsClass( style ) {
	if ( currentClass !== style ) {
		$( "#CosmeticMenuMain" ).RemoveClass( currentClass )
		$( "#CosmeticMenuMain" ).AddClass( style )
		currentClass = style
	}
}

SetCosmeticsClass( "Abilities" )

CreateAbilitiesToTake()
UpdateAbilities()
GameEvents.Subscribe( "cosmetics_reload_abilities", ReloadAbilities )

function Load() {
	var id = Players.GetLocalPlayer()

	if ( id !== -1 ) {
		var t = CustomNetTables.GetTableValue( "cosmetics", id.toString() )

		if ( t ) {
			UpdateCurrentHeroEffect( t.hero_effects )
			UpdateCurrentEffectColor( t.effect_colors )
			UpdateCurrentKillEffect( t.kill_effects )
		}
	}
}

Load()

CustomNetTables.SubscribeNetTableListener( "cosmetics", function( _, k, v ) {
	if ( k == Players.GetLocalPlayer().toString() ) {
		UpdateCurrentHeroEffect( v.hero_effects )
		UpdateCurrentEffectColor( v.effect_colors )
		UpdateCurrentKillEffect( v.kill_effects )
		UpdateCurrentPet( v.pet )
	}
} )