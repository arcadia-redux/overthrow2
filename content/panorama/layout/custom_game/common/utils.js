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

function GetDotaHud() {
	var panel = $.GetContextPanel();
	while (panel && panel.id !== "Hud") {
		panel = panel.GetParent();
	}

	if (!panel) {
		throw new Error("Could not find Hud root from panel with id: " + $.GetContextPanel().id);
	}

	return panel;
}

function FindDotaHudElement(id) {
	return GetDotaHud().FindChildTraverse(id);
}

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
