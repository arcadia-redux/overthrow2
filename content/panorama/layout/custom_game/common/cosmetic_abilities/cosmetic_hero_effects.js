var heroEffects = []
heroEffects[1] = "#Attrib_Particle156"
heroEffects[2] = "#Attrib_Particle155"
heroEffects[3] = "#Attrib_Particle109"
heroEffects[4] = "#Attrib_Particle185"
heroEffects[5] = "#Attrib_Particle73"
heroEffects[7] = "#Attrib_Particle159"
heroEffects[8] = "#Attrib_Particle129"
heroEffects[9] = "#Attrib_Particle22"
heroEffects[10] = "#Attrib_Particle4"
heroEffects[11] = "#Attrib_Particle15"
heroEffects[12] = "#Attrib_Particle37"
heroEffects[13] = "#Attrib_Particle57"
heroEffects[14] = "#Attrib_Particle76"
heroEffects[15] = "#Attrib_Particle61"
heroEffects[16] = "#Attrib_Particle196"
heroEffects[17] = "#Attrib_Particle268"
heroEffects[18] = "#Attrib_Particle157"
heroEffects[20] = "#Attrib_Particle46"
heroEffects[21] = "#Attrib_Particle74"
heroEffects[22] = "#Attrib_Particle158"
heroEffects[23] = "Supporter Emblem"

var prismaticColors = []
prismaticColors[1] = { name: "#UnusualShips", r: 25, g: 25, b: 112 }
prismaticColors[2] = { name: "#UnusualMannsMint", r: 188, g: 221, b: 179 }
prismaticColors[3] = { name: "#UnusualMiasma", r: 192, g: 192, b: 192 }
prismaticColors[4] = { name: "#UnusualGold", r: 207, g: 171, b: 49 }
prismaticColors[5] = { name: "#UnusualInternational2014", r: 127, g: 72, b: 195 }
prismaticColors[6] = { name: "#UnusualCreatorsLight", r: 220, g: 242, b: 255 }
prismaticColors[7] = { name: "#UnusualSummerWarmth", r: 255, g: 238, b: 188 }
prismaticColors[8] = { name: "#UnusualPlushShagbark", r: 255, g: 193, b: 220 }
prismaticColors[9] = { name: "#UnusualPurple", r: 130, g: 50, b: 207 }
prismaticColors[10] = { name: "#UnusualIceRoshan", r: 50, g: 171, b: 220 }
prismaticColors[11] = { name: "#UnusualLavaRoshan", r: 255, g: 120, b: 50 }
prismaticColors[12] = { name: "#UnusualEarthGreen", r: 90, g: 195, b: 85 }
prismaticColors[13] = { name: "#UnusualAbysm", r: 255, g: 60, b: 40 }
prismaticColors[14] = { name: "#UnusualVermilionRenewal", r: 202, g: 1, b: 35 }
prismaticColors[15] = { name: "#UnusualInternational2013", r: 21, g: 165, b: 21 }
prismaticColors[16] = { name: "#UnusualPristinePlatinum", r: 213, g: 227, b: 245 }
prismaticColors[17] = { name: "#UnusualUnhallowedGround", r: 128, g: 128, b: 0 }
prismaticColors[18] = { name: "#UnusualBrightGreen", r: 161, g: 255, b: 89 }
prismaticColors[19] = { name: "#UnusualBusinessPants", r: 240, g: 230, b: 140 }
prismaticColors[20] = { name: "#UnusualBrightPurple", r: 130, g: 50, b: 237 }
prismaticColors[21] = { name: "#UnusualDungeonDoom", r: 123, g: 104, b: 238 }
prismaticColors[22] = { name: "#UnusualDeepBlue", r: 61, g: 104, b: 196 }
prismaticColors[23] = { name: "#UnusualVerdantGreen", r: 81, g: 179, b: 80 }
prismaticColors[24] = { name: "#UnusualDredgeEarth", r: 189, g: 183, b: 107 }
prismaticColors[25] = { name: "#UnusualCursedBlack", r: 6, g: 6, b: 6 }
prismaticColors[26] = { name: "#UnusualEmberFlame", r: 255, g: 198, b: 4 }
prismaticColors[27] = { name: "#UnusualMidasGold", r: 255, g: 202, b: 21 }
prismaticColors[28] = { name: "#UnusualDeepGreen", r: 55, g: 134, b: 77 }
prismaticColors[29] = { name: "#UnusualPlagueGrey", r: 98, g: 110, b: 91 }
prismaticColors[30] = { name: "#UnusualOrange", r: 208, g: 119, b: 51 }
prismaticColors[31] = { name: "#UnusualCrystallineBlue", r: 26, g: 61, b: 133 }
prismaticColors[32] = { name: "#UnusualBlue", r: 0, g: 151, b: 206 }
prismaticColors[33] = { name: "#UnusualPlacidBlue", r: 148, g: 202, b: 208 }
prismaticColors[34] = { name: "#UnusualDefensiveRed", r: 255, g: 66, b: 0 }
prismaticColors[35] = { name: "#UnusualBlossomRed", r: 215, g: 96, b: 146 }
prismaticColors[36] = { name: "#UnusualRed", r: 208, g: 61, b: 51 }
prismaticColors[37] = { name: "#UnusualInternational2012", r: 80, g: 125, b: 254 }
prismaticColors[38] = { name: "#UnusualSeaGreen", r: 74, g: 183, b: 141 }
prismaticColors[39] = { name: "#UnusualLightGreen", r: 183, g: 207, b: 51 }
prismaticColors[40] = { name: "#UnusualSwine", r: 255, g: 175, b: 0 }
prismaticColors[41] = { name: "#UnusualDiretideOrange", r: 247, g: 157, b: 0 }
prismaticColors[42] = { name: "#UnusualRubiline", r: 209, g: 31, b: 161 }

var selectedEffectType = null
var currentEffects = {}
var currentColors = {}

function DeleteEffect() {
	GameEvents.SendCustomGameEventToServer( "cosmetics_remove_hero_effect", { type: selectedEffectType } )
}

function DeleteColor() {
	GameEvents.SendCustomGameEventToServer( "cosmetics_remove_effect_color", { type: selectedEffectType } )
}

function SetEffectType( type ) {
	if ( selectedEffectType != type ) {
		$( "#EffectOwner" ).RemoveClass( selectedEffectType )
		$( "#EffectOwner" ).AddClass( type )
		selectedEffectType = type
		UpdateCurrentHeroEffect( currentEffects[type] )
		UpdateCurrentEffectColor( currentColors[type] )
	}
}

SetEffectType( "hero" )

function CreateHeroEffect( parent, heroEffectName, heroEffectIndex ) {
	var hero_effect = $.CreatePanel( "Button", parent, "" )
	hero_effect.AddClass( "HeroEffect" )

	hero_effect.SetPanelEvent( "onactivate", function() {
		GameEvents.SendCustomGameEventToServer( "cosmetics_set_hero_effect", {
			index: heroEffectIndex,
			type: selectedEffectType
		} )
	} )

	hero_effect.SetPanelEvent( "onmouseover", function() {
		var preview = $( "#PreviewImage" )

		preview.SetImage( "file://{resources}/layout/custom_game/common/cosmetic_abilities/preview/effects/" + heroEffectIndex + ".png" )
		preview.SetHasClass( "Visible", true )
	} )

	hero_effect.SetPanelEvent( "onmouseout", function() {
		var preview = $( "#PreviewImage" )

		preview.SetImage( "file://{resources}/layout/custom_game/common/cosmetic_abilities/preview/effects/" + heroEffectIndex + ".png" )
		preview.SetHasClass( "Visible", false )
	} )

	$.CreatePanel( "Label", hero_effect, "" ).text = $.Localize( heroEffectName )
}

function CreateEffectColor( parent, index ) {
	var hero_effect = $.CreatePanel( "Button", parent, "" )
	hero_effect.AddClass( "EffectColor" )

	var c = prismaticColors[index]

	hero_effect.style["background-color"] = "rgb( " + c.r + ", " + c.g + ", " + c.b + " )"

	hero_effect.SetPanelEvent( "onactivate", function() {
		GameEvents.SendCustomGameEventToServer( "cosmetics_set_effect_color", {
			index: index,
			type: selectedEffectType
		} )
	} )
}

function CreateHeroEffects() {
	var container = $( "#HeroEffectsContainer" )

	for ( var i in heroEffects ) {
		CreateHeroEffect( container, heroEffects[i], i )
	}

	container = $( "#EffectColorsContainer" )

	for ( var i in prismaticColors ) {
		CreateEffectColor( container, i )
	}
}

function UpdateCurrentHeroEffect( index ) {
	if ( index ) {
		var current = $( "#CurrentEffect" )

		current.text = $.Localize( heroEffects[index] )
		current.AddClass( "CurrentEffect" )
		current.RemoveClass( "None" )
		$( "#DeleteEffect" ).style.visibility = "visible"
	} else {
		var current = $( "#CurrentEffect" )
		
		current.text = "none"
		current.RemoveClass( "CurrentEffect" )
		current.AddClass( "None" )
		$( "#DeleteEffect" ).style.visibility = "collapse"
	}
}

function UpdateCurrentEffectColor( index ) {
	if ( index ) {
		var c = prismaticColors[index]
		var current = $( "#CurrentColor" )

		current.text = $.Localize( c.name )
		current.RemoveClass( "None" )
		current.style.color = "rgb( " + c.r + ", " + c.g + ", " + c.b + " )"
		$( "#DeleteColor" ).style.visibility = "visible"
	} else {
		var current = $( "#CurrentColor" )

		current.text = "none"
		current.AddClass( "None" )
		current.style.color = null
		$( "#DeleteColor" ).style.visibility = "collapse"
	}
}

CreateHeroEffects()