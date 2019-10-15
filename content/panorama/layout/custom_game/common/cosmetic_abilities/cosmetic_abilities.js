var cosmeticAbilityOverrideImages = {}
var cosmeticAbilities = {
	"high_five": true,
	"seasonal_ti9_banner": true,
	"seasonal_summon_cny_balloon": true,
	"seasonal_summon_dragon": true,
	"seasonal_summon_cny_tree": true,
	"seasonal_firecrackers": true,
	"seasonal_ti9_shovel": true,
	"seasonal_ti9_instruments": true,
	"seasonal_ti9_monkey": true,
	"seasonal_summon_ti9_balloon": true,
	"seasonal_throw_snowball": true,
	"seasonal_festive_firework": true,
	"seasonal_decorate_tree": true,
	"seasonal_summon_snowman": true
}
var permanentAbilitySlots = {
	"high_five": 4,
	"seasonal_ti9_banner": 5
}
var abilitiesToTake = [
	"seasonal_summon_cny_balloon",
	"seasonal_summon_dragon",
	"seasonal_summon_cny_tree",
	"seasonal_firecrackers",
	"seasonal_ti9_shovel",
	"seasonal_ti9_instruments",
	"seasonal_ti9_monkey",
	"seasonal_summon_ti9_balloon",
	"seasonal_throw_snowball",
	"seasonal_festive_firework",
	"seasonal_decorate_tree",
	"seasonal_summon_snowman"
]
var ABILITIES_CANT_BE_REMOVED = {
	"high_five": true,
	"seasonal_ti9_banner": true,
}
var abilityWebm = {
	"seasonal_summon_cny_balloon":"40XJ9",
	"seasonal_summon_dragon":"Ry9Mv",
	"seasonal_summon_cny_tree":"rVY9D",
	"seasonal_firecrackers":"Lxe64",
	"seasonal_ti9_shovel":"b1dNv",
	"seasonal_ti9_instruments":"5d1Rr",
	"seasonal_ti9_monkey":"XEjX7",
	"seasonal_summon_ti9_balloon":"BAEq9",
	"seasonal_throw_snowball":"8mBLL",
	"seasonal_festive_firework":"voBa5",
	"seasonal_decorate_tree":"Px17L",
	"seasonal_summon_snowman":"na38r"
}

var abilitySlots = []
var abilityAnimations = {}

function Ability( slot, abilityName ) {
	this.abilityName = abilityName

	var image_path = cosmeticAbilityOverrideImages[abilityName] || "file://{images}/spellicons/consumables/" + abilityName + ".png"

	this.image = $.CreatePanel( "Image", slot.panel, "Image" )
	this.image.SetImage( image_path )

	this.image.SetPanelEvent( "onactivate", function() {
		if ( Entities.IsControllableByPlayer( currentUnit, Players.GetLocalPlayer() ) ) {
			var ability = Entities.GetAbilityByName( currentUnit, abilityName )

			if ( Abilities.IsActivated( ability ) ) {
				Abilities.ExecuteAbility( ability, currentUnit, false )
			} else {
				GameEvents.SendCustomGameEventToServer( "cosmetic_abilities_try_activate", { unit: currentUnit, ability: abilityName } )
			}
		}
	} )

	var panel = this.image

	this.image.SetPanelEvent( "onmouseover", function() {
		$.DispatchEvent( "DOTAShowAbilityTooltip", panel, abilityName )
	} )
	this.image.SetPanelEvent( "onmouseout", function() {
		$.DispatchEvent( "DOTAHideAbilityTooltip", panel )
	} )

	this.cooldown = $.CreatePanel( "Panel", this.image, "Cooldown" )
	this.cooldownEffect = $.CreatePanel( "Panel", this.cooldown, "CooldownEffect" )
	this.cooldownEffect.style["opacity-mask"] = "url( '" + image_path + "' )"
	this.cooldownCountdown = $.CreatePanel( "Label", this.cooldown, "CooldownCountdown" )

	if ( !ABILITIES_CANT_BE_REMOVED[abilityName] ) {
		var deleteButton = $.CreatePanel( "Button", this.image, "DeleteButton" )

		deleteButton.SetPanelEvent( "onactivate", function() {
			if ( Entities.IsControllableByPlayer( currentUnit, Players.GetLocalPlayer() ) ) {
				GameEvents.SendCustomGameEventToServer( "cosmetic_abilities_delete", { unit: currentUnit, ability: abilityName } )
			}
		} )
	} 

	this.Update = function() {
		var ability = Entities.GetAbilityByName( currentUnit, this.abilityName )

		if ( !Abilities.IsCooldownReady( ability ) ) {
			var remaining = Abilities.GetCooldownTimeRemaining( ability )
			var progress = remaining / Abilities.GetCooldownLength( ability ) * -360

			this.cooldown.style.visibility = "visible"
			this.cooldownEffect.style.clip = "radial( 50% 75%, 0deg, " + progress + "deg )"
			this.cooldownCountdown.text = Math.ceil( remaining )
		} else {
			this.cooldown.style.visibility = "collapse"
		}
	}

	this.Delete = function() {
		this.image.DeleteAsync( 0 )
	}
}

function AbilitySlot( parent, index, style ) {
	this.panel = $.CreatePanel( "Panel", parent, "Slot" + index )
	this.panel.AddClass( style )

	this.Update = function() {
		if ( this.content && this.content.Update ) {
			this.content.Update()
		}
	}

	this.Clear = function() {
		if ( this.content ) {
			this.content.Delete()
			this.content = null
		}
	}

	this.AddContent = function( content ) {
		this.Clear()
		this.content = content
	}
}

function ReloadAbilities() {
	currentUnit = Players.GetLocalPlayerPortraitUnit()

	for ( i in abilitySlots ) {
		var slot = abilitySlots[i]
		slot.Clear()
	}

	var visible_abilities = 0

	for ( var i = 0; i < Entities.GetAbilityCount( currentUnit ); i++ ) {
		var ability = Entities.GetAbility( currentUnit, i )
		var name = Abilities.GetAbilityName( ability )

		if ( !Abilities.IsHidden( ability ) && i < 6 ) {
			visible_abilities++
		}

		if ( cosmeticAbilities[name] ) {
			var permSlot = permanentAbilitySlots[name]

			if ( permSlot ) {
				abilitySlots[permSlot].AddContent( new Ability( abilitySlots[permSlot], name ) )
			} else {
				for ( s in abilitySlots ) {
					var slot = abilitySlots[s]

					if ( !slot.content ) {
						slot.AddContent( new Ability( slot, name ) )
						break
					}
				}
			}
		}
	}

	if ( Entities.IsRealHero( currentUnit ) ) {
		$( "#CosmeticMenu" ).style.visibility = "visible"
	} else {
		$( "#CosmeticMenu" ).style.visibility = "collapse"
	}

	if ( visible_abilities > 4 ) {
		$( "#BarOverAbilities" ).AddClass( "FiveAbilities" )
	} else {
		$( "#BarOverAbilities" ).RemoveClass( "FiveAbilities" )
	}
}

function UpdateAbilities() {
	if ( Players.GetLocalPlayerPortraitUnit() != currentUnit ) {
		ReloadAbilities()
	} else {
		for ( i in abilitySlots ) {
			var slot = abilitySlots[i]
			slot.Update()
		}
	}

	$.Schedule( 1 / 60, UpdateAbilities )
}

for ( var i = 0; i < 7; i++ ) {
	if ( i > 3 ) { 
		abilitySlots[i] = new AbilitySlot( $( "#BarOverItems" ), i, "SlotOverItems" )
	} else {
		abilitySlots[i] = new AbilitySlot( $( "#BarOverAbilities" ), i, "SlotOverAbility" )
	}

}

function CreateAbilityToTake( row, abilityName ) {
	var image = $.CreatePanel( "Image", row, "ImagePreview" )
	image.SetImage( cosmeticAbilityOverrideImages[abilityName] || "file://{images}/spellicons/consumables/" + abilityName + ".png")

	abilityAnimations[abilityName] = $.CreatePanel( "Panel", $( "#AnimationContainer" ), "" )
	abilityAnimations[abilityName].BLoadLayoutFromString( '<root><Panel class="Animation"><MoviePanel src="s2r://panorama/videos/cosmetic_abilities/' + abilityWebm[abilityName] + '.webm" repeat="true" autoplay="onload" /></Panel></root>', false, false )
	abilityAnimations[abilityName].style.opacity = "0"

	image.SetPanelEvent( "onactivate", function() {
		GameEvents.SendCustomGameEventToServer( "cosmetics_add_ability", { unit: currentUnit, ability: abilityName } )
	} )

	image.SetPanelEvent( "onmouseover", function() {
		$.DispatchEvent( "DOTAShowAbilityTooltip", image, abilityName )

		abilityAnimations[abilityName].style.opacity = "1"
	} )

	image.SetPanelEvent( "onmouseout", function() {
		$.DispatchEvent( "DOTAHideAbilityTooltip", image )

		abilityAnimations[abilityName].style.opacity = "0"
	} )
}

function CreateAbilitiesToTake() {
	var abilities_row = null

	for ( var i = 0; i < abilitiesToTake.length; i++ ) {
		if ( i % 4 == 0 ) {
			abilities_row = $.CreatePanel( "Panel", $( "#AbilitiesContainer" ), "" )
			abilities_row.AddClass( "AbilitiesRow" )
		}

		CreateAbilityToTake( abilities_row, abilitiesToTake[i] )
	}
}