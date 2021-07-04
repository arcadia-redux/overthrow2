Object.values = function (object) {
	return Object.keys(object).map(function (key) {
		return object[key];
	});
};

Array.prototype.includes = function (searchElement, fromIndex) {
	return this.indexOf(searchElement, fromIndex) !== -1;
};

String.prototype.includes = function (searchString, position) {
	return this.indexOf(searchString, position) !== -1;
};

function setInterval(callback, interval) {
	interval = interval / 1000;
	$.Schedule(interval, function reschedule() {
		$.Schedule(interval, reschedule);
		callback();
	});
}

function createEventRequestCreator(eventName) {
	var idCounter = 0;
	return function (data, callback) {
		var id = ++idCounter;
		data.id = id;
		GameEvents.SendCustomGameEventToServer(eventName, data);
		var listener = GameEvents.Subscribe(eventName, function (data) {
			if (data.id !== id) return;
			GameEvents.Unsubscribe(listener);
			callback(data);
		});

		return listener;
	};
}

function SubscribeToNetTableKey(tableName, key, callback) {
	var immediateValue = CustomNetTables.GetTableValue(tableName, key) || {};
	if (immediateValue != null) callback(immediateValue);
	CustomNetTables.SubscribeNetTableListener(tableName, function (_tableName, currentKey, value) {
		if (currentKey === key && value != null) callback(value);
	});
}

const FindDotaHudElement = (id) => dotaHud.FindChildTraverse(id);
const dotaHud = (() => {
	let panel = $.GetContextPanel();
	while (panel) {
		if (panel.id === "DotaHud") return panel;
		panel = panel.GetParent();
	}
})();

var useChineseDateFormat = $.Language() === "schinese" || $.Language() === "tchinese";
/** @param {Date} date */
function formatDate(date) {
	return useChineseDateFormat
		? date.getFullYear() + "-" + date.getMonth() + "-" + date.getDate()
		: date.getMonth() + "/" + date.getDate() + "/" + date.getFullYear();
}

let boostGlow = false;
let glowSchelude;
const CENTER_SCREEN_MENUS = ["CollectionDotaU"];

function ToggleMenu(name) {
	FindDotaHudElement(name).ToggleClass("show");
	if (name == "CollectionDotaU") {
		if (glowSchelude != null) {
			$.CancelScheduled(glowSchelude);
		}
		const glowPanel = FindDotaHudElement("DonateFocus");
		glowPanel.SetHasClass("show", boostGlow);
		if (boostGlow)
			glowSchelude = $.Schedule(4, () => {
				glowSchelude = undefined;
				glowPanel.SetHasClass("show", false);
			});
	}
	CENTER_SCREEN_MENUS.forEach((panelName) => {
		if (panelName != name) FindDotaHudElement(panelName).SetHasClass("show", false);
	});
}

function _AddMenuButton(buttonId) {
	return $.CreatePanel("Button", $.GetContextPanel(), buttonId);
}
function CreateButtonInTopMenu(button, activateEvent, overEvent, outEvent) {
	button.SetPanelEvent("onactivate", activateEvent);
	button.SetPanelEvent("onmouseover", overEvent);

	button.SetPanelEvent("onmouseout", outEvent);

	let menu = FindDotaHudElement("ButtonBar");
	let existingPanel = menu.FindChildTraverse(button.id);
	if (existingPanel) existingPanel.DeleteAsync(0.1);
	if (menu)
		menu.Children().forEach((button) => {
			button.style.verticalAlign = "top";
		});
	button.SetParent(menu);
}

function _GetVarFromUniquePortraitsData(player_id, hero_name, path) {
	const unique_portraits = CustomNetTables.GetTableValue("game_state", "portraits");
	if (unique_portraits && unique_portraits[player_id]) {
		return `${path}${unique_portraits[player_id]}.png`;
	} else {
		return `${path}${hero_name}.png`;
	}
}

function GetPortraitImage(player_id, hero_name) {
	return _GetVarFromUniquePortraitsData(player_id, hero_name, "file://{images}/heroes/");
}
function GetPortraitIcon(player_id, hero_name) {
	return _GetVarFromUniquePortraitsData(player_id, hero_name, "file://{images}/heroes/icons/");
}

function GetHEXPlayerColor(player_id) {
	var player_color = Players.GetPlayerColor(player_id).toString(16);
	return player_color == null
		? "#000000"
		: "#" +
				player_color.substring(6, 8) +
				player_color.substring(4, 6) +
				player_color.substring(2, 4) +
				player_color.substring(0, 2);
}
