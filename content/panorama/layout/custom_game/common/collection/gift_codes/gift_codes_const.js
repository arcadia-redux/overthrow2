const CODE_LIST_AVAILABLE = 0;
const CODE_LIST_CLAIMED = 1;

const GIFT_CODE_USED = 0;
const GIFT_CODE_INCORRECT = 1;
const GIFT_CODE_ACTIVATED = 2;
const LOCAL_PLAYER_ID = Game.GetLocalPlayerID();

const CODE_LAYOUT = /(\w{4}-){4}\w{4}/;

const GIFT_CODES_ROOT = $("#GiftCodes_PanelWrap");
const PLAYER_CODES_ROOT = $("#GiftCodes_PlayerCodesAvaileble");
const PLAYER_CLAIMED_CODES_ROOT = $("#GiftCodes_PlayerCodesClaimed");
const GIFT_CODE_REDEEM_STATE = $("#GiftCodes_RedeemState");
const GIFT_CODE_REDEEM_STATE_TEXT = GIFT_CODE_REDEEM_STATE.GetChild(1);
const NEW_GIFT_CODE_VALUE = $("#GiftCodes_RedeemUseField");
const COOLDOWN_FOR_REFRESH_CODES = 5;
const PLAYERS_FOR_GIFT_ROOT = $("#PlayersForGift_Root");
const UPDATE_CODES_BUTTON = $("#UpdateCodesButton");

const LOCAL_GIFT_ROOT = $("#SelectLocalGift");
LOCAL_GIFT_ROOT.is_show = false;
const LOCAL_GIFT_BUTTON = $("#LocalPlayersGift_SendButton");
const LOCAL_GIFT_ARROW = $("#ArrowRightLeft");

const GIFT_NOTIFICATION_FOR_ALL = $("#GiftCodeNotificationForAll");
const GIFT_NOTIFICATION_FOR_ALL_SENDER_NAME = $("#GiftCodeNotificationForAll_Sender");
const GIFT_NOTIFICATION_FOR_ALL_TARGET_NAME = $("#GiftCodeNotificationForAll_Target");

const GIFT_NOTIFICATION_FOR_TARGET = $("#SelfGiftNotificationRoot");
const GIFT_NOTIFICATION_FOR_TARGET_SENDER_NAME = $("#PlayerGiftSenderName");
const GIFT_NOTIFICATION_FOR_TARGET_SENDER_HERO = $("#PlayerGiftSenderHero");
const GIFT_NOTIFICATION_FOR_TARGET_ITEM = $("#SelfGiftNotification_ItemName");
