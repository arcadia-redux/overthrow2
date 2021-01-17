const SUPP_NAMES = {
	1: "player_base_booster",
	2: "player_golden_booster",
};
const CONTEXT = $.GetContextPanel();
const HOVER_FUNC = {
	Treasure: (sourceValue) => {
		const sourceParentPanel = FindDotaHudElement("Item_" + sourceValue);
		CONTEXT.AddClass(sourceParentPanel.rarityName);
		$("#SourceName").text = $.Localize(sourceValue);
		$("#SourceImage").SetImage(sourceParentPanel.imagePath);
	},
	DOTAU_MMR: (sourceValue) => {
		CONTEXT.AddClass("RankOverlay");
		$("#SourceName").text = sourceValue;
		$("#SourceImage").SetImage("file://{images}/custom_game/collection/collection_trophy_source.png");
	},
	Coins: (sourceValue) => {
		CONTEXT.AddClass("GloryOverlay");
		$("#SourceName").text = sourceValue;
		$("#SourceImage").SetImage("file://{images}/custom_game/collection/collection_glory_source.png");
	},
	SupporterState: (sourceValue) => {
		CONTEXT.AddClass(SUPP_NAMES[sourceValue]);
		$("#SourceName").text = $.Localize(SUPP_NAMES[sourceValue]);
		$("#SourceImage").SetImage("file://{resources}/images/custom_game/payment/payment_boost.png");
	},
	Money: (sourceValue) => {
		CONTEXT.AddClass("GloryOverlay");
		$("#SourceName").text = $.Localize("#paySymbol") + GetLocalPrice(Math.round(sourceValue * 100) / 100);
		$("#SourceImage").SetImage("file://{resources}/images/custom_game/payment/payment_boost.png");
	},
	Other: (sourceValue) => {
		CONTEXT.AddClass("UniqueItem");
		$("#SourceName").text = $.Localize("#" + sourceValue);
		$("#SourceImage").SetImage(
			"file://{resources}/images/custom_game/collection/OtherSources/" + sourceValue + ".png",
		);
	},
};

function setTooltip() {
	const itemName = CONTEXT.GetAttributeString(`itemName`, undefined);
	const itemCategory = CONTEXT.GetAttributeString(`itemCategory`, undefined);
	const itemRariry = CONTEXT.GetAttributeString(`itemRariry`, undefined);
	const sourceName = CONTEXT.GetAttributeString(`sourceName`, undefined);
	const sourceValue = CONTEXT.GetAttributeString(`sourceValue`, undefined);
	let bShowSource = CONTEXT.GetAttributeString(`bShowSource`, undefined);
	bShowSource = (bShowSource || 1) == 1;
	const rarityColor = ITEMS_RARITY[itemRariry].color;
	$("#TooltipName").text = $.Localize(itemName);
	$("#CategoryText").text = $.Localize("#collection_item_category").replace(
		"##category_name##",
		$.Localize(itemCategory),
	);

	$("#RarityText").text = $.Localize("#collection_item_rarity").replace(
		"##rarity_name##",
		"<font color='" + rarityColor + "'>" + $.Localize(ITEMS_RARITY[itemRariry].name) + "</font>",
	);
	$("#TooltipName").style.backgroundColor =
		"gradient(linear, 0% 0%, 100% 0%, from(" + rarityColor + "33), to(transparent));";
	$("#RarityLabel").style.backgroundColor =
		" gradient(linear, 0% 0%, 100% 0%, from(transparent), color-stop(0.25, " +
		rarityColor +
		"), color-stop(0.75, " +
		rarityColor +
		"), to(transparent));";
	$("#MainInfo").style.backgroundColor =
		"gradient(linear, 0% 0%, 80% 250%, from(" + rarityColor + "26), to(transparent));";
	$("#SourceValue").text = $.Localize("#collection_item_source").replace(
		"##source_name##",
		$.Localize(sourceName + "_source"),
	);
	const itemDescription = itemName + "_description";
	const localizedDesc = $.Localize(itemDescription);
	if (itemDescription == localizedDesc) {
		$("#Description").text = $.Localize(itemCategory + "_description");
	} else {
		$("#Description").text = localizedDesc;
	}
	$("#SourceBorder").visible = bShowSource;
	$("#SourceName").visible = bShowSource;
	$("#SourceValueWrap").visible = bShowSource;
	if (!bShowSource) return;
	Object.values(ITEMS_RARITY).forEach((rarityData) => {
		CONTEXT.RemoveClass(rarityData.name);
	});
	Object.values(SUPP_NAMES).forEach((suppClassName) => {
		CONTEXT.RemoveClass(suppClassName);
	});
	CONTEXT.RemoveClass("RankOverlay");
	CONTEXT.RemoveClass("BoostOverlay");
	CONTEXT.RemoveClass("GloryOverlay");
	CONTEXT.RemoveClass("UniqueItem");

	HOVER_FUNC[sourceName](sourceValue);
}
