const NON_BREAKING_SPACE = "\u00A0";
const BASE_MESSAGE_INDENT = NON_BREAKING_SPACE.repeat(19);

GameEvents.Subscribe("custom_chat_message", (event) => {
	let text = BASE_MESSAGE_INDENT;

	const chatLinesPanel = FindDotaHudElement("ChatLinesPanel");
	const message = $.CreatePanelWithProperties("Label", chatLinesPanel, "", {
		class: "ChatLine",
		html: "true",
		selectionpos: "auto",
		hittest: "false",
		hittestchildren: "false",
	});
	message.style.flowChildren = "right";
	message.style.color = "#faeac9";
	message.style.opacity = 1;
	$.Schedule(7, () => {
		message.style.opacity = null;
	});

	if (event.PlayerID > -1) {
		const playerInfo = Game.GetPlayerInfo(event.PlayerID);
		const localTeamColor = GameUI.CustomUIConfig().team_colors[playerInfo.player_team_id];

		text += event.isTeam ? `[${$.Localize("#DOTA_ChatCommand_GameAllies_Name")}] ` : NON_BREAKING_SPACE;
		text += `<font color='${localTeamColor}'>${playerInfo.player_name}</font>: `;

		$.CreatePanelWithProperties("Panel", message, "", { class: "HeroBadge", selectionpos: "auto" });

		const heroIcon = $.CreatePanelWithProperties("Image", message, "", { class: "HeroIcon", selectionpos: "auto" });
		heroIcon.SetImage("file://{images}/heroes/" + playerInfo.player_selected_hero + ".png");
	} else {
		text += event.isTeam ? `[${$.Localize("#DOTA_ChatCommand_GameAllies_Name")}] ` : NON_BREAKING_SPACE;
	}

	text += event.textData.replace(/%%\d*(.+?)%%/g, (_, token) => $.Localize(token));
	message.text = text;
});
