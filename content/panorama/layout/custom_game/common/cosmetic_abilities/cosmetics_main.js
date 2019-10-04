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

function SaveSettings() {
	GameEvents.SendCustomGameEventToServer( "cosmetics_save", {} )
}

function UpdateSaveButton( i ) {
	if ( i == 0 ) {
		$( "#SaveSettings" ).style.visibility = "visible"
	} else {
		$( "#SaveSettings" ).style.visibility = "collapse"
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
			currentEffects.hero = t.hero_effect
			currentEffects.pet = t.pet_effect
			currentEffects.wards = t.wards_effect
			UpdateCurrentHeroEffect( currentEffects[selectedEffectType] )
			currentColors.hero = t.hero_color
			currentColors.pet = t.pet_color
			currentColors.wards = t.wards_color
			UpdateCurrentEffectColor( currentColors[selectedEffectType] )
			UpdateCurrentKillEffect( t.kill_effects )
			UpdateCurrentPet( t.pet )
			UpdateSaveButton( t.saved )
		}

		var tt = CustomNetTables.GetTableValue( "cosmetics", "team_" + Players.GetTeam( id ) )

		if ( tt ) {
			currentEffects.courier = tt.courier_effect
			currentColors.courier = tt.courier_color
			UpdateCurrentHeroEffect( currentEffects[selectedEffectType] )
			UpdateCurrentEffectColor( currentColors[selectedEffectType] )
		}
	}
}

Load()

CustomNetTables.SubscribeNetTableListener( "cosmetics", function( _, k, v ) {
	if ( k == Players.GetLocalPlayer().toString() ) {
		UpdateCurrentHeroEffect( v.hero_effects )
		currentEffects.hero = v.hero_effect
		currentEffects.pet = v.pet_effect
		currentEffects.wards = v.wards_effect
		UpdateCurrentHeroEffect( currentEffects[selectedEffectType] )
		currentColors.hero = v.hero_color
		currentColors.pet = v.pet_color
		currentColors.wards = v.wards_color
		UpdateCurrentEffectColor( currentColors[selectedEffectType] )
		UpdateCurrentKillEffect( v.kill_effects )
		UpdateCurrentPet( v.pet )
		UpdateSaveButton( v.saved )
	} else if ( k == "team_" + Players.GetTeam( Players.GetLocalPlayer() ) ) {
		currentEffects.courier = v.courier_effect
		currentColors.courier = v.courier_color
		UpdateCurrentHeroEffect( currentEffects[selectedEffectType] )
		UpdateCurrentEffectColor( currentColors[selectedEffectType] )
	}
} )