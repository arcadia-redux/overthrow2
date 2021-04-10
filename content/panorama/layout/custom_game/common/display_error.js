GameEvents.Subscribe("display_custom_error", function (msg) {
	GameEvents.SendEventClientSide("dota_hud_error_message", {
		splitscreenplayer: 0,
		reason: 80,
		message: msg.message,
	});
});
GameEvents.Subscribe("display_custom_error_with_value", function (msg) {
	let base_message = $.Localize(msg.message);
	Object.entries(msg.values).forEach(([key, value]) => {
		base_message = base_message.replace(`##${key}##`, $.Localize(value));
	});
	GameEvents.SendEventClientSide("dota_hud_error_message", {
		splitscreenplayer: 0,
		reason: 80,
		message: base_message,
	});
});
