var images = {
	"high_five": "file://{images}/spellicons/consumables/high_five.png",
	"seasonal_ti9_banner": "file://{images}/spellicons/consumables/seasonal_ti9_banner.png",
	"seasonal_summon_cny_balloon": "file://{images}/spellicons/consumables/seasonal_summon_cny_balloon.png",
	"seasonal_summon_dragon": "file://{images}/spellicons/consumables/seasonal_summon_dragon.png",
	"seasonal_summon_cny_tree": "file://{images}/spellicons/consumables/seasonal_summon_cny_tree.png",
	"seasonal_firecrackers": "file://{images}/spellicons/consumables/seasonal_firecrackers.png",
}
var cosmeticAbilities = {
	"high_five": true,
	"seasonal_ti9_banner": true,

	"seasonal_summon_cny_balloon": true,
	"seasonal_summon_dragon": true,
	"seasonal_summon_cny_tree": true,
	"seasonal_firecrackers": true
}
var permanentAbilitySlots = {
	"high_five": 4,
	"seasonal_ti9_banner": 5
}
var abilitiesInShowcase = [
	"seasonal_summon_cny_balloon",
	"seasonal_summon_dragon",
	"seasonal_summon_cny_tree",
	"seasonal_firecrackers"
]
var showcaseAbilitiesSlot = 6
var slots = []

var currentUnit = null
var currentAbilitiesCount = 0

function AbilityToTake( showcase, abilityName ) {
	this.abilityName = abilityName

	this.image = $.CreatePanel( "Image", showcase.showcase, "ImagePreview" )
	this.image.SetImage( images[abilityName] )

	this.image.SetPanelEvent( "onactivate", function() {
		if ( Entities.IsControllableByPlayer( currentUnit, Players.GetLocalPlayer() ) ) {
			GameEvents.SendCustomGameEventToServer( "cosmetic_abilities_take", { unit: currentUnit, ability: abilityName } )
		}
	} )

	var panel = this.image

	this.image.SetPanelEvent( "onmouseover", function() {
		$.DispatchEvent( "DOTAShowAbilityTooltip", panel, abilityName )
	} )
	this.image.SetPanelEvent( "onmouseout", function() {
		$.DispatchEvent( "DOTAHideAbilityTooltip", panel )
	} )
}

function ShowcaseAbilities( slot ) {
	this.showcase = $.CreatePanel( "Panel", slot.panel, "Showcase" )
	this.showcaseSignboard = $.CreatePanel( "Button", this.showcase, "ShowcaseSignboard" )
	this.showcaseSignboardText = $.CreatePanel( "Label", this.showcaseSignboard, "ShowcaseSignboardText" )
	this.showcaseSignboardText.text = "Cosmetic"

	var showcase = this.showcase 

	this.showcaseSignboard.SetPanelEvent( "onactivate", function() {
		showcase.ToggleClass( "Open" )
	} )

	this.abilities = []

	for ( var i = 0; i < abilitiesInShowcase.length; i++ ) {
		this.abilities[i] = new AbilityToTake( this, abilitiesInShowcase[i] )
	}

	this.Delete = function() {
		this.showcase.DeleteAsync( 0 )
	}
}

function Ability( slot, abilityName ) {
	this.abilityName = abilityName

	this.image = $.CreatePanel( "Image", slot.panel, "Image" )
	this.image.SetImage( images[abilityName] )

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
	this.cooldownEffect.style["opacity-mask"] = "url( '" + images[abilityName] + "' )"
	this.cooldownCountdown = $.CreatePanel( "Label", this.cooldown, "CooldownCountdown" )

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

function Slot( parent, index, style ) {
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

function Reload() {
	currentUnit = Players.GetLocalPlayerPortraitUnit()

	for ( i in slots ) {
		var slot = slots[i]
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
				slots[permSlot].AddContent( new Ability( slots[permSlot], name ) )
			} else {
				for ( s in slots ) {
					var slot = slots[s]

					if ( !slot.content ) {
						slot.AddContent( new Ability( slot, name ) )
						break
					}
				}
			}
		}
	}

	if ( Entities.IsRealHero( currentUnit ) && showcaseAbilitiesSlot ) {
		var slot = slots[showcaseAbilitiesSlot]
		slot.AddContent( new ShowcaseAbilities( slot ) )
	}

	if ( visible_abilities > 4 ) {
		$( "#BarOverAbilities" ).AddClass( "FiveAbilities" )
	} else {
		$( "#BarOverAbilities" ).RemoveClass( "FiveAbilities" )
	}
}

function Update() {
	if ( Players.GetLocalPlayerPortraitUnit() != currentUnit ) {
		Reload()
	} else {
		for ( i in slots ) {
			var slot = slots[i]
			slot.Update()
		}
	}

	$.Schedule( 1 / 60, Update )
}

for ( var i = 0; i < 7; i++ ) {
	if ( i > 3 ) { 
		slots[i] = new Slot( $( "#BarOverItems" ), i, "SlotOverItems" )
	} else {
		slots[i] = new Slot( $( "#BarOverAbilities" ), i, "SlotOverAbility" )
	}

}

GameEvents.Subscribe( "cosmetic_abilities_reload_hud", Reload )

Update()