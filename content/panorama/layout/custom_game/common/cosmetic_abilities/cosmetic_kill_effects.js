var killEffects = [
	"firework",
	"tombstone",
	"incineration",
	"halloween"
]

var killEffectAnimations = {}

function DeleteKillEffect() {
	GameEvents.SendCustomGameEventToServer( "cosmetics_remove_kill_effect", {} )
}

function CreateKillEffect( parent, effectName ) {
	var hero_effect = $.CreatePanel( "Button", parent, "" )
	hero_effect.AddClass( "HeroEffect" )

	hero_effect.SetPanelEvent( "onactivate", function() {
		GameEvents.SendCustomGameEventToServer( "cosmetics_set_kill_effect", {
			effect_name: effectName
		} )
	} )

	killEffectAnimations[effectName] = $.CreatePanel( "Panel", $( "#AnimationContainer" ), "" )
	killEffectAnimations[effectName].BLoadLayoutFromString( '<root><Panel class="Animation"><MoviePanel src="s2r://panorama/videos/kill_effects/' + effectName + '.webm" repeat="true" autoplay="onload" /></Panel></root>', false, false )
	killEffectAnimations[effectName].style.opacity = "0"

	hero_effect.SetPanelEvent( "onmouseover", function() {
		killEffectAnimations[effectName].style.opacity = "1"
	} )

	hero_effect.SetPanelEvent( "onmouseout", function() {
		killEffectAnimations[effectName].style.opacity = "0"
	} )

	$.CreatePanel( "Label", hero_effect, "" ).text = $.Localize( "cosmetics_kill_effect_" + effectName )
}

function CreateKillEffects() {
	var container = $( "#KillEffectsContainer" )

	for ( var name of killEffects ) {
		CreateKillEffect( container, name )
	}
}

function UpdateCurrentKillEffect( effectName ) {
	if ( effectName ) {
		var current = $( "#CurrentKillEffect" )

		current.text = $.Localize( "cosmetics_kill_effect_" + effectName )
		current.AddClass( "CurrentEffect" )
		current.RemoveClass( "None" )
		$( "#DeleteKillEffect" ).style.visibility = "visible"
	} else {
		var current = $( "#CurrentKillEffect" )
		
		current.text = "none"
		current.RemoveClass( "CurrentEffect" )
		current.AddClass( "None" )
		$( "#DeleteKillEffect" ).style.visibility = "collapse"
	}
}

CreateKillEffects()