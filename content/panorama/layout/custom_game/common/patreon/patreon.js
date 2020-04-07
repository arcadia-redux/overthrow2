var hasPatreonStatus = true;
var isPatron = false;
var patreonLevel = 0
var patreonPerks = []
var giftNotificationRemainingTime = 0;
var giftNotificationScheduler = false;
var paymentTargetID = Game.GetLocalPlayerID();
var donation_target_dropdown = false;

var local_steam_id = Game.GetPlayerInfo(Game.GetLocalPlayerID()).player_steamid

if (local_steam_id == 76561198054179075 || local_steam_id == 76561198988961452) {
	$('#PaymentWindowUserSelectorContainer').style.visibility = 'visible';
	$('#PaymentWindowAvatar').style.visibility = 'visible';
}

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
		$('#PaymentWindowDropDown').enabled = true;
	} else {
		$('#PaymentWindowDropDown').enabled = false;
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

	var requestData = { provider: provider, paymentKind: paymentKind, paymentTargetID: paymentTargetID };
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
new PatreonPerk( "our_thanks_and_appreciation", 1 )
Divider()
new PatreonPerk( "supporter_perks_low", 1 )
Divider()
new PatreonPerk( "first_pick_low", 1 )
Divider()
new PatreonPerk( "instant_transfer", 1 )
Divider()
new PatreonPerk( "immune_kick_troll", 1 )
Divider()

new PatreonPerk( "first_pick_high", 2 )
Divider()
new PatreonPerk( "supporter_perks_high", 2 )
Divider()
new PatreonPerk( "kick_troll", 2 )
//Divider()

SetPatreonLevel( 0 )

SubscribeToNetTableKey('game_state', 'patreon_bonuses', function (data) {
	UpdatePaymentTargetList(data);

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

GameEvents.Subscribe('patreon:gift:notification', function(data) {
	$.Msg("client received event")
	$('#GiftNotificationAvatar').steamid =  Game.GetPlayerInfo(data.playerId).player_steamid
	$('#GiftNotificationName').text = Players.GetPlayerName(data.playerId)
	$('#GiftNotificationLabel').text = $.Localize('#received_gift_' + data.level)
	$('#GiftNotificationPanel').style.opacity = 1;

	Particles.CreateParticle("particles/patreon_gift_tier_" + data.level + ".vpcf", ParticleAttachment_t.PATTACH_EYES_FOLLOW, 1)
	if (data.level == 1) {
		Game.EmitSound("Waitingforplayers_Boost_Shared")
		Game.EmitSound("Loot_Drop_Stinger_Rare")
	} else if (data.level == 2) {
		Game.EmitSound("Waitingforplayers_Boost_Shared")
		Game.EmitSound("Loot_Drop_Stinger_Ancient")
	}

	giftNotificationRemainingTime = 8;
	if (giftNotificationScheduler) {
		$.CancelScheduled(giftNotificationScheduler);
	}
	giftNotificationScheduler = $.Schedule(0.1, GiftNotificationTick);
});

function GiftNotificationTick() {
	giftNotificationRemainingTime -= 0.1;
	if (giftNotificationRemainingTime > 0) {
		giftNotificationScheduler = $.Schedule(0.1, GiftNotificationTick);
	} else {
		$('#GiftNotificationPanel').style.opacity = 0;
		giftNotificationScheduler = false;
	}
}

function UpdatePaymentTargetList(patreonData) {
	if (donation_target_dropdown) {
		for(var id = 0; id <= 23; id++) {
			if (Players.IsValidPlayerID(id)) {
				if (patreonData[id] && patreonData[id].level > 0) {
					var this_player_option = $('#PatreonOption' + id);
					if (this_player_option) {
						this_player_option.DeleteAsync(0)
					}
				}
			}
		}
	} else {
		var dropdown_parent = $('#PaymentWindowUserSelectorContainer');
		donation_target_dropdown = $.CreatePanel('DropDown', dropdown_parent, 'PaymentWindowDropDown');
		var layout_string = '<root><DropDown style="margin-left: 5px;" oninputsubmit="updatePaymentWindow()" >';

		for(var id = 0; id <= 23; id++) {
			if (Players.IsValidPlayerID(id)) {
				if (!patreonData[id] || patreonData[id].level <= 0) {
					layout_string += `<Label text="${Players.GetPlayerName(id)}" id="PatreonOption${id}" onmouseover="UpdatePaymentTarget(${id})" />`;
				}
			}
		}
		layout_string = layout_string + '</DropDown></root>';
		donation_target_dropdown.BLoadLayoutFromString(layout_string, false, true);
	}
}

function UpdatePaymentTarget(id) {
	$('#PaymentWindowAvatar').steamid = Game.GetPlayerInfo(id).player_steamid;
	paymentTargetID = id;
}

setInterval(updatePatreonButton, 1000);
$('#PatreonWindow').visible = false;
setPaymentWindowVisible(false);
