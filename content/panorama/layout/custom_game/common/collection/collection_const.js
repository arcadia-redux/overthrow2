const ITEMS_RARITY = {
	[1]: {
		sound: "Loot_Drop_Stinger_Uncommon",
		name: "common",
		color: "#a7b2ce",
	},
	[2]: {
		sound: "Loot_Drop_Stinger_Rare",
		name: "uncommon",
		color: "#5a92cd",
	},
	[3]: {
		sound: "Loot_Drop_Stinger_Mythical",
		name: "rare",
		color: "#4867f1",
	},
	[4]: {
		sound: "ui.treasure_01",
		name: "mythical",
		color: "#834af5",
	},
	[5]: {
		sound: "ui.treasure_02",
		name: "legendary",
		color: "#d033e2",
	},
	[6]: {
		sound: "ui.treasure_03",
		name: "immortal",
		color: "#cc9e35",
	},
	[7]: {
		sound: "collection.drop_arcana",
		name: "arcana",
		color: "#a3d857",
	},
	[99]: {
		sound: "Loot_Drop_Stinger_Uncommon",
		name: "unique",
		color: "#d80f00",
	},
};
const SOUND_DUPLICATE_ITEM = "collection.duplicate_item";

const ITEMS_TYPES = [
	"Masteries",
	"Treasures",
	"Auras",
	"HeroSkins",
	"Pets",
	"KillEffects",
	"Barrages",
	"CosmeticAbilities",
	"DuelEffects",
	"BetEffects",
	"Effigies",
	"SpellEffects",
	"Items",
	"ChatWheels",
	"Interfaces",
	"Sprays",
	"Specials",
];

const PERMANENT_SHOW_TYPES = ["Masteries", "Treasures"];

const EQUIPPED = 0;
const EQUIP = 1;
const OPEN_TREASURE = 2;
const ITEM_OWNED = 3;

const ITEMS_EQUIP_STATE = {
	[0]: "equipped",
	[1]: "equip",
	[2]: "open_treasure",
	[3]: "item_owned",
};

const PLAYER_BOOST_STATE = {
	[0]: "no_boost",
	[1]: "base_booster",
	[2]: "golden_booster",
};

const TOOLTIPS_WITH_VALUES = { DOTAU_MMR: "mmr_min", Coins: "cost", Money: "cost" };

const SOURCES_WEIGHT = ["SupporterState_2", "SupporterState_1", "Money", "Other", "Coins", "DOTAU_MMR", "Treasure"];
const TREASURES_WEIGHT = [
	"treasure_starter",
	"treasure_collection_1",
	"treasure_emotes_basic",
	"treasure_emotes_deluxe",
	"treasure_hallowed_shimmer",
	"treasure_winter",
];

const SORT_FUNCTIONS = {
	rarity_up: function (a, b) {
		let result = 0;
		if (a.rarity < b.rarity) {
			result = 1;
		} else {
			if (a.rarity != b.rarity) {
				result = -1;
			}
		}
		return result;
	},
	rarity_down: function (a, b) {
		let result = 0;
		if (a.rarity > b.rarity) {
			result = 1;
		} else {
			if (a.rarity != b.rarity) {
				result = -1;
			}
		}
		return result;
	},
	default: function (a, b) {
		let result = 0;
		if (a.default < b.default) {
			result = 1;
		} else {
			if (a.default != b.default) {
				result = -1;
			}
		}
		return result;
	},
};

const TIMES_MULTIPLAYER = {
	sec: 86400,
	min: 1440,
	hour: 24,
	day: 1,
};

const ITEMS_IN_WHEEL_INIT = 10;

const ITEMS_BUY_COINS_SOUNDS = {
	true: "Item.PickUpRingShop",
	false: "ui.contract_fail",
};
const ITEM_CHANGE_EQUIP_STATE_COOLDOWN = 0.5;
const MAP_NAME = Game.GetMapInfo().map_display_name;
