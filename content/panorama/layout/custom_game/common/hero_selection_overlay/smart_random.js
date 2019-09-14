var gridCore = FindDotaHudElement('GridCore');
var mainFilters = FindDotaHudElement('Filters');

/** @type {string[] | 'foo' | 'cooldown'} */
var smartRandomStatus;

function Activate() {
	if (smartRandomStatus == 'cooldown') {
		$.DispatchEvent('ExternalBrowserGoToURL', 'https://www.patreon.com/dota2unofficial');
	} else {
		GameEvents.SendCustomGameEventToServer("smart_random_hero", {});
	}
}

function OnMouseOver() {
	var message = Array.isArray(smartRandomStatus) ? 'ready' : smartRandomStatus;
	$.DispatchEvent('DOTAShowTextTooltip', 'smart_random_tooltip_' + message);
	if (Array.isArray(smartRandomStatus)) {
		for (var card of gridCore.Children()) {
			if (card.paneltype !== 'DOTAHeroCard') return;
			var heroName = 'npc_dota_hero_' + card.FindChildTraverse('HeroImage').heroname;
			card.SetHasClass('Filtered', smartRandomStatus.includes(heroName));
		}
	}
}

function OnMouseOut() {
	$.DispatchEvent('DOTAHideTextTooltip');
	$.DispatchEvent('DOTAUpdateEnabledHeroes', mainFilters);
}

function updateSmartRandomStatus(newStatus) {
	smartRandomStatus = newStatus;
	if (typeof smartRandomStatus === 'object') smartRandomStatus = Object.values(smartRandomStatus);
	$.GetContextPanel().SetHasClass('NoStats', smartRandomStatus === 'no_stats');
	$.GetContextPanel().SetHasClass('OnCooldown', smartRandomStatus === 'cooldown');
}

updateSmartRandomStatus('no_stats');
SubscribeToNetTableKey('game_state', 'smart_random', function(smartRandom) {
	updateSmartRandomStatus(smartRandom[Game.GetLocalPlayerID()] || 'no_stats');
});

function getBans() {
	var gridCore = FindDotaHudElement("GridCore");
	var result = {};
	for (var child of gridCore.Children()) {
		if (child.BHasClass("Banned")) {
			var heroImage = child.FindChildTraverse("HeroImage");
			if (heroImage) {
				result['npc_dota_hero_' + heroImage.heroname] = true;
			}
		}
	}

	return result;
}

GameEvents.Subscribe("banned_heroes", function(event) {
	GameEvents.SendCustomGameEventToServer("banned_heroes", {
		eventId: event.eventId,
		result: getBans(),
	});
});
