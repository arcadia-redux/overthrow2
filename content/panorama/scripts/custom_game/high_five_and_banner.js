highFiveButton = null

function CreateButton( parent ) {
	highFiveButton = $.CreatePanel( "Button", parent, "" )

	if ( highFiveButton ) {
		highFiveButton.BLoadLayout( "file://{resources}/layout/custom_game/high_five_and_banner_buttons.xml", false, false )

		parent.MoveChildBefore( highFiveButton, parent.FindChildTraverse( "center_bg" ) )
	}
}

function Update() {
	var hud = $.GetContextPanel().GetParent().GetParent().GetParent()
	var pp = hud.FindChildTraverse( "HUDElements" ).FindChildTraverse( "lower_hud" )
	pp.FindChildTraverse( "buffs" ).style.transform = "translateY( -46px )"
	pp.FindChildTraverse( "debuffs" ).style.transform = "translateY( -46px )"

	if ( !highFiveButton ) { 
		CreateButton( pp.FindChildTraverse( "center_with_stats" ).FindChildTraverse( "center_block" ) )
	}

	$.Schedule( 1 / 30, Update )
}

Update()