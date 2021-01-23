const TEXT_FIELD = $("#FeedbackText");
const SEND_BUTTON = $("#FeedbackSendButton");
const MAX_SYMBOLS_FIELD = $("#MaxSymbols");
const MAX_SYMBOLS = 500;
const textLength = () => {
	return TEXT_FIELD.text.length;
};

let defaultText = false;
function SendFeedback() {
	const text = TEXT_FIELD.text;
	if (!SEND_BUTTON.BHasClass("Cooldown") && text != "") {
		SEND_BUTTON.SetHasClass("Cooldown", true);
		GameEvents.SendCustomGameEventToServer("feedback:send_feedback", {
			text: text,
		});
		TEXT_FIELD.text = "";
		Game.EmitSound("General.ButtonClick");
	}
}
function UpdateCooldown(data) {
	SEND_BUTTON.SetHasClass("Cooldown", data.cooldown == 1);
}

function FeedbackTooltip() {
	if (SEND_BUTTON.BHasClass("Cooldown")) {
		$.DispatchEvent("DOTAShowTextTooltip", SEND_BUTTON, $.Localize("#feedback_cooldown"));
	} else if (SEND_BUTTON.BHasClass("Blocked")) {
		$.DispatchEvent("DOTAShowTextTooltip", SEND_BUTTON, $.Localize("#feedback_blocked"));
	}
}

function UpdateFeedbackText() {
	SEND_BUTTON.SetHasClass("Blocked", TEXT_FIELD.text == "");
	const overLimit = textLength() > MAX_SYMBOLS;
	if (overLimit) {
		TEXT_FIELD.text = TEXT_FIELD.text.substring(0, MAX_SYMBOLS);
	}
	MAX_SYMBOLS_FIELD.SetHasClass("max", overLimit);
	MAX_SYMBOLS_FIELD.SetDialogVariable("curr", textLength());
}
function CloseFeedback() {
	const feedbackMenu = FindDotaHudElement("FeedbackHeaderRoot").GetParent();
	feedbackMenu.ToggleClass("show");
	Game.EmitSound("ui_chat_slide_in");
}
(function () {
	MAX_SYMBOLS_FIELD.SetDialogVariable("max", MAX_SYMBOLS);
	MAX_SYMBOLS_FIELD.SetDialogVariable("curr", 0);
	GameEvents.Subscribe("feedback:update_cooldown", UpdateCooldown);
	GameEvents.SendCustomGameEventToServer("feedback:check_cooldown", {});
})();
