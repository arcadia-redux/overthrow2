const ITEMS_TIER_COLORS = {
	1: "#bdbdbd",
	2: "#92e47e",
	3: "#7d90f6",
	4: "#d27afc",
	5: "#fedd8a",
};

function OnPickedUpItem(data) {
	const panel = $.CreatePanel("Panel", $("#IngameNotifications"), "");
	panel.BLoadLayoutSnippet("PickUpItem");
	const itemPanel = panel.GetChild(0);
	const color = ITEMS_TIER_COLORS[data.tier] || ITEMS_TIER_COLORS[1];

	itemPanel.itemname = data.itemName;
	let position = data.position.split(" ");
	position.forEach((value, index) => {
		position[index] = parseInt(value);
	});
	itemPanel.ClearPanelEvent("onmouseover");
	itemPanel.ClearPanelEvent("onmouseout");
	itemPanel.style.borderColor = color;
	itemPanel.style.boxShadow = "inset " + color + " 0px 0px 4px 0px;";
	const freezePosition = function (panel, position) {
		const nX = Game.WorldToScreenX(position[0], position[1], position[2]);
		const nY = Game.WorldToScreenY(position[0], position[1], position[2]);
		panel.style.x = nX / panel.actualuiscale_x - panel.actuallayoutwidth / 2 + "px";
		panel.style.y = nY / panel.actualuiscale_y - 50 + "px";
		$.Schedule(0.01, () => {
			if (panel.BHasClass("Show")) freezePosition(panel, position);
		});
	};
	freezePosition(panel, position);

	panel.SetHasClass("PlayUp", true);
	panel.SetHasClass("Show", true);
	Game.EmitSound("Dungeon.Plus1");
	$.Schedule(0.8, () => {
		panel.SetHasClass("Show", false);
		panel.DeleteAsync(0.4);
	});
}

GameEvents.Subscribe("OnPickedUpItem", OnPickedUpItem);
