const GLORY_OFFERS = {
	100: {
		price: 0.99,
		fortune: 2,
	},
	550: {
		price: 4.99,
		bonus: 10,
		fortune: 12,
	},
	1150: {
		price: 9.99,
		bonus: 15,
		popular: true,
		fortune: 25,
	},
	3000: {
		price: 24.99,
		bonus: 20,
		fortune: 70,
	},
	6500: {
		price: 49.99,
		bonus: 30,
		fortune: 150,
	},
	15000: {
		price: 99.99,
		bonus: 50,
		fortune: 330,
	},
};
const gloryOffersRoot = $("#GloryOffersRoot");
const gloryShop = $("#GloryShopRoot");
function CloseGloryShop() {
	gloryShop.SetHasClass("show", false);
}
function OpenGloryShop() {
	gloryShop.SetHasClass("show", true);
}
function BuyGlory() {}
(function () {
	gloryOffersRoot.RemoveAndDeleteChildren();
	const isNoFortuneShop = MAP_NAME == "dota" || MAP_NAME == "dota_tournament";

	Object.entries(GLORY_OFFERS).forEach(([value, data]) => {
		const offerPanel = $.CreatePanel("Panel", gloryOffersRoot, "");
		offerPanel.BLoadLayoutSnippet("GloryOffer");
		offerPanel.FindChildTraverse("GloryOfferHeaderText_Glory").text = value;
		offerPanel.FindChildTraverse("GloryOfferHeaderText_Fortune").text = data.fortune;
		offerPanel.FindChildTraverse("GloryOfferPrice").SetDialogVariable("price", GetLocalPrice(data.price));
		offerPanel.FindChildTraverse("GloryOfferPrice").SetDialogVariable("paySymbol", $.Localize("#paySymbol"));
		offerPanel.FindChildTraverse("Popular").visible = data.popular != undefined;
		offerPanel.FindChildTraverse("GloryDiscount").text = data.bonus
			? $.Localize("#glory_offer_bonus").replace("##pct##", data.bonus)
			: "";
		const image =
			"file://{images}/custom_game/collection/glory_shop/glory_bundle_" +
			value +
			(isNoFortuneShop ? "_no_fortune.png" : ".png");
		offerPanel.FindChildTraverse("GloryOfferData").style.backgroundImage = "url('" + image + "')";
		const bundleName = "purchase_glory_bundle_" + value;
		offerPanel.FindChildTraverse("GloryOfferButton").SetPanelEvent("onactivate", function () {
			_CreatePurchaseAccess(
				bundleName,
				image,
				bundleName,
				bundleName + "_description",
				Math.round(data.price * 100) / 100,
			);
		});
	});
})();
