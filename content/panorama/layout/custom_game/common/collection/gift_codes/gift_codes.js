let player_id_for_gift = LOCAL_PLAYER_ID;
let code_for_local_gift;
let local_gift_activated = false;
let schedule_notification_for_all;
let schedule_notification_for_target;

function GetCodeItemNameFromPaymentKind(payment_kind) {
	if (payment_kind == "base_booster" || payment_kind == "golden_booster") payment_kind = `player_${payment_kind}`;
	return payment_kind;
}
class GiftCode {
	constructor(code, item_name_key) {
		this.code = code
			.replace(/.{1,4}/g, (token, i) => {
				return `${token}${i + 4 == code.length ? "" : "-"}`;
			})
			.toUpperCase();

		const new_code_panel = $.CreatePanel("Panel", PLAYER_CODES_ROOT, "");
		new_code_panel.BLoadLayoutSnippet("GiftCode");

		this.code_value_label = new_code_panel.FindChildTraverse("GiftCode_Value");
		this.state_description_label = new_code_panel.FindChildTraverse("GiftCode_Status");

		this.SetReveal(false);
		this.panel = new_code_panel;
		this.claimed_steam_id_panel = new_code_panel.FindChildTraverse("GiftCode_CodeUsed").GetChild(1);

		new_code_panel.FindChildTraverse("GiftCode_Name").text = $.Localize(
			GetCodeItemNameFromPaymentKind(item_name_key),
		);

		this.SetState(CODE_LIST_AVAILABLE);

		new_code_panel.FindChildTraverse("GiftCode_RevealButton").SetPanelEvent("onactivate", () => {
			this.SetReveal(!this.reveal);
		});
		new_code_panel.FindChildTraverse("GiftCode_ReclaimButton").SetPanelEvent("onactivate", () => {
			this.Reclaim();
		});
		new_code_panel.FindChildTraverse("GiftCode_ValueWrap").SetPanelEvent("onactivate", () => {
			$.DispatchEvent("CopyStringToClipboard", this.code, null);
		});
		const send_button = new_code_panel.FindChildTraverse("GiftCode_SendButton");
		send_button.SetPanelEvent("onmouseover", () => {
			if (!local_gift_activated) return;
			const pos = send_button.GetPositionWithinWindow();
			const x_scale = send_button.actualuiscale_x;
			const y_scale = send_button.actualuiscale_y;
			const set_element_pos = function (panel, x_fix, y_fix, min) {
				panel.style.position =
					`${pos.x / x_scale + send_button.actuallayoutwidth / x_scale + x_fix}px ` +
					`${Math.min(pos.y / y_scale - panel.actuallayoutheight / y_scale / 2 + y_fix, min)}px 0px`;
			};
			set_element_pos(LOCAL_GIFT_ROOT, 0, 20, 570);
			set_element_pos(LOCAL_GIFT_ARROW, -13, 17, Infinity);
			ToggleLocalGiftCodes(true);
			code_for_local_gift = this;
		});
		send_button.SetPanelEvent("onmouseout", () => {
			ToggleLocalGiftCodes(false, 0.3);
		});
	}
	SendToPlayer(player_id) {
		GameEvents.SendCustomGameEventToServer("gift_codes:send_code_to_player", {
			code: this.code.replace(/-/g, "").toLowerCase(),
			target_id: player_id,
		});
		ToggleLocalGiftCodes(false);
	}
	SetReveal(b_state) {
		this.reveal = b_state;
		this.code_value_label.text = this.reveal ? this.code : `${this.code.slice(0, this.code.length - 4)}****`;
	}
	Reclaim() {
		UseGiftCode(this.code, true);
	}
	SetState(state) {
		this.state = state;
		this.state_description_label.text = $.Localize(`gift_code_state_${this.state}`).toUpperCase();
	}
	SetReclaimedState(steam_id) {
		this.panel.SetParent(PLAYER_CLAIMED_CODES_ROOT);
		this.claimed_steam_id_panel.steamid = steam_id;
		this.SetState(CODE_LIST_CLAIMED);
	}
}

function UpdateLocalCodes() {
	if (UPDATE_CODES_BUTTON.BHasClass("Cooldown")) return;
	UPDATE_CODES_BUTTON.SetHasClass("Cooldown", true);
	GameEvents.SendCustomGameEventToServer("gift_codes:refresh_codes", {});
	$.Schedule(COOLDOWN_FOR_REFRESH_CODES, () => {
		UPDATE_CODES_BUTTON.SetHasClass("Cooldown", false);
	});
}

function CreateGiftCodes(codes) {
	PLAYER_CODES_ROOT.RemoveAndDeleteChildren();
	PLAYER_CLAIMED_CODES_ROOT.RemoveAndDeleteChildren();
	Object.entries(codes).forEach(([code, code_data]) => {
		const new_code = new GiftCode(code, code_data.paymentKind);
		if (code_data.redeemerSteamId != null && code_data.redeemerSteamId != "None")
			new_code.SetReclaimedState(code_data.redeemerSteamId);
	});
}
function CloseGiftCodes() {
	ToggleLocalGiftCodes(false);
	const collection = FindDotaHudElement("CollectionDotaU");
	if (collection.BHasClass("show")) collection.SetFocus();
	GIFT_CODES_ROOT.SetHasClass("Show", false);
	GIFT_CODE_REDEEM_STATE.SetHasClass("Show", false);
	Game.EmitSound("ui_friends_slide_in");
}

function CodeUsedFromServer(data) {
	switch (data.reason) {
		case GIFT_CODE_INCORRECT:
			GIFT_CODE_REDEEM_STATE_TEXT.text = $.Localize("#gift_code_invalid");
			Game.EmitSound("gift_codes.incorrect");
			break;
		case GIFT_CODE_USED:
			GIFT_CODE_REDEEM_STATE_TEXT.text = $.Localize("#gift_code_already_claimed");
			Game.EmitSound("gift_codes.claimed");
			break;
		case GIFT_CODE_ACTIVATED:
			NEW_GIFT_CODE_VALUE.text = "";
			GIFT_CODE_REDEEM_STATE_TEXT.text = $.Localize("#gift_code_activated_fine");
			Game.EmitSound("gift_codes.activated");
			break;
	}
	GIFT_CODE_REDEEM_STATE.SetHasClass("Show", true);
	GIFT_CODE_REDEEM_STATE.SetHasClass(`CodeReason_${GIFT_CODE_REDEEM_STATE.old_state || ""}`, false);
	GIFT_CODE_REDEEM_STATE.old_state = data.reason;
	GIFT_CODE_REDEEM_STATE.SetHasClass(`CodeReason_${data.reason}`, true);
}
function HideIncorrectCode() {
	GIFT_CODE_REDEEM_STATE.SetHasClass("Show", false);
}
function UseGiftCode(code, is_reclaim) {
	code = code.replace(/-/g, "").toLowerCase();
	GameEvents.SendCustomGameEventToServer("gift_codes:redeem_code", {
		code: code,
		is_reclaim: is_reclaim,
	});
}
function RedeemNewCode() {
	let code = NEW_GIFT_CODE_VALUE.text;
	if (!code.search(CODE_LAYOUT)) {
		UseGiftCode(code, false);
	} else {
		CodeUsedFromServer({ reason: GIFT_CODE_INCORRECT });
	}
}

function ToggleLocalGiftCodes(b_state, time_for_update_state) {
	if (time_for_update_state == undefined) time_for_update_state = 0;
	LOCAL_GIFT_ROOT.is_show = b_state;
	$.Schedule(time_for_update_state, () => {
		LOCAL_GIFT_ROOT.SetHasClass("Show", !LOCAL_GIFT_ROOT.is_show ? b_state : true);
		LOCAL_GIFT_ARROW.SetHasClass("Show", !LOCAL_GIFT_ROOT.is_show ? b_state : true);
		if (!LOCAL_GIFT_ROOT.BHasClass("Show")) {
			PLAYERS_FOR_GIFT_ROOT.Children().forEach((panel) => {
				panel.RemoveClass("Selected");
			});
			LOCAL_GIFT_BUTTON.SetHasClass("Active", false);
		}
	});
}

function ShowLocalGiftCodes() {
	ToggleLocalGiftCodes(true);
}
function HideLocalGiftCodes() {
	ToggleLocalGiftCodes(false, 0.3);
}

function SendCodeToLocalPlayer() {
	if (!LOCAL_GIFT_BUTTON.BHasClass("Active")) return;
	if (player_id_for_gift == LOCAL_PLAYER_ID) return;
	if (code_for_local_gift == null) return;

	code_for_local_gift.SendToPlayer(player_id_for_gift);
}
function UpdateHeroSelection(data) {
	const player_id = data.playerId;
	const player_in_gift_panel = $(`#PlayerInGift_${player_id}`);
	if (player_in_gift_panel != undefined) {
		const player_info = Game.GetPlayerInfo(player_id);
		if (player_info == undefined) return;
		player_in_gift_panel.FindChildTraverse("PlayerGiftHeroName").text = $.Localize(
			player_info.player_selected_hero,
		);
	}
}

function StopSchedule(schelude) {
	if (schelude != null) {
		$.CancelScheduled(schelude);
	}
}

function CodeWasGiftNotification(data) {
	const target_id = data.target_id;
	const sender_id = data.sender_id;
	const payment_kind = GetCodeItemNameFromPaymentKind(data.payment_kind);

	const start_notification = (panel, schedule, time_for_hide) => {
		StopSchedule(schedule);
		panel.SetHasClass("Show", true);
		schedule = $.Schedule(time_for_hide, () => {
			schedule = undefined;
			panel.SetHasClass("Show", false);
		});
	};
	start_notification(GIFT_NOTIFICATION_FOR_ALL, schedule_notification_for_all, 4);
	if (target_id == LOCAL_PLAYER_ID) {
		Game.EmitSound("gift_codes.notification_gift");
		start_notification(GIFT_NOTIFICATION_FOR_TARGET, schedule_notification_for_target, 6);
	}

	const sender_info = Game.GetPlayerInfo(sender_id);
	if (sender_info != undefined) {
		GIFT_NOTIFICATION_FOR_ALL_SENDER_NAME.text = sender_info.player_name;
		if (target_id == LOCAL_PLAYER_ID) {
			GIFT_NOTIFICATION_FOR_TARGET_SENDER_NAME.steamid = sender_info.player_steamid;
			GIFT_NOTIFICATION_FOR_TARGET_SENDER_HERO.text = $.Localize(sender_info.player_selected_hero);
			GIFT_NOTIFICATION_FOR_TARGET_ITEM.text = $.Localize(GetCodeItemNameFromPaymentKind(payment_kind));
		}
	}

	const target_info = Game.GetPlayerInfo(target_id);
	if (target_info != undefined) GIFT_NOTIFICATION_FOR_ALL_TARGET_NAME.text = target_info.player_name;
}

function CreateLocalPlayersForGifts() {
	for (let player_id = 0; player_id < 24; player_id++) {
		if (player_id == LOCAL_PLAYER_ID) continue;
		const player_info = Game.GetPlayerInfo(player_id);
		if (player_info == undefined) continue;
		const new_player_panel = $.CreatePanel("Button", PLAYERS_FOR_GIFT_ROOT, `PlayerInGift_${player_id}`);
		new_player_panel.BLoadLayoutSnippet("PlayerForGift");
		new_player_panel.FindChildTraverse("PlayerGiftHeroName").text = $.Localize(player_info.player_selected_hero);
		const avatar_panel = new_player_panel.FindChildTraverse("PlayerForGiftAvatar");
		avatar_panel.steamid = player_info.player_steamid;
		avatar_panel.SetHasClass("IsHaveAvatar", player_info.player_connection_state != 1);
		new_player_panel.FindChildTraverse("PlayerGift_SteamName").steamid = player_info.player_steamid;

		new_player_panel.SetPanelEvent("onactivate", () => {
			player_id_for_gift = player_id;
			if (!new_player_panel.BHasClass("Selected")) Game.EmitSound("gift_codes.target_for_gift");
			PLAYERS_FOR_GIFT_ROOT.Children().forEach((panel) => {
				panel.RemoveClass("Selected");
			});
			new_player_panel.AddClass("Selected");
			LOCAL_GIFT_BUTTON.SetHasClass("Active", true);
		});
		$.GetContextPanel().SetHasClass("HavePlayerForGift", true);

		local_gift_activated = true;
	}
}

function OpenCollectionFromGiftNoticiation() {
	ToggleMenu(`CollectionDotaU`);
	StopSchedule(schedule_notification_for_target);
	GIFT_NOTIFICATION_FOR_TARGET.SetHasClass("Show", false);
}

(function () {
	PLAYERS_FOR_GIFT_ROOT.RemoveAndDeleteChildren();
	CreateLocalPlayersForGifts();
	GameEvents.SendCustomGameEventToServer("gift_codes:get_codes", {});
	GameEvents.Subscribe("gift_codes:update_codes", CreateGiftCodes);
	GameEvents.Subscribe("gift_codes:code_used_from_server", CodeUsedFromServer);
	GameEvents.Subscribe("gift_codes:code_was_gift", CodeWasGiftNotification);
	GameEvents.Subscribe("player_show_aegis_init", UpdateHeroSelection);
})();
