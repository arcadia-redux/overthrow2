var hasPatreonStatus = true;
var isPatron = false;
var patreonLevel = 0
var patreonPerks = []

$( "#PatreonPerksContainer" ).RemoveAndDeleteChildren()

class PatreonPerk {
	constructor( name, level, overrideImage ) {
		this.panel = $.CreatePanel( "Panel", $( "#PatreonPerksContainer" ), "" )
		this.panel.BLoadLayoutSnippet( "PatreonPerk" )

		this.panel.FindChildTraverse( "PatreonPerkImage" ).SetImage( overrideImage || "file://{resources}/layout/custom_game/common/patreon/perks/" + name + ".png" )

		this.panel.FindChildTraverse( "PatreonPerkTitle" ).text = $.Localize( "#" + name )
		this.panel.FindChildTraverse( "PateonPerkDescription" ).text = $.Localize( "#" + name + "_description" )

		this.access = this.panel.FindChildTraverse( "PatreonPerkAccess" )
		this.level = level
		this.UpdateLevel()

		patreonPerks.push( this )
	}

	UpdateLevel() {
		if ( patreonLevel >= this.level ) {
			this.access.text = $.Localize( "available_perk" )
			this.access.SetHasClass( "Available", true )
		} else {
			if ( this.level < 2 ) {
				this.access.text = ""
			} else {
				this.access.text = $.Localize( "high_tier_supporter_perk" )
			}
			this.access.SetHasClass( "Available", false )
		}
	}
}

//class FreeBoots extends PatreonPerk {
//	constructor() {
//		super( "boots_free", 1 )
//
//		this.button = $.CreatePanel( "ToggleButton", this.panel.FindChildTraverse( "PatreonPerkAdditional" ), "" )
//		this.button.text = $.Localize( "#boots_enable" )
//		this.button.style["margin-top"] = "18px"
//
//		let btn = this.button
//
//		this.button.SetPanelEvent( "onactivate", function() {
//			if ( isPatron ) {
//				GameEvents.SendCustomGameEventToServer( "patreon_toggle_boots", { enabled: !!btn.checked } )
//			}
//		} )
//	}
//
//	Enable( bool ) {
//		this.button.checked = bool
//	}
//}

function Divider() {
	let panel = $.CreatePanel( "Panel", $( "#PatreonPerksContainer" ), "" )
	panel.AddClass( "Divider" )
}

function OnPatreonButtonPressed() {
    var panel = $('#PatreonWindow');

    panel.visible = !panel.visible;
}

var shouldHideNewMethodsAnnouncement = false;
function hideNewMethodsAnnouncement() {
	shouldHideNewMethodsAnnouncement = true;
	updatePatreonButton();
}

function updatePatreonButton() {
	// TODO: Either remove full button, or revert this change
	var minimizePatreonButton = true;

	$('#PatreonButtonPanel').visible = hasPatreonStatus;
	$('#PatreonButton').visible = !minimizePatreonButton;
	$('#PatreonButtonSmallerImage').visible = minimizePatreonButton;
	// Show icon only when chat wheel is loaded as it's not a common module yet
	$('#VOIcon').visible = Boolean(GameUI.CustomUIConfig().chatWheelLoaded) && Game.GetDOTATime(false, false) <= 120;
	$('#NewMethodsAnnouncement').visible = !shouldHideNewMethodsAnnouncement && !isPatron && $.Language() !== 'russian' && Game.GetDOTATime(false, false) <= 120;
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

var paymentWindowUpdateListener;
var paymentWindowPostUpdateTimer;
function updatePaymentWindow() {
	if (paymentWindowUpdateListener != null) {
		GameEvents.Unsubscribe(paymentWindowUpdateListener);
	}

	if (paymentWindowPostUpdateTimer != null) {
		$.CancelScheduled(paymentWindowPostUpdateTimer);
	}

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
			$('#PaymentWindowBody').SetURL(response.url);
			paymentWindowPostUpdateTimer = $.Schedule(1, function() {
				paymentWindowPostUpdateTimer = undefined;
				setPaymentWindowStatus('success');
			});
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

function SetPatreonLevel( level ) {
	patreonLevel = level

	let visible1 = false
	let visible2 = false
	let visible3 = false
	let visible4 = false
	let visible5 = false

	if ( level < 1 ) {
		visible1 = true
		visible2 = true
	} else {
		if ( level < 2 ) {
			visible3 = true
		} else {
			visible4 = true
		}

		visible5 = true
	}
	$( "#IsNotPatreonText" ).visible = visible1
	$( "#PatreonSupportButtons" ).visible = visible2
	$( "#PatreonSupporter" ).visible = visible3
	$( "#PatreonSupporterHigh" ).visible = visible4
	$( "#ThanksText" ).visible = visible5
}

$.GetContextPanel().RemoveClass('IsPatron');

//var boots = new FreeBoots()
//Divider()
new PatreonPerk( "random_unlimited", 1 )
Divider()
new PatreonPerk( "cosmetics_box", 1 )
Divider()
new PatreonPerk( "unlimited_chat_wheel", 1 )
Divider()
new PatreonPerk( "instant_transfer", 1 )
Divider()
new PatreonPerk( "immune_kick_troll", 1 )
Divider()
new PatreonPerk( "kick_troll", 2 )
Divider()
new PatreonPerk( "private_courier", 2, "s2r://panorama/images/items/courier_dire.png" )

SetPatreonLevel( 0 )

SubscribeToNetTableKey('game_state', 'patreon_bonuses', function (data) {
	var status = data[Game.GetLocalPlayerID()];
	if (!status) return;

	hasPatreonStatus = true;
	isPatron = status.level > 0;
	$.GetContextPanel().SetHasClass('IsPatron', isPatron);
	updatePatreonButton();

	SetPatreonLevel( status.level )

	var isAutoControlled = status.endDate != null;
	//$('#PatreonSupporterUpgrade').visible = isAutoControlled && status.level < 2;

	//$('#PatreonSupporterStatusExpiriesIn').visible = isAutoControlled;

	//if (isAutoControlled) {
	//	var endDate = new Date(status.endDate);
	//	var daysLeft = Math.ceil((endDate - Date.now()) / 1000 / 60 / 60 / 24);
	//	$('#PatreonSupporterStatus').SetDialogVariable('support_days_left', daysLeft);
	//	$('#PatreonSupporterStatus').SetDialogVariable('support_end_date', formatDate(endDate));
	//}

	boots.Enable( !!status.bootsEnabled )
});

setInterval(updatePatreonButton, 1000);
$('#PatreonWindow').visible = false;
setPaymentWindowVisible(false);