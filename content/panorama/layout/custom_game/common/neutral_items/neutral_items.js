itemPanels = [];
droppedItems = [];

$("#ItemsContainer").RemoveAndDeleteChildren();

function NeutralItemDropped(data) {
	Game.EmitSound("Loot_Drop_Stinger_Short");
	let item = $.CreatePanel("Panel", $("#ItemsContainer"), "");
	item.BLoadLayoutSnippet("TakeItem");
	item.AddClass("Slide");
	item.FindChildTraverse("ItemImage").itemname = data.itemName;
	item.FindChildTraverse("ButtonTake").SetPanelEvent("onactivate", function () {
		GameEvents.SendCustomGameEventToServer("neutral_item_take", {
			item: data.item,
		});
	});
	item.FindChildTraverse("CloseButton").SetPanelEvent("onactivate", function () {
		item.visible = false;
	});

	item.FindChildTraverse("Countdown").AddClass("Active");

	droppedItems[data.item] = item;

	$.Schedule(15, function () {
		item.RemoveClass("Slide");
		item.DeleteAsync(0.3);
	});
}

function NeutralItemTaked(data) {
	Game.EmitSound("Loot_Drop_Stinger_Short");

	if (droppedItems[data.item]) {
		droppedItems[data.item].RemoveClass("Slide");
		droppedItems[data.item].visible = false;
		droppedItems[data.item] = false;
	}

	let taked = $.CreatePanel("Panel", $("#ItemsContainer"), "");
	taked.BLoadLayoutSnippet("WhoTakedItem");
	taked.AddClass("Slide");
	taked.FindChildTraverse("ItemImage").itemname = Abilities.GetAbilityName(data.item);

	taked
		.FindChildTraverse("HeroImage")
		.SetImage(GetPortraitImage(data.player, Players.GetPlayerSelectedHero(data.player)));

	$.Schedule(5, function () {
		taked.RemoveClass("Slide");
		taked.DeleteAsync(0.3);
	});
}

GameEvents.Subscribe("neutral_item_taked", NeutralItemTaked);
GameEvents.Subscribe("neutral_item_dropped", NeutralItemDropped);
