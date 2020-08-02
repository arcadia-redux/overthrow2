const BLACK_LIST_FOR_TOOLTIPS_ITEMS = ["item_bag_of_gold", "item_treasure_chest", "item_core_pumpkin"];
var hidingEvent = null;
var tooltipPanel = null;
function HideTooltip() {
	const itemImage = tooltipPanel.GetChild(1).GetChild(1).GetChild(0).GetChild(0).GetChild(0); //ID ItemImage
	if (itemImage && itemImage.itemname && BLACK_LIST_FOR_TOOLTIPS_ITEMS.indexOf(itemImage.itemname) > -1) {
		$.DispatchEvent("DOTAHideAbilityTooltip");
	}
}

function CheckAbilityTooltipPanel() {
	if (hidingEvent == null) {
		hidingEvent = HideTooltip;
		hidingEvent();
		$.Schedule(0.05, () => {
			hidingEvent = null;
		});
	}
}

function AddListenerForAbilityTooltip() {
	if (FindDotaHudElement("DOTAAbilityTooltip")) {
		tooltipPanel = FindDotaHudElement("DOTAAbilityTooltip");
		$.RegisterEventHandler("PanelStyleChanged", FindDotaHudElement("DOTAAbilityTooltip"), CheckAbilityTooltipPanel);
	} else {
		$.Schedule(1, () => {
			AddListenerForAbilityTooltip();
		});
	}
}
AddListenerForAbilityTooltip();
