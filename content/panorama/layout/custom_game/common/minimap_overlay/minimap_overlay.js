function HudStyleChanged() {
	$.Schedule(1, CreateMapOverlay);
}

const ADDON_NAME_BY_MAP_NAME = {
	core_quartet: "overthrow2",
	desert_octet: "overthrow2",
	desert_quintet: "overthrow2",
	forest_solo: "overthrow2",
	mines_trio: "overthrow2",
	temple_quartet: "overthrow2",
	temple_sextet: "overthrow2",
	desert_duo: "overthrow2",
	dota: "dota12v12",
	dota_tournament: "dota12v12",
};

function CreateMapOverlay() {
	const miniMap = FindDotaHudElement("minimap_block");
	const mapName = Game.GetMapInfo().map_display_name;
	const mapIsLarge = FindDotaHudElement("Hud").BHasClass("MinimapExtraLarge");
	if (miniMap.desiredlayoutheight > 1) {
		if (ADDON_NAME_BY_MAP_NAME[mapName] != undefined)
			$("#MapOverlayDotaU_Wrap").AddClass(ADDON_NAME_BY_MAP_NAME[mapName]);
		const removeDotaElement = function (id) {
			const element = FindDotaHudElement(id);
			if (element) element.DeleteAsync(0);
		};
		removeDotaElement("HUDSkinMinimap");
		removeDotaElement("HUDSkinTopBarBG");
		FindDotaHudElement("GlyphScanContainer").style.marginLeft = mapIsLarge ? "283px" : "247px";
	} else {
		$.Schedule(1, function () {
			CreateMapOverlay();
		});
	}
}

(function () {
	CreateMapOverlay();
	$.RegisterEventHandler("PanelStyleChanged", FindDotaHudElement("minimap_block"), HudStyleChanged);
})();
