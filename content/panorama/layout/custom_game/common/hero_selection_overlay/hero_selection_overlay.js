var startingItemsLeftColumn = FindDotaHudElement("StartingItemsLeftColumn");
for (var child of startingItemsLeftColumn.Children()) {
	if (child.BHasClass('PatreonBonusButtonContainer')) {
		child.DeleteAsync(0);
	}
}

var inventoryStrategyControl = FindDotaHudElement("InventoryStrategyControl");
inventoryStrategyControl.style.marginTop = (46 - 32) + 'px';

var patreonBonusButton = $.CreatePanel("Panel", startingItemsLeftColumn, "");
patreonBonusButton.BLoadLayout("file://{resources}/layout/custom_game/common/hero_selection_overlay/patreon_bonus_button.xml", false, false);
startingItemsLeftColumn.MoveChildAfter(patreonBonusButton, startingItemsLeftColumn.GetChild(0));

var heroPickRightColumn = FindDotaHudElement('HeroPickRightColumn');
var smartRandomButton = heroPickRightColumn.FindChildTraverse('smartRandomButton');
if (smartRandomButton != null) smartRandomButton.DeleteAsync(0);
smartRandomButton = $.CreatePanel('Button', heroPickRightColumn, 'smartRandomButton');
smartRandomButton.BLoadLayout("file://{resources}/layout/custom_game/common/hero_selection_overlay/smart_random.xml", false, false);

SubscribeToNetTableKey('game_state', 'player_stats', function(playerStats) {
	var localStats = playerStats[Game.GetLocalPlayerID()];
	if (!localStats) return;

	$('#PlayerStatsAverageWinsLoses').text = localStats.wins + '/' + localStats.loses;
	$('#PlayerStatsAverageKDA').text = [
		localStats.averageKills,
		localStats.averageDeaths,
		localStats.averageAssists,
	].map(Math.round).join('/');
});

$.GetContextPanel().SetDialogVariable('map_name', Game.GetMapInfo().map_display_name);
