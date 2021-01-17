const PAYMENT_VALUES = {
	base_booster: {
		price: "8.50",
	},
	golden_booster: {
		price: "34.00",
	},
};

const EXCHANGE_RATE = {
	//By one dollar
	schinese: 7,
};

function GetLocalPrice(basePrice) {
	if (EXCHANGE_RATE[$.Language()]) basePrice = Math.round(basePrice * EXCHANGE_RATE[$.Language()] * 100) / 100;
	return basePrice;
}
