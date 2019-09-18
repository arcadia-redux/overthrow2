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

var showNewPaymentMethods = Game.IsInToolsMode();
Game.AddCommand("dota_2_unofficial_new_payment_methods", function() {
	showNewPaymentMethods = true;
	updatePatreonButton();
}, "", 0);

function updatePatreonButton() {
	// TODO: Either remove full button, or revert this change
	var minimizePatreonButton = true;

	$('#PatreonButtonPanel').visible = hasPatreonStatus;
	$('#PatreonButton').visible = !minimizePatreonButton;
	$('#PatreonButtonSmallerImage').visible = minimizePatreonButton;
	$('#VOIcon').visible = Game.GetDOTATime(false, false) <= 120;
	$('#NewMethodsAnnouncement').visible = showNewPaymentMethods && !isPatron && $.Language() !== 'russian';
	$('#SupportButtonPaymentWindow').visible = showNewPaymentMethods;
}

function setPaymentWindowVisible(visible) {
	GameEvents.SendCustomGameEventToServer('patreon:payments:window', { visible: visible });
	$('#PaymentWindow').visible = visible;
	$('#SupportButtonPaymentWindow').checked = visible;
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

var createPaymentRequest = createEventRequestCreator('patreon:payments:create');

var paymentWindowUpdateListener
function updatePaymentWindow() {
	if (paymentWindowUpdateListener != null) {
		GameEvents.Unsubscribe(paymentWindowUpdateListener);
	}

	$('#PaymentWindowBody').RemoveAndDeleteChildren()
	$('#PaymentWindowBody').BCreateChildren('<HTML acceptsinput="true" />');
	var htmlPanel = $('#PaymentWindowBody').GetChild(0);

	setPaymentWindowStatus('loading');

	var provider;
	for (var child of $('#PaymentWindowProviders').Children()) {
		if (child.checked) {
			provider = child.GetAttributeString("value", undefined);
		}
	}

	var paymentKind;
	for (var child of $('#PaymentWindowPaymentKinds').Children()) {
		if (child.checked) {
			paymentKind = child.GetAttributeString("value", undefined);
		}
	}

	var requestData = { provider: provider, paymentKind: paymentKind };
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
	$('#PaymentWindowPaymentKindsUpgradeTo2').checked = true;
	setPaymentWindowVisible(true);
}

function openPurchasePaymentWindow(value) {
	for (var child of $('#PaymentWindowProviders').Children()) {
		if (child.GetAttributeString("value", undefined) === value) {
			child.checked = true;
		}
	}

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
	isPatron = status.level > 0;
	$.GetContextPanel().SetHasClass('IsPatron', isPatron);
	updatePatreonButton();

	var isAutoControlled = status.endDate != null;
	$('#PatreonSupporterUpgrade').visible = isAutoControlled && status.level < 2;
	$('#PatreonSupporterStatusExpiriesIn').visible = isAutoControlled;
	if (isAutoControlled) {
		var endDate = new Date(status.endDate);
		var daysLeft = Math.ceil((endDate - Date.now()) / 1000 / 60 / 60 / 24);
		$('#PatreonSupporterStatus').SetDialogVariable('support_days_left', daysLeft);
		$('#PatreonSupporterStatus').SetDialogVariable('support_end_date', formatDate(endDate));
	}

	$('#FreeBootsEnableDisable').checked = !!status.bootsEnabled;
	$('#SupporterEmblemEnableDisable').checked = !!status.emblemEnabled;
	SelectColor(status.emblemColor);
});

setInterval(updatePatreonButton, 1000);
$('#PatreonWindow').visible = false;
setPaymentWindowVisible(false);
