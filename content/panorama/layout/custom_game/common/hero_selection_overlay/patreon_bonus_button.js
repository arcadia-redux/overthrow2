var isPatreon = false;

function GoToPatreonPage() {
	if (isPatreon) return;
	$.DispatchEvent('ExternalBrowserGoToURL', 'https://www.patreon.com/dota2unofficial')
}

function TogglePatreonBonusButton() {
	if (!isPatreon) return;
	var enabled = $('#PatreonBonusButton').checked;
	GameEvents.SendCustomGameEventToServer("patreon_toggle_boots", { enabled: enabled } );
}

function OnMouseOver() {
	if (isPatreon) return;
	$.DispatchEvent('DOTAShowTextTooltip', '#patreon_bonus_button_tooltip')
}

var firstUpdate = true;
SubscribeToNetTableKey('game_state', 'patreon_bonuses', function(patreonBonuses) {
	var playerBonuses = patreonBonuses[Game.GetLocalPlayerID()];
	if (!playerBonuses) return;

	if (!firstUpdate) return;
	firstUpdate = false;

	isPatreon = playerBonuses.level > 0;
	$('#PatreonBonusButton').enabled = isPatreon;
	$('#PatreonBonusButton').checked = isPatreon && playerBonuses.bootsEnabled;
});
