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

	if (FindDotaHudElement("FeedbackButton") != undefined) return;
	const feedbackButton = _AddMenuButton("FeedbackButton");
	CreateButtonInTopMenu(
		feedbackButton,
		() => {
			const feedbackMenu = FindDotaHudElement("FeedbackHeaderRoot").GetParent();
			feedbackMenu.ToggleClass("show");
		},
		() => {
			$.DispatchEvent("DOTAShowTextTooltip", feedbackButton, "#feedback_top_menu_hint");
		},
		() => {
			$.DispatchEvent("DOTAHideTextTooltip");
		},
	);
})();
