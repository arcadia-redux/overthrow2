var wait_time = [
	6, // 0 level patreon
	3, // 1 level patreon
	0 // 2 level patreon
]

var localized_text = [
	$.Localize("#HighSupportersOnly"),
	$.Localize("#SupportersOnly"),
	$.Localize("#DOTA_Hero_Selection_LOCKIN"),
]

var interval = 0.3

function _InvokeUpdate(initial_time, new_time, buttons) {
	$.Schedule(interval, function() {
		_UpdatePickButton(initial_time, new_time, buttons)
	})
}

function _UpdatePickButton(initial_time, time, buttons) {
	// waiting until ban phase or pause expires
	if (Game.IsInBanPhase() || Game.IsGamePaused()) { 
		_InvokeUpdate(initial_time, time, buttons)
		return
	}

	let lock_text = localized_text[0]
	if (time <= 3 && initial_time > 3) {
		lock_text = localized_text[1]
	}
	
	buttons[0].GetChild(0).text = `${lock_text} (${time.toFixed(0)})`
	if (time < interval) {

		buttons.forEach(button => {
			button.SetAcceptsFocus(true)
			button.BAcceptsInput(true)
			button.style.saturation = null
			button.style.brightness = null
		})

		buttons[0].GetChild(0).text = localized_text[2]
		return
	}

	_InvokeUpdate(initial_time, time - interval, buttons)
}

function _InitPickLocker(level) {
	$.Msg("Locking pick button, patreon level: ", level)
	let pick_button = FindDotaHudElement("LockInButton")
	let random_button = FindDotaHudElement("RandomButton")
	let smart_random_button = FindDotaHudElement("smartRandomButton")

	let buttons = [pick_button, random_button, smart_random_button]

	if (level < 2) {
		let time = wait_time[level]

		buttons.forEach(button => {
			button.SetAcceptsFocus(false)
			button.BAcceptsInput(false)
			button.style.saturation = 0.0
			button.style.brightness = 0.2
		})

		let label = pick_button.GetChild(0)
		label.style.width = "95%"
		label.style.height = "25px"
		label.style.horizontalAlign = "left"
		label.style.textOverflow = "shrink"

		_UpdatePickButton(time, time, buttons)
	}
}

SubscribeToNetTableKey("game_state", "patreon_bonuses", function (patreon_bonuses) {
	let local_stats = patreon_bonuses[Game.GetLocalPlayerID()];
	let level = 0
	if (local_stats && local_stats.level) {
		level = local_stats.level
	}
	_InitPickLocker(level)
})