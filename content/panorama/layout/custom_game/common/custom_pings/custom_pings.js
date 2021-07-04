let time_counter = 0;
let b_root_visible = false;
let tracker_hud;

function SetRootPingActive(bool) {
	tracker_hud.hittest = bool;
	HUD_ROOT_FOR_TRACKER.hittestchildren = bool;
}

function ClearActive() {
	for (let i = 1; i <= PINGS_COUNT; i++) {
		$(`#Custom_Ping${i}`).SetHasClass("Active", false);
	}
	HUD_PING_WHEEL.SetHasClass("DefaultPing", false);
}

function PingToServer() {
	for (let i = 1; i <= PINGS_COUNT; i++) {
		const panel = $(`#Custom_Ping${i}`);
		if (panel.BHasClass("Active")) {
			let ping_pos_screen = HUD_PING_WHEEL.GetPositionWithinWindow();
			const x = ping_pos_screen.x + hud_wheel_half_width;
			const y = ping_pos_screen.y + hud_wheel_half_height;
			GameEvents.SendCustomGameEventToServer("custom_ping:ping", {
				pos: Game.ScreenXYToWorld(x, y),
				type: panel.GetAttributeInt("ping-type", 0),
			});
		}
	}
}

function GamePingsTracker() {
	if (GameUI.IsAltDown() && GameUI.IsMouseDown(0)) {
		time_counter += THINK;
	} else {
		if (b_root_visible) PingToServer();
		ClearActive();
		SetRootPingActive(false);
		HUD_PING_WHEEL.visible = false;
		b_root_visible = false;
		time_counter = 0;
	}

	if (time_counter >= TRIGGER_TIME_FOR_WHEEL && !b_root_visible) {
		const cursor = GameUI.GetCursorPosition();
		SetRootPingActive(true);
		$.Schedule(0.01, () => {
			if (tracker_hud.BHasHoverStyle()) {
				HUD_PING_WHEEL.visible = true;
				b_root_visible = true;
				HUD_PING_WHEEL.style.position = `${(cursor[0] - hud_wheel_half_width) / ROOT.actualuiscale_x}px ${
					(cursor[1] - hud_wheel_half_height) / ROOT.actualuiscale_y
				}px 0px`;
			}
		});
	}

	if (b_root_visible) {
		ClearActive();
		const cursor = GameUI.GetCursorPosition();
		const root_pos = HUD_PING_WHEEL.GetPositionWithinWindow();

		const x = cursor[0] - root_pos.x - hud_wheel_half_width;
		const y = root_pos.y - cursor[1] + hud_wheel_half_height;

		let deg = (Math.atan2(y, x) * 180) / Math.PI + (y < 0 ? 360 : 0);

		let element_n = Math.ceil(0.5 + deg / (360 / (PINGS_COUNT - 1)));
		element_n = element_n == 7 ? 1 : element_n;

		const x_abs = Math.abs(x);
		const y_abs = Math.abs(y);
		if (x_abs < MIN_OFFSET && y_abs < MIN_OFFSET) element_n = 7;

		if (x_abs <= MAX_OFFSET * ROOT.actualuiscale_x && y_abs <= MAX_OFFSET * ROOT.actualuiscale_y) {
			const panel = $(`#Custom_Ping${element_n}`);
			if (panel) panel.SetHasClass("Active", true);
			HUD_PING_WHEEL.SetHasClass("DefaultPing", element_n == 7);
		}
	}
	$.Schedule(THINK, () => {
		GamePingsTracker();
	});
}

function ClientPing(data) {
	if (data.type == undefined || PINGS_DATA[data.type] == undefined) return;

	const original_map_width = Math.ceil(minimap.actuallayoutwidth / minimap.actualuiscale_x);
	const original_map_height = Math.ceil(minimap.actuallayoutheight / minimap.actualuiscale_y);

	const world_pos = data.pos.split(" ");

	const coef_x = world_pos[0] / (WORLD_X * 2);
	const coef_y = world_pos[1] / (WORLD_Y * 2);
	const pos_x = (coef_x + 0.5) * original_map_width + X_OFFSET;
	const pos_y = (0.5 - coef_y) * original_map_height + Y_OFFSET;

	if (pos_x > original_map_width || pos_y > original_map_height) return;

	const new_ping = $.CreatePanel("Panel", HUD_FOR_CUSTOM_PINGS, "");
	new_ping.BLoadLayoutSnippet("CustomPing");

	const margin_side = pos_x - hud_ping_root_half_width + coef_x * 8;
	if (dota_hud.BHasClass("HUDFlipped")) {
		new_ping.style.marginLeft = `${original_map_width - margin_side - hud_ping_root_half_width * 2}px`;
	} else {
		new_ping.style.marginLeft = `${margin_side}px`;
	}

	const margin_top = pos_y + hud_ping_root_half_height - coef_y * 8;

	new_ping.style.marginTop = `${original_map_height - margin_top}px`;

	const image = new_ping.GetChild(0);
	image.AddClass("Pulse");

	if (PINGS_DATA[data.type].image != undefined) {
		image.SetImage(PINGS_DATA[data.type].image);
	}
	if (PINGS_DATA[data.type].sound != undefined) {
		Game.EmitSound(PINGS_DATA[data.type].sound);
	}

	if (data.type == C_PingsTypes.DEFAULT || data.type == C_PingsTypes.DANGER || data.type == C_PingsTypes.WAYPOINT) {
		var player_color = GetHEXPlayerColor(data.player_id);
		image.style.washColor = player_color;
	} else if (data.type == C_PingsTypes.RETREAT) {
		image.style.washColor = "#ff0a0a;";
	}

	let text_label;

	if (data.type == C_PingsTypes.WAYPOINT) {
		let hero_name = Players.GetPlayerSelectedHero(data.player_id);
		new_ping.GetChild(1).SetImage(GetPortraitIcon(data.player_id, hero_name));
		text_label = $.CreatePanel("Label", ROOT, "");
		text_label.AddClass("HeroNamePing");
		text_label.text = $.Localize(hero_name);
		text_label.style.color = player_color;
		text_label.SetParent(tracker_hud);
		$.Schedule(0.01, () => {
			FreezePanel(text_label, parseInt(world_pos[0]), parseInt(world_pos[1]), parseInt(world_pos[2]) + 120);
		});
	}

	$.Schedule(3.5, () => {
		new_ping.DeleteAsync(0);
		if (text_label) text_label.DeleteAsync(0);
	});
}

function FreezePanel(panel, pos_x, pos_y, pos_z) {
	if (!panel.IsValid()) return;
	const sX = Game.WorldToScreenX(pos_x, pos_y, pos_z);
	const sY = Game.WorldToScreenY(pos_x, pos_y, pos_z);

	var x = sX / panel.actualuiscale_x - panel.actuallayoutwidth / 2;
	var y = sY / panel.actualuiscale_y - panel.actuallayoutheight;
	panel.SetPositionInPixels(x, y, 0);
	$.Schedule(0, () => {
		FreezePanel(panel, pos_x, pos_y, pos_z);
	});
}

(function () {
	HUD_FOR_CUSTOM_PINGS.RemoveAndDeleteChildren();
	HUD_ROOT_FOR_TRACKER.Children().forEach((p) => {
		if (p.id == "CustomPingsHudTracker") p.DeleteAsync(0);
	});
	const panel = $("#CustomPingsHudTracker");
	panel.SetParent(HUD_ROOT_FOR_TRACKER);
	panel.hittest = true;
	tracker_hud = panel;
	GamePingsTracker();
	GameEvents.Subscribe("custom_ping:ping_client", ClientPing);
})();
