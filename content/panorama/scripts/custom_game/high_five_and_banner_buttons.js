function Activate( ability ) {
	var unit = Players.GetLocalPlayerPortraitUnit()
	
	if ( Entities.IsControllableByPlayer( unit, Players.GetLocalPlayer() ) ) {
		GameEvents.SendCustomGameEventToServer( "cons_ability_activate", {
			unit: Players.GetLocalPlayerPortraitUnit(),
			ability: ability,
		} )
	}
}

function ShowToolTip( ability, id ) {
	$.DispatchEvent( "DOTAShowAbilityTooltip", $( "#" + id ), ability );
}

function HideToolTip( id ) {
	$.DispatchEvent( "DOTAHideAbilityTooltip", $( "#" + id ) );
}

function UpdateButton( button, ability ) {
	var ability = Entities.GetAbilityByName( Players.GetLocalPlayerPortraitUnit(), ability )

	if ( ability != -1 ) {
		button.style.visibility = "visible"

		var cooldown_panel = button.FindChildTraverse( "Cooldown" )

		if ( !Abilities.IsCooldownReady( ability ) ) {
			cooldown_panel.style.visibility = "visible"

			var remaining = Abilities.GetCooldownTimeRemaining( ability )

			button.FindChildTraverse( "CooldownText" ).text = Math.floor( remaining )

			/*var progress = ( -360 * ( remaining / Abilities.GetCooldownLength( ability ) ) ).toString()

			$( "#CooldownBackground" ).style.clip = "radial( 50% 50%, 0deg, " + progress + "deg )"*/
		} else {
			cooldown_panel.style.visibility = "collapse"
		}
	} else {
		button.style.visibility = "collapse"
	}
}

function Update() {
	UpdateButton( $( "#HighFive" ), "high_five" )
	UpdateButton( $( "#Banner" ), "seasonal_ti9_banner" )

	$.Schedule( 1 / 30, Update )
}

Update()