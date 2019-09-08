var hasPatreonStatus = false;
var isPatron = false;
var nowselected = $('#ColourWhite');

function OnPatreonButtonPressed() {
    var panel = $('#PatreonWindow');

    panel.visible = !panel.visible;
}

function ToggleEmblem() {
	if (isPatron) {
		var isEnabled = !!$('#SupporterEmblemEnableDisable').checked;
        GameEvents.SendCustomGameEventToServer('patreon_toggle_emblem', {enabled: isEnabled});
    }
}

function BootsEnableToggle() {
	if (isPatron) {
		var isEnabled = !!$('#FreeBootsEnableDisable').checked;
        GameEvents.SendCustomGameEventToServer('patreon_toggle_boots', { enabled: isEnabled });
    }
}

function OnColourPressed(text) {
    if (isPatron) {
        GameEvents.SendCustomGameEventToServer('patreon_update_emblem', { color: text });
        SelectColor(text);
    }
}

function SelectColor(colorName) {
    if (nowselected != $('#Colour' + colorName)) {
        nowselected.RemoveClass('SelecetedColor');
        $('#Colour' + colorName).AddClass('SelecetedColor');
        nowselected = $('#Colour' + colorName);
    }
}

function updatePatreonButton() {
	var minimizePatreonButton = Game.GetDOTATime(false, false) > 60;
	var hideVoIcon = Game.GetDOTATime(false, false) > 120;

	$('#PatreonButton').visible = hasPatreonStatus && !minimizePatreonButton;
	$('#PatreonButtonSmallerImage').visible = hasPatreonStatus && minimizePatreonButton;
	$('#VOIcon').visible = hasPatreonStatus && !hideVoIcon;
}

var createPaymentRequest = createEventRequestCreator('patreon:payments:create')

var currentPaymentWindowProvider = 'wechat';
var currentPaymentWindowPaymentKind = 'purchase_1';

function setPaymentWindowVisible(visible) {
	$('#PaymentWindow').visible = visible;
	$('#SupportButtonPayment').checked = visible;
	if (visible) {
		updatePaymentWindow();
	}
}

/** @param {'success' | 'loading' | { error: string }} status */
function setPaymentWindowStatus(status) {
	var isError = typeof status === 'object';
	$('#PaymentWindowBody').visible = status === 'success';
	$('#PaymentWindowLoader').visible = status === 'loading';
	$('#PaymentWindowError').visible = isError;
	if (isError) {
		$('#PaymentWindowErrorMessage').text = status.error;
	}
}

function togglePaymentWindowVisible() {
	setPaymentWindowVisible(!$('#PaymentWindow').visible);
}

var paymentWindowUpdateListener
function updatePaymentWindow() {
	if (paymentWindowUpdateListener != null) {
		GameEvents.Unsubscribe(paymentWindowUpdateListener);
	}

	$('#PaymentWindowBody').RemoveAndDeleteChildren()
	$('#PaymentWindowBody').BCreateChildren('<HTML acceptsinput="' + Game.IsInToolsMode() + '" />');
	var htmlPanel = $('#PaymentWindowBody').GetChild(0);

	setPaymentWindowStatus('loading');
	var requestData = { provider: currentPaymentWindowProvider, paymentKind: currentPaymentWindowPaymentKind };
	paymentWindowUpdateListener = createPaymentRequest(requestData, function(response) {
		if (response.url != null) {
			setPaymentWindowStatus('success');
			htmlPanel.SetURL(response.url);
		} else {
			setPaymentWindowStatus({ error: response.error || 'Unknown error' });
		}
	});
}

function openUpgradePaymentWindow() {
	$('#PaymentWindowPaymentKinds').visible = false;
	currentPaymentWindowPaymentKind = 'upgrade_to_2';
	setPaymentWindowVisible(true);
}

GameEvents.Subscribe('patreon:payments:update', function(response) {
	if (response.error) {
		setPaymentWindowStatus({ error: response.error });
	} else {
		setPaymentWindowVisible(false);
	}
});

$.GetContextPanel().RemoveClass('IsPatron');
SubscribeToNetTableKey('game_state', 'patreon_bonuses', function (data) {
	var status = data[Game.GetLocalPlayerID()];
	if (!status) return;

	hasPatreonStatus = true;
	updatePatreonButton();

	isPatron = status.level > 0;
	$.GetContextPanel().SetHasClass('IsPatron', isPatron);
	var endDate = new Date(status.endDate);
	var daysLeft = Math.ceil((endDate - Date.now()) / 1000 / 60 / 60 / 24);
	$('#PatreonSupporterStatus').SetDialogVariable('support_days_left', daysLeft);
	$('#PatreonSupporterStatus').SetDialogVariable('support_end_date', endDate.toDateString());
	$('#PatreonSupporterUpgrade').visible = status.level < 2;

	$('#FreeBootsEnableDisable').checked = !!status.bootsEnabled;
	$('#SupporterEmblemEnableDisable').checked = !!status.emblemEnabled;
	SelectColor(status.emblemColor);
});

setInterval(updatePatreonButton, 1000);
$('#PatreonWindow').visible = false;
setPaymentWindowVisible(false);
