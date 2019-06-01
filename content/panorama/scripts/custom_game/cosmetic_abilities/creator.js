var COSMETIC_ABILITIES = {
	"high_five": true,
	"seasonal_ti9_banner": true,

	"seasonal_summon_cny_balloon": true,
	"seasonal_summon_dragon": true,
	"seasonal_summon_cny_tree": true,
	"seasonal_firecrackers": true
}

var hud = $.GetContextPanel().GetParent().GetParent().GetParent()
var lower_hud = hud.FindChildTraverse( "HUDElements" ).FindChild( "lower_hud" )
var center_with_stats = lower_hud.FindChild( "center_with_stats" )
var center_block = center_with_stats.FindChild( "center_block" )

lower_hud.style.height = "100%"
center_with_stats.style.height = "100%"
center_block.style.height = "100%"

lower_hud.FindChild( "buffs" ).style.transform = "translateY( -50px )"
lower_hud.FindChild( "debuffs" ).style.transform = "translateY( -50px )"

var newPanel = $.CreatePanel( "Panel", center_block, "CosmeticAbilities" )
newPanel.BLoadLayout( "file://{resources}/layout/custom_game/cosmetic_abilities.xml", false, false )
center_block.MoveChildBefore( newPanel, center_block.FindChild( "center_bg" ) )

center_block.FindChildrenWithClassTraverse( "TertiaryAbilityContainer" )[0].style.visibility = "collapse"

var abilities_panel = center_block.FindChild( "AbilitiesAndStatBranch" ).FindChild( "abilities" )

function HideAbilities() {
	var abilities = abilities_panel.Children()

	for ( i in abilities ) {
		var ability_name = abilities[i].FindChildTraverse( "AbilityImage" ).abilityname

		if ( COSMETIC_ABILITIES[ability_name] ) {
			abilities[i].style.visibility = "collapse"
		}
	}

	$.Schedule( 1 / 1000, HideAbilities )
}

HideAbilities()