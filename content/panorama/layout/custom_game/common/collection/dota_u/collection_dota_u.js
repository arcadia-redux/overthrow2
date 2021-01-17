(function () {
	if (FindDotaHudElement("CollectionTopButton") != undefined) return;
	const collectionButton = _AddMenuButton("CollectionTopButton");
	CreateButtonInTopMenu(
		collectionButton,
		() => {
			boostGlow = false;
			ToggleMenu("CollectionDotaU");
		},
		() => {
			$.DispatchEvent("DOTAShowTextTooltip", collectionButton, "#TopMenuIcon_Collection_message");
		},
		() => {
			$.DispatchEvent("DOTAHideTextTooltip");
		},
	);
})();
