(function () {
	const neutralItems = FindDotaHudElement("TeamNeutralItemsTierList");
	neutralItems.GetParent().style.overflow = "squish scroll";
	neutralItems.Children().forEach((neutralTier) => {
		const panel = neutralTier.GetChild(1);
		panel.style.flowChildren = "right-wrap";
	});
})();
