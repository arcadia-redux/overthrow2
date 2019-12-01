var gridCategories = FindDotaHudElement('GridCategories');
function getAllHeroCards() {
	return gridCategories.FindChildrenWithClassTraverse("HeroCard");
}

/** @type {string[] | 'no_stats' | 'cooldown'} */
var smartRandomStatus;

function Activate() {
	if (Array.isArray(smartRandomStatus)) {
		GameEvents.SendCustomGameEventToServer("smart_random_hero", {});
	} else {
		$.DispatchEvent('ExternalBrowserGoToURL', 'https://www.patreon.com/dota2unofficial');
	}
}

function OnMouseOver() {
	var message = Array.isArray(smartRandomStatus) ? 'ready' : smartRandomStatus;
	$.DispatchEvent('DOTAShowTextTooltip', 'smart_random_tooltip_' + message);
	if (Array.isArray(smartRandomStatus)) {
		for (var card of getAllHeroCards()) {
			var shortName = card.FindChildTraverse('HeroImage').heroname;
			var heroName = 'npc_dota_hero_' + shortName;
			card.SetHasClass('Filtered', !smartRandomStatus.includes(heroName));
		}
	}
}

var filters = FindDotaHudElement('Filters');
function OnMouseOut() {
	$.DispatchEvent('DOTAHideTextTooltip');
	$.DispatchEvent('DOTAHeroGridToggleRecommendedHeroesFilter', filters);
	$.DispatchEvent('DOTAHeroGridToggleRecommendedHeroesFilter', filters);
}

function updateSmartRandomStatus(newStatus) {
	smartRandomStatus = newStatus;
	if (typeof smartRandomStatus === 'object') smartRandomStatus = Object.values(smartRandomStatus);
	$.GetContextPanel().SetHasClass('IsError', !Array.isArray(smartRandomStatus));
}

updateSmartRandomStatus('no_stats');
SubscribeToNetTableKey('game_state', 'smart_random', function(smartRandom) {
	updateSmartRandomStatus(smartRandom[Game.GetLocalPlayerID()] || 'no_stats');
});

function getBans() {
	var result = {};
	for (var child of getAllHeroCards()) {
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
