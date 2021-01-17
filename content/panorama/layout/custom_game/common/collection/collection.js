let paymentKind = "noKind";
let equippedItems = [];
let itemByCoinsName;
let itemByCoinsCount = 0;
let playerCoins = 0;

let currentTreasure = "";
let wheelData = {};
let firstMoveSchelude;
let stopWheelSchelude;
let spinSound;
let spinEndSound;
let treasureGlowSchelude;

let currentSorting = "default";
let lastPreviewPanel = "";

const treasuresPreviewRoot = $("#TreasuresPreviewRoot");
const COLLECTION_DOTAU = $("#CollectionDotaU");

function OpenTreasurePreview(treasureName) {
	Game.EmitSound("ui.treasure_unlock.wav");
	const previewPanelName = "#TreasurePreview_" + treasureName;
	lastPreviewPanel = previewPanelName;
	const treasurePreviewPanel = $(previewPanelName);
	treasurePreviewPanel.SetHasClass("show", true);
	treasuresPreviewRoot.SetHasClass("show", true);
	const actionButtonInPreview = treasurePreviewPanel.FindChildTraverse("Preview_OpenTreasure");
	const treasureIsAvaileble = $("#Item_" + treasureName).BHasClass("Availeble");
	actionButtonInPreview.SetHasClass("PlayerIsHasTreasure", treasureIsAvaileble);
	actionButtonInPreview.GetChild(0).text = $.Localize(treasureIsAvaileble ? "#open_treasure" : "#buy_treasure");
	const itemsContainer = treasurePreviewPanel.FindChildTraverse("ItemsPreviewList");
	const items = itemsContainer.Children();
	for (const item of items.sort(SORT_FUNCTIONS["rarity_up"])) {
		itemsContainer.MoveChildBefore(item, itemsContainer.GetChild(0));
	}
}

const ACTIVATE_FUNCTUIONS = {
	Coins: AddItemToAccessCoins,
	Treasure: (data) => {
		OpenTreasurePreview(data.sourceValue);
	},
	SupporterState_1: () => {
		BuyBoost("base_booster");
	},
	SupporterState_2: () => {
		BuyBoost("golden_booster");
	},
	DOTAU_MMR: () => {
		Game.EmitSound("ui.contract_fail");
	},
	Money: (data) => {
		const itemPanel = $("#Item_" + data.itemName);
		if (itemPanel)
			_CreatePurchaseAccess(data.itemName, itemPanel.imagePath, data.itemName, data.itemName + "_description");
	},
};

const HOVER_FUNCTUIONS = {
	Coins: CheckCoinsPrice,
	Treasure: CheckTreasureInfo,
	SupporterState_1: TooltipNeedBaseBoost,
	SupporterState_2: TooltipNeedGoldBoost,
	Money: TooltipMoneyPrice,
};
function _ChangeItemEquipState(itemName, equipState) {
	if (COLLECTION_DOTAU.BHasClass("ItemActionCD")) return;
	COLLECTION_DOTAU.AddClass("ItemActionCD");
	$.Schedule(ITEM_CHANGE_EQUIP_STATE_COOLDOWN, () => {
		COLLECTION_DOTAU.RemoveClass("ItemActionCD");
	});
	Game.EmitSound(equipState ? "ui.inv_equip" : "ui.inv_unequip");
	GameEvents.SendCustomGameEventToServer(
		equipState ? "battlepass_inventory:equip_item" : "battlepass_inventory:take_off_item",
		{ itemName: itemName },
	);
}
const ITEM_BUTTON_FUNCTIONS = {
	[0]: function (itemName) {
		_ChangeItemEquipState(itemName, false);
	},
	[1]: function (itemName) {
		_ChangeItemEquipState(itemName, true);
	},
	[2]: function (itemName) {
		const previewPanelName = "#TreasurePreview_" + itemName;
		if (lastPreviewPanel == previewPanelName) {
			OpenTreasure(itemName);
		} else {
			OpenTreasurePreview(itemName);
		}
	},

	[3]: function (itemName) {},
};

function SetPaymentVisible(state) {
	$("#CollectionPayment").SetHasClass("show", state);
}

function ParseBigNumber(x) {
	return x ? x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",") : "0";
}

function ClickButton() {
	Game.EmitSound("General.ButtonClick");
}

function OpenTreasure(itemName) {
	ClickButton();
	currentTreasure = itemName;
	let count = 0;
	if ($("#Item_" + itemName).count) count = $("#Item_" + itemName).count;
	const treasuresLeftPanel = $("#TreasuresLeft");
	const playerIsHaveMoreTreasure = count - 1 > 0;
	treasuresLeftPanel.text = $.Localize("spin_treasures_left").replace("##tries##", count - 1);
	treasuresLeftPanel.visible = playerIsHaveMoreTreasure;
	$("#SpinAgain").SetHasClass("block", !playerIsHaveMoreTreasure);
	if (!count > 0) return;
	GameEvents.SendCustomGameEventToServer("battlepass_inventory:open_treasure", {
		treasureName: itemName,
	});
}

function SpinAgain() {
	ClickButton();
	ITEM_BUTTON_FUNCTIONS[2](currentTreasure);
}

function AddItemToAvailebleList(itemName, state, count) {
	const itemPanel = $("#Item_" + itemName);
	if (!itemPanel) return;
	itemPanel.RemoveClass(itemPanel.sourceClassName);
	itemPanel.AddClass("Availeble");
	Object.values(ITEMS_EQUIP_STATE).forEach((className) => {
		itemPanel.RemoveClass(className);
	});
	itemPanel.AddClass(ITEMS_EQUIP_STATE[state]);
	const itemButton = itemPanel.FindChildTraverse("ItemActionButton");
	itemButton.FindChild("ItemButtonText").text = $.Localize("#" + ITEMS_EQUIP_STATE[state]);
	itemButton.ClearPanelEvent("onactivate");
	itemButton.SetPanelEvent("onactivate", () => {
		ITEM_BUTTON_FUNCTIONS[state](itemName);
	});
	if (count != undefined) {
		const itemCountText = itemPanel.FindChildTraverse("ItemCount");
		itemCountText.text = count;
		itemCountText.visible = itemPanel.category == "Treasures";
	}
	itemPanel.count = count;
	if (itemPanel.season) itemPanel.visible = true;
	itemPanel.FindChildTraverse("ItemActionButton").style.washColor = null;
	const itemPreviewPanel = $("#ItemPreview_" + itemName);
	if (!itemPreviewPanel) return;
	itemPreviewPanel.RemoveClass("BW");
}

function SetItemToNotAvailebleList(itemName) {
	const item = $("#Item_" + itemName);
	if (!item) return;
	Object.values(ITEMS_EQUIP_STATE).forEach((className) => {
		item.RemoveClass(className);
	});
	item.RemoveClass("Availeble");
	let sourceName = item.sourceName;
	let sourceClassName = sourceName;
	let sourceValue = item.sourceValue;
	if (item.season) item.visible = false;
	const itemButtonText = item.FindChildTraverse("ItemButtonText");
	itemButtonText.text = $.Localize("#" + sourceName);

	if (TOOLTIPS_WITH_VALUES[sourceName]) {
		itemButtonText.text =
			sourceValue > 0
				? itemButtonText.text.replace(
						"##" + TOOLTIPS_WITH_VALUES[sourceName] + "##",
						Math.round(sourceValue * 100) / 100,
				  )
				: "#free_item";
	} else if (sourceName == "SupporterState") {
		itemButtonText.text = $.Localize("#" + sourceName + "_" + sourceValue);
		sourceClassName += "_" + sourceValue;
	} else if (sourceName == "Treasure") {
		const addOverlay = () => {
			if ($("#Item_" + sourceValue)) {
				item.FindChildTraverse("ItemActionButton").style.washColor = item.BHasClass("Availeble")
					? null
					: ITEMS_RARITY[$("#Item_" + sourceValue).rarity].color + "A6";
			} else {
				$.Schedule(1, addOverlay);
			}
		};
		addOverlay();
	}
	const actionButton = itemButtonText.GetParent();
	actionButton.ClearPanelEvent("onactivate");
	actionButton.ClearPanelEvent("onmouseover");

	if (HOVER_FUNCTUIONS[sourceClassName]) {
		actionButton.SetPanelEvent("onmouseover", () => {
			HOVER_FUNCTUIONS[sourceClassName]({
				cost: sourceValue,
				panel: actionButton,
				sourceValue: item.sourceValue,
			});
		});
		actionButton.SetPanelEvent("onmouseout", () => {
			$.DispatchEvent("DOTAHideTextTooltip");
		});
	}

	if (ACTIVATE_FUNCTUIONS[sourceClassName]) {
		actionButton.SetPanelEvent("onactivate", () => {
			ACTIVATE_FUNCTUIONS[sourceClassName]({
				sourceValue: sourceValue,
				itemName: itemName,
				rarity: item.rarityName,
				category: item.category,
			});
		});
	}

	if (item.blocked) {
		actionButton.ClearPanelEvent("onactivate");
		actionButton.ClearPanelEvent("onmouseover");
		itemButtonText.text = $.Localize("#coming_soon");
		item.visible = false;
	}

	item.sourceClassName = sourceClassName;
	item.AddClass(sourceClassName);

	const itemCountText = item.FindChildTraverse("ItemCount");
	itemCountText.text = 0;
	itemCountText.visible = item.category == "Treasures";
}

function UpdateEquippedItems(data) {
	equippedItems.forEach((itemName) => {
		AddItemToAvailebleList(itemName, EQUIP);
	});
	Object.entries(data).forEach(([categoryName, data]) => {
		if (categoryName.indexOf("equipped")) return;
		Object.values(data).forEach((itemName) => {
			equippedItems.push(itemName);
			AddItemToAvailebleList(itemName, EQUIPPED);
		});
	});
}

function UpdatePlayerItems(data) {
	let itemsCount = {};
	Object.values(data).forEach((itemData) => {
		itemsCount[itemData.itemName] = itemData.count;
	});

	$("#ItemsList")
		.Children()
		.forEach((panel, index) => {
			const tabPanel = $("#ItemsTypesList").GetChild(index);
			tabPanel.SetHasClass("IsHasAvailbleItems", index < 2);
			const itemParent = panel.FindChildTraverse("Items");
			const items = itemParent.Children();
			for (const item of items) {
				const itemCount = itemsCount[item.itemName];
				if (itemCount && itemCount > 0) {
					let state = 0;
					if (item.noAction) {
						state = ITEM_OWNED;
					} else if (item.category == "Treasures") {
						state = OPEN_TREASURE;
					} else {
						state = item.BHasClass("equipped") ? EQUIPPED : EQUIP;
					}
					AddItemToAvailebleList(item.itemName, state, itemCount);
					tabPanel.SetHasClass("IsHasAvailbleItems", true);
				} else if (item.BHasClass("Availeble")) {
					SetItemToNotAvailebleList(item.itemName);
				}
			}
		});
	SortingItems(currentSorting);
}

function UpdatePlayerInfo(data) {
	const playerBooster = $("#PlayerStatusBooster");
	playerBooster.text = $.Localize("player_" + PLAYER_BOOST_STATE[data.boosterStatus]);
	Object.values(PLAYER_BOOST_STATE).forEach((className) => {
		playerBooster.RemoveClass(className);
	});
	playerBooster.AddClass(PLAYER_BOOST_STATE[data.boosterStatus]);
	const playerProgressText = $("#DotaUBP_LevelProgress");
	playerProgressText.SetDialogVariable("curr_exp", data.playerCurrExp);
	playerProgressText.SetDialogVariable("max_exp", data.playerNeedExp);
	$("#BPProgressBar").value = data.playerCurrExp / data.playerNeedExp;
	$("#DotaUBP_PlayerLevel").text = data.playerLevel;
	UpdateCoins({ coins: data.coins });
	if (data.boosterStatus == 0) {
		ShowBoostInfo("BaseBoost");
	} else {
		ShowBoostInfo("GoldBoost");
	}
	$("#BuyBoost_base_booster").SetHasClass("block", data.boosterStatus == 2);
	if (data.blockRepeatPurchase) {
		if (data.boosterStatus == 1) {
			$("#BuyBoost_base_booster").AddClass("block");
		} else if (data.boosterStatus == 2) {
			$("#BuyBoost_base_booster").AddClass("block");
			$("#BuyBoost_golden_booster").AddClass("block");
		}
	}
	if (data.boosterEndDate == undefined) data.boosterEndDate = 0;
	const donateTimeLeft = (new Date(data.boosterEndDate) - new Date()) / 864e5;

	const setTimeLeft = function (format) {
		const setTimeText = function (text) {
			$("#BoostTimeLeft_1").SetDialogVariable("time_left", text);
			$("#BoostTimeLeft_2").SetDialogVariable("time_left", text);
		};
		setTimeText(
			$.Localize("boost_time_left_day").replace(
				"##time##",
				Math.floor(donateTimeLeft * TIMES_MULTIPLAYER[format]).toString(),
			),
		);
	};
	Object.entries(TIMES_MULTIPLAYER).forEach(([format, multiplayer]) => {
		if (donateTimeLeft > 1 / multiplayer) {
			setTimeLeft(format);
		}
	});
	$("#BoostTimeLeftRoot_1").visible = data.boosterStatus == 1 && donateTimeLeft > 0;
	$("#BoostTimeLeftRoot_2").visible = data.boosterStatus == 2 && donateTimeLeft > 0;
}

function ShowBoostInfo(boostName) {
	Game.EmitSound("ui.inv_pickup_highvalue");
	$("#BoostersInfoWrap")
		.Children()
		.forEach((panel) => {
			panel.SetHasClass("Show", false);
		});
	$("#BoostersHeader")
		.Children()
		.forEach((panel) => {
			panel.SetHasClass("Active", false);
		});
	$("#" + boostName + "Panel").SetHasClass("Show", true);
	$("#" + boostName).SetHasClass("Active", true);
}

function _CreatePurchaseAccess(name, imagePath, headerKey, descKey, price) {
	$("#PatreonPaymentButton").visible = name == "base_booster" || name == "golden_booster";
	$("#PurchasingHeader").text = $.Localize("#" + headerKey);
	$("#PurchasingDescription").text = $.Localize("#" + descKey);
	let priceValue = 0;
	let newPayment = name;
	if (PAYMENT_VALUES[name]) {
		if (PAYMENT_VALUES[name].price) priceValue = PAYMENT_VALUES[name].price;
	} else if ($("#Item_" + name) != undefined) {
		newPayment = "purchase_" + name;
		priceValue = Math.round($("#Item_" + name).sourceValue * 100) / 100;
	}
	paymentKind = newPayment;
	if (price) priceValue = price;
	$("#Price").SetDialogVariable("price", GetLocalPrice(priceValue));
	$("#Price").SetDialogVariable("paySymbol", $.Localize("#paySymbol"));
	$("#PurchasingIcon").SetImage(imagePath);
	SetPaymentVisible(true);
}

function BuyBoost(type) {
	if ($("#BuyBoost_" + type).BHasClass("block")) return;
	ClickButton();
	_CreatePurchaseAccess(
		type,
		"file://{resources}/images/custom_game/payment/payment_boost.png",
		type + "_purchase_header",
		type + "_purchase_description",
	);
}

function SortingItems(sortName) {
	currentSorting = sortName;
	Game.EmitSound("ui.inv_sort");
	$.DispatchEvent("DropInputFocus", $("#SortingOptions"));
	$("#SortingOptions").SetSelected("collection_sort_" + sortName);

	$("#ItemsList")
		.Children()
		.forEach((panel) => {
			const itemParent = panel.FindChildTraverse("Items");
			const items = itemParent.Children();
			for (const item of items.sort(SORT_FUNCTIONS[sortName])) {
				itemParent.MoveChildBefore(item, itemParent.GetChild(0));
			}
		});
}

function InitCollection(_data) {
	const itemsTypesParentParent = $("#ItemsTypesList");
	const itemsListParent = $("#ItemsList");
	itemsTypesParentParent.RemoveAndDeleteChildren();
	itemsListParent.RemoveAndDeleteChildren();
	treasuresPreviewRoot.RemoveAndDeleteChildren();

	ITEMS_TYPES.forEach((itemTypeName) => {
		const itemTypePanel = $.CreatePanel("Panel", itemsTypesParentParent, "ItemType_" + itemTypeName);
		itemTypePanel.BLoadLayoutSnippet("ItemType");
		itemTypePanel.GetChild(0).text = $.Localize("#" + itemTypeName);
		itemTypePanel.SetPanelEvent("onactivate", function () {
			Game.EmitSound("Item.DropRecipeShop");
			SelectItemType(itemTypeName);
		});
		const itemsListWrap = $.CreatePanel("Panel", itemsListParent, "ItemsList_" + itemTypeName);
		itemsListWrap.BLoadLayoutSnippet("ItemsListType");
		itemsListWrap.FindChildTraverse("Items").RemoveAndDeleteChildren();
	});

	CreateMasteriesTab(_data.masteries);

	const createItems = function (data, isTreasureType) {
		Object.entries(data).forEach(([itemName, itemData]) => {
			const categoryName = ITEMS_TYPES[itemData.Category];
			const rarityName = ITEMS_RARITY[itemData.Rarity].name;
			const itemsListWrap = $("#ItemsList_" + categoryName);
			const itemsList = itemsListWrap.FindChildTraverse("Items");
			const item = $.CreatePanel("Panel", itemsList, "Item_" + itemName);
			item.BLoadLayoutSnippet("ItemDotaU");
			const sourceName = Object.entries(itemData.Source)[0][0];
			const sourceValue = Object.entries(itemData.Source)[0][1];
			item.AddClass(rarityName);
			const isItemTreasure = ITEMS_TYPES[itemData.Category] == "Treasures";
			item.SetHasClass("IsTreasure", isItemTreasure);
			itemsListWrap.FindChildTraverse("ItemNone").visible = false;

			item.sourceName = sourceName;
			item.category = categoryName;
			item.sourceValue = sourceValue;
			item.itemName = itemName;
			item.rarity = itemData.Rarity;
			item.rarityName = rarityName;
			item.imagePath = "file://{images}/custom_game/collection/" + categoryName + "/" + itemName + ".png";
			if (itemData.NoAction) {
				item.noAction = true;
			}

			item.FindChildTraverse("ItemEquippedState").style.washColor = ITEMS_RARITY[itemData.Rarity].color;
			if (categoryName == "Treasures") {
				const itemNamePanel = item.FindChildTraverse("ItemName");
				itemNamePanel.text = $.Localize(itemName);
				itemNamePanel.visible = true;
			} else if (categoryName == "Barrages") {
				item.FindChildTraverse("TextContentRoot").AddClass(itemName);
				item.imagePath = "file://{images}/custom_game/collection/Barrages/barrages_bg.png";
			}
			const itemImagePanel = item.FindChildTraverse("ItemImage");
			itemImagePanel.SetImage(item.imagePath);

			if (isItemTreasure)
				item.FindChildTraverse("TreasureShowInfo").SetPanelEvent("onactivate", () => {
					OpenTreasurePreview(itemName);
				});

			const createItemTooltip = (panel, bShowSource) => {
				let params =
					`itemName=` +
					itemName +
					"&itemCategory=" +
					categoryName +
					"&itemRariry=" +
					itemData.Rarity +
					"&sourceName=" +
					sourceName +
					"&sourceValue=" +
					sourceValue +
					"&bShowSource=" +
					bShowSource;
				panel.SetPanelEvent("onmouseover", () => {
					$.DispatchEvent(
						"UIShowCustomLayoutParametersTooltip",
						panel,
						"DotaUItemTooltip",

						"file://{resources}/layout/custom_game/common/collection/collection_item_tooltip/collection_item_tooltip.xml",
						params,
					);
					if (item.BHasClass("NewItemGlow")) {
						UpdateNewItemsNotificationByCategory(categoryName, -1);
						item.RemoveClass("NewItemGlow");
					}
				});

				panel.SetPanelEvent("onmouseout", () => {
					$.DispatchEvent("UIHideCustomLayoutTooltip", panel, "DotaUItemTooltip");
				});
			};
			if (itemData.Blocked) {
				item.blocked = true;
			} else {
				createItemTooltip(itemImagePanel, 1);
			}
			if (itemData.HideInCollection) {
				item.visible = false;
				item.hideInCollection = true;
			}
			if (itemData.Season) {
				item.visible = false;
				item.season = true;
			}
			SetItemToNotAvailebleList(itemName);

			let defaultSortWeight =
				Math.abs(itemData.Rarity - 99) + SOURCES_WEIGHT.indexOf(item.sourceClassName) * 1000;
			if (item.sourceClassName == "Treasure" && TREASURES_WEIGHT.indexOf(sourceValue) > -1) {
				defaultSortWeight += TREASURES_WEIGHT.indexOf(sourceValue) * 100;
			}
			if (itemData.Category == 1 && itemData.Blocked == undefined && TREASURES_WEIGHT.indexOf(itemName) > -1) {
				defaultSortWeight += TREASURES_WEIGHT.indexOf(itemName) * 100;
			}
			item.default = defaultSortWeight;

			if (isTreasureType) {
				const previewPanel = $.CreatePanel("Panel", treasuresPreviewRoot, "TreasurePreview_" + itemName);
				previewPanel.BLoadLayoutSnippet("TreasuresPreviewWrap");
				previewPanel
					.FindChildTraverse("PreviewParticleRoot")
					.BCreateChildren(
						'<DOTAScenePanel style="width:100%;height:100%;" camera="camera_' +
							rarityName +
							'" particleonly="false" map="collection/spin_glow" hittest="false"/>',
					);
				previewPanel.FindChildTraverse("TreasureName").text = $.Localize("#treasure_preview_header")
					.replace("##treasure##", $.Localize(itemName))
					.toUpperCase();
				previewPanel.FindChildTraverse("TreasureImagePreview").SetImage(item.imagePath);
				const openTreasureButton = previewPanel.FindChildTraverse("Preview_OpenTreasure");
				const cancelTreasureButton = previewPanel.FindChildTraverse("Preview_Cancel");

				openTreasureButton.SetPanelEvent("onactivate", () => {
					previewPanel.SetHasClass("show", false);
					treasuresPreviewRoot.SetHasClass("show", false);
					if (item.BHasClass("Availeble")) {
						OpenTreasure(itemName);
					} else {
						if (sourceValue > playerCoins) {
							SelectItemType("Treasures");
							StopSchelude(treasureGlowSchelude);
							item.AddClass("TreasureGlow");
							treasureGlowSchelude = $.Schedule(3.5, () => {
								treasureGlowSchelude = undefined;
								$("#ItemsList_Treasures")
									.FindChild("Items")
									.Children()
									.forEach((treasureItem) => {
										treasureItem.RemoveClass("TreasureGlow");
									});
							});
						} else {
							ACTIVATE_FUNCTUIONS[sourceName]({
								sourceValue: sourceValue,
								itemName: itemName,
								rarity: rarityName,
								category: categoryName,
							});
						}
					}
				});
				cancelTreasureButton.SetPanelEvent("onactivate", () => {
					previewPanel.SetHasClass("show", false);
					treasuresPreviewRoot.SetHasClass("show", false);
					lastPreviewPanel = "";
				});
			} else if (sourceName == "Treasure" && itemData.Blocked == undefined) {
				const itemInPreview = $.CreatePanel(
					"Panel",
					$("#TreasurePreview_" + sourceValue).FindChildTraverse("ItemsPreviewList"),
					"ItemPreview_" + itemName,
				);
				itemInPreview.AddClass("BW");
				itemInPreview.BLoadLayoutSnippet("ItemDotaU");
				const itemImagePreview = itemInPreview.FindChildTraverse("ItemImage");
				itemImagePreview.SetImage(item.imagePath);
				itemInPreview.FindChildTraverse("ItemActionButton").visible = false;
				itemInPreview.AddClass(rarityName);
				if (categoryName == "Barrages") {
					const textContent = itemInPreview.FindChildTraverse("TextContentRoot");
					textContent.style.opacity = 1;
					textContent.AddClass(itemName);
					itemInPreview.imagePath = "file://{images}/custom_game/collection/Barrages/barrages_bg.png";
				}
				itemInPreview.rarity = itemData.Rarity;
				createItemTooltip(itemImagePreview, 0);
			}

			if (itemData.OverrideCategoty) {
				const newRootPanel = $("#ItemsList_" + ITEMS_TYPES[itemData.OverrideCategoty]);
				if (newRootPanel != undefined) {
					item.SetParent(newRootPanel.FindChildTraverse("Items"));
				}
			}
		});
	};
	createItems(_data.treasures, true);
	createItems(_data.items, false);
	SelectItemType("Treasures");
	FindDotaHudElement("CollectionTopButton").visible = true;
}

function ClearChildredFromClass(parentName, className) {
	$(parentName)
		.Children()
		.forEach((panel) => {
			panel.SetHasClass(className, false);
		});
}

function SelectItemType(itemType) {
	ClearChildredFromClass("#ItemsTypesList", "Selected");
	ClearChildredFromClass("#ItemsList", "Show");

	$("#ItemType_" + itemType).SetHasClass("Selected", true);
	$("#ItemsList_" + itemType).SetHasClass("Show", true);
	$("#ItemsList").SetHasClass("FirstType", itemType == "Treasures");
}

function CloseCollectionDotaU() {
	Game.EmitSound("ui_friends_slide_in");
	COLLECTION_DOTAU.SetHasClass("show", false);
}

function CancelPurchaseCoins() {
	ClickButton();
	itemByCoinsCount = 0;
	$("#PurchaseAccessCoins").SetHasClass("show", false);
}

function SuccessPurchaseCoins() {
	Game.EmitSound("Quickbuy.Confirmation");
	$("#PurchaseAccessCoins").SetHasClass("show", false);
	GameEvents.SendCustomGameEventToServer("battlepass_inventory:buy_item_by_coins", {
		itemName: itemByCoinsName,
		count: itemByCoinsCount,
	});
	itemByCoinsCount = 0;
}

function ChangeItemsCount(count) {
	$.DispatchEvent("DOTAHideTextTooltip");
	const changeSide = count > 0;
	count = count + itemByCoinsCount;
	const parentPanel = $("#PurchaseAccessCoins");
	const isFreeTreasure = itemByCoinsName == "gift_free_treasure";
	const maxItems = isFreeTreasure ? 1 : Math.floor(playerCoins / parentPanel.itemCostByOne);
	count = Math.max(Math.min(maxItems, count), 1);
	const cost = Math.min(parentPanel.itemCostByOne * count, playerCoins);

	parentPanel.FindChildTraverse("PlayerCoins").text = ParseBigNumber(cost);
	parentPanel.FindChildTraverse("ItemsCount").text = count;

	const isMinItems = itemByCoinsCount > 1 || count > 1;
	if ((itemByCoinsCount != maxItems || count != maxItems) && isMinItems) {
		ClickButton();
	}
	const incrementItemsButton = $("#ChangeItemsCount_Inc");
	const decrementItemsButton = $("#ChangeItemsCount_Dec");

	incrementItemsButton.SetHasClass("BW", count == maxItems);
	decrementItemsButton.SetHasClass("BW", count == 1);

	const incEvent = function () {
		if (!isFreeTreasure)
			$.DispatchEvent(
				"DOTAShowTextTooltip",
				incrementItemsButton,
				$.Localize(
					itemByCoinsCount != maxItems || count != maxItems
						? "#item_increment_1"
						: "#not_enough_glory_for_extra_item",
				),
			);
	};
	const decEvent = function () {
		if (itemByCoinsCount > 1 || count > 1)
			$.DispatchEvent("DOTAShowTextTooltip", decrementItemsButton, $.Localize("#item_decrement_1"));
	};
	incrementItemsButton.SetPanelEvent("onmouseover", incEvent);
	decrementItemsButton.SetPanelEvent("onmouseover", decEvent);
	itemByCoinsCount = count;
	if (changeSide && isMinItems) {
		incEvent();
	} else {
		decEvent();
	}
}

function AddItemToAccessCoins(data) {
	const isPlayerHaveEnoughCoins = data.sourceValue <= playerCoins;
	Game.EmitSound(ITEMS_BUY_COINS_SOUNDS[isPlayerHaveEnoughCoins]);
	if (!isPlayerHaveEnoughCoins) return;
	const decrementItemsButton = $("#ChangeItemsCount_Dec");

	$("#PurchaseAccessCoins").SetHasClass("show", true);
	decrementItemsButton.SetHasClass("BW", true);
	itemByCoinsName = data.itemName;
	const parentPanel = $("#PurchaseAccessCoins");
	parentPanel.itemCostByOne = data.sourceValue;
	parentPanel.FindChild("Item").RemoveAndDeleteChildren();
	const item = $.CreatePanel("Panel", parentPanel.FindChild("Item"), "");
	item.BLoadLayoutSnippet("ItemDotaU");
	item.FindChild("ItemActionButton").visible = false;
	item.AddClass(data.rarity);
	if ($("#Item_" + data.itemName))
		item.FindChildTraverse("ItemImage").SetImage($("#Item_" + data.itemName).imagePath);
	parentPanel.FindChildTraverse("СountButtons").visible = data.category == "Treasures";
	ChangeItemsCount(1);
}

function CheckCoinsPrice(data) {
	if (data.cost <= playerCoins) return;
	if (data.panel.GetParent().BHasClass("Availeble")) return;
	$.DispatchEvent("DOTAShowTextTooltip", data.panel, $.Localize("#not_enough_coins"));
}

function CheckTreasureInfo(data) {
	if (data.panel.GetParent().BHasClass("Availeble")) return;
	$.DispatchEvent(
		"DOTAShowTextTooltip",
		data.panel,
		$.Localize("#item_in_treasure").replace("##treasure_name##", $.Localize("#" + data.sourceValue)),
	);
}

function TooltipNeedBaseBoost(data) {
	if (data.panel.GetParent().BHasClass("Availeble")) return;
	$.DispatchEvent("DOTAShowTextTooltip", data.panel, $.Localize("#need_buy_base_booster"));
}

function TooltipNeedGoldBoost(data) {
	if (data.panel.GetParent().BHasClass("Availeble")) return;
	$.DispatchEvent("DOTAShowTextTooltip", data.panel, $.Localize("#need_buy_golden_booster"));
}
function TooltipMoneyPrice(data) {
	if (data.panel.GetParent().BHasClass("Availeble")) return;
	$.DispatchEvent(
		"DOTAShowTextTooltip",
		data.panel,
		$.Localize("#item_for_money").replace("##cost##", Math.round(data.cost * 100) / 100),
	);
}

function UpdateCoins(data) {
	playerCoins = data.coins;
	$("#PlayerCoins").text = ParseBigNumber(data.coins);

	$("#ItemsList")
		.Children()
		.forEach((panel) => {
			const itemParent = panel.FindChildTraverse("Items");
			const items = itemParent.Children();
			items.forEach((item) => {
				if (item.sourceName == "Coins") item.SetHasClass("AccessToBuyCoins", item.sourceValue <= playerCoins);
			});
		});
}

function SetItemInWheel(panel, itemName, isPrize) {
	panel.BLoadLayoutSnippet("ItemDotaU");
	panel.FindChildTraverse("ItemActionButton").visible = false;
	const baseItemPanel = $("#Item_" + itemName);
	panel.FindChildTraverse("ItemImage").SetImage(baseItemPanel.imagePath);
	const textContent = panel.FindChildTraverse("TextContentRoot");
	if (baseItemPanel.category == "Barrages") {
		textContent.RemoveClass(panel.oldBarrageClass);
		textContent.style.opacity = 1;
		textContent.AddClass(itemName);
		panel.oldBarrageClass = itemName;
	} else {
		textContent.style.opacity = 0;
	}

	panel.RemoveClass(panel.oldClass);

	const rarityClass = baseItemPanel.rarityName;
	panel.oldClass = rarityClass;
	panel.AddClass("InWheel");
	panel.AddClass(rarityClass);
	panel.SetHasClass("PrizeItem", isPrize);
}

function SkipSpin() {
	wheelData.skipAnimation = true;
	SetWheelAnimation(false);
	ShowWheel(wheelData);
	StopWheel();
	SetItemInWheel($("#TreasuresWheel").GetChild(3), wheelData.itemPrize, true);
}

function SetPanelsVisibilityByWheelActive(bool) {
	$("#SkipSpin").SetHasClass("show", bool);
	$("#InfoAboutPrize").SetHasClass("show", !bool);
	$("#TreasuresWheel").SetHasClass("BW", !bool);
}

function ShowWheel(data) {
	SetPanelsVisibilityByWheelActive(true);
	wheelData = data;
	const wheelPanel = $("#TreasuresWheel");
	$("#TreasuresWheelWrap").GetParent().SetHasClass("show", true);
	wheelPanel.RemoveClass("wheel");
	wheelPanel.style.paddingLeft = "-5px";
	wheelPanel.RemoveAndDeleteChildren();
	SetItemInWheel($("#ChestIcon"), currentTreasure, false);
	for (let i = 1; i < ITEMS_IN_WHEEL_INIT; i++) {
		let counter = i;
		while (!data.itemPool[counter]) {
			counter = counter - Object.keys(data.itemPool).length;
		}
		const itemName = data.itemPool[counter];
		const item = $.CreatePanel("Panel", wheelPanel, "");
		SetItemInWheel(item, itemName, false);
	}
	if (!data.skipAnimation) StartWheel(data.itemPrize, data.itemPool, data.glory);
}

function SetWheelAnimation(bool) {
	$("#SpinArrow").SetHasClass("spin", bool);
	$("#ParticleArrow").SetHasClass("show", bool);
}

function SetVisiblePrizeParticle(bool) {
	$("#ParticlePrize").SetHasClass("show", bool);
}

function StopSchelude(schelude) {
	if (schelude != null) {
		$.CancelScheduled(schelude);
	}
}

function UpdateNewItemsNotificationByCategory(category, value) {
	const newItemsCountInTab = $("#ItemType_" + category).GetChild(1);
	const oldItemsCount = parseInt(newItemsCountInTab.text);
	if (oldItemsCount != undefined) {
		const newCount = oldItemsCount + value;
		newItemsCountInTab.text = newCount;
		newItemsCountInTab.SetHasClass("show", newCount > 0);
	}
}

function StopWheel() {
	Game.StopSound(spinSound);
	SetWheelAnimation(false);
	SetPanelsVisibilityByWheelActive(false);

	const gloryForDuplicate = wheelData.glory;
	const particleParent = $("#WheelParticle");
	particleParent.RemoveAndDeleteChildren();

	const itemPrizeName = wheelData.itemPrize;

	$("#ItemRecived").text = $.Localize(itemPrizeName);
	const isItemDuplicate = gloryForDuplicate > 0;
	$("#DoubleGloryInfoWrap").SetHasClass("show", isItemDuplicate);
	SetVisiblePrizeParticle(!isItemDuplicate);

	const parentItemPanel = $("#Item_" + itemPrizeName);
	let soundName = ITEMS_RARITY[$("#Item_" + itemPrizeName).rarity].sound;
	if (isItemDuplicate) {
		soundName = SOUND_DUPLICATE_ITEM;
		$("#DoubleGloryValue").text = gloryForDuplicate;
	} else {
		const particle = $.CreatePanel("Panel", particleParent, "");
		particle.BLoadLayoutSnippet("WheelWinParticle");

		if (parentItemPanel.hideInCollection == undefined) {
			parentItemPanel.AddClass("NewItemGlow");
			UpdateNewItemsNotificationByCategory(parentItemPanel.category, 1);
		}
	}
	spinEndSound = Game.EmitSound(soundName);
	StopSchelude(firstMoveSchelude);
	StopSchelude(stopWheelSchelude);
}

function StartWheel(prizeItemName, itemData) {
	spinSound = Game.EmitSound("ui.treasure.spin_music");
	if (spinEndSound) Game.StopSound(spinEndSound);
	SetWheelAnimation(true);
	SetVisiblePrizeParticle(false);

	const wheelPanel = $("#TreasuresWheel");
	wheelPanel.AddClass("wheel");
	const animationTime = 5;
	const parentWidth = 148;
	let wheelTimeStep = parentWidth / (3705 / animationTime);

	const itemLength = Object.keys(itemData).length;
	const maxCount = Math.floor(animationTime / wheelTimeStep);
	const prizeCount = maxCount - 5;
	wheelTimeStep -= 0.04; //manually fix

	const callbackWithWheelCheck = function (callback) {
		if (wheelPanel.BHasClass("wheel")) {
			callback();
		}
	};

	let count = 0;
	const move = function () {
		if (count < maxCount - 2) {
			$.Schedule(wheelTimeStep, () => {
				callbackWithWheelCheck(() => {
					wheelPanel.style.paddingLeft = ++count * parentWidth + "px";
					const movedChild = wheelPanel.GetChild(0);
					const isItemPrize = count == prizeCount;
					const itemName = isItemPrize ? prizeItemName : itemData[Math.ceil(Math.random() * itemLength)];
					SetItemInWheel(movedChild, itemName, isItemPrize);
					wheelPanel.MoveChildAfter(movedChild, wheelPanel.GetChild(wheelPanel.Children().length - 1));
					move();
				});
			});
		}
	};

	firstMoveSchelude = $.Schedule(0.7, () => {
		firstMoveSchelude = undefined;
		callbackWithWheelCheck(() => {
			move();
		});
	});

	stopWheelSchelude = $.Schedule(animationTime, () => {
		stopWheelSchelude = undefined;
		callbackWithWheelCheck(() => {
			StopWheel();
		});
	});
}

function CloseWheelDotaU() {
	ClickButton();
	SetPanelsVisibilityByWheelActive(true);
	$("#TreasuresWheelWrap").GetParent().SetHasClass("show", false);
	$("#DoubleGloryInfoWrap").SetHasClass("show", false);
	lastPreviewPanel = "";
}

function _OnlyOwnedItemsFilter(state) {
	$("#ItemsList").SetHasClass("OnlyOwned", state);
	$("#ItemsTypesList").SetHasClass("OnlyOwned", state);
}

function ShowOnlyOwnedItems() {
	Game.EmitSound("ui.inv_sort");
	const state = $("#OnlyOwnedItems").IsSelected();
	_OnlyOwnedItemsFilter(state);

	GameEvents.SendCustomGameEventToServer("battlepass_inventory:save_only_equipped_items", {
		state: state,
	});
}

function SettingsFromSaved(data) {
	let boolState = false;
	if (data.only_owned_items != undefined) {
		boolState = data.only_owned_items == 1;
	}
	$("#OnlyOwnedItems").SetSelected(boolState);
	_OnlyOwnedItemsFilter(boolState);
	const hideFreeTreasure = () => {
		const freeTreasure = $("#Item_gift_free_treasure");
		if (freeTreasure != undefined) {
			freeTreasure.visible = false;
		} else {
			$.Schedule(0.1, hideFreeTreasure);
		}
	};
	if (data.got_free_treasure != undefined) hideFreeTreasure();
}

function OpenSpecificCollection(data) {
	boostGlow = false;
	if (data.boostGlow) {
		boostGlow = data.boostGlow;
	}
	ToggleMenu("CollectionDotaU");
	SelectItemType(data.category);
}

function SelectSprays() {
	COLLECTION_DOTAU.SetHasClass("show", true);
	SelectItemType("Sprays");
}

(function () {
	GameEvents.SendCustomGameEventToServer("battlepass_inventory:get_collection", {});
	GameEvents.Subscribe("battlepass_inventory:init_collection", InitCollection);
	GameEvents.Subscribe("battlepass_inventory:update_player_info", UpdatePlayerInfo);
	GameEvents.Subscribe("battlepass_inventory:update_player_items", UpdatePlayerItems);
	GameEvents.Subscribe("battlepass_inventory:update_equipped_items", UpdateEquippedItems);
	GameEvents.Subscribe("battlepass_inventory:update_coins", UpdateCoins);
	GameEvents.Subscribe("battlepass_inventory:show_wheel", ShowWheel);
	GameEvents.Subscribe("battlepass_inventory:select_sprays", SelectSprays);
	GameEvents.Subscribe("battlepass_inventory:open_specific_collection", OpenSpecificCollection);
	SubscribeToNetTableKey("player_settings", Game.GetLocalPlayerID().toString(), SettingsFromSaved);
	COLLECTION_DOTAU.AddClass(MAP_NAME);
})();
