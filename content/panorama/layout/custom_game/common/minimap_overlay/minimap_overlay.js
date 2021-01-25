function HudStyleChanged() {
	$.Schedule(1, CreateMapOverlay);
}

function CreateMapOverlay() {
	const miniMap = FindDotaHudElement("minimap_block");
	const mapIsLarge = FindDotaHudElement("Hud").BHasClass("MinimapExtraLarge");
	const mapName = Game.GetMapInfo().map_display_name;
	const mapOverlayData = {
		ffa: [mapIsLarge ? 229 : 200], //height for source minimap
		demo: [mapIsLarge ? 229 : 200], //height for source minimap
	};
	if (miniMap.desiredlayoutheight > 1) {
		miniMap.style.opacityMask = "url('file://{resources}/images/custom_game/map_overlay/map_hide_top_part.png')";
		$("#MapOverlayCHC_Wrap").AddClass(mapName);
		if (mapOverlayData[mapName]) miniMap.style.height = mapOverlayData[mapName] + "px";
		const removeDotaElement = function (id) {
			const element = FindDotaHudElement(id);
			if (element) element.DeleteAsync(0);
		};
		removeDotaElement("HUDSkinMinimap");
		removeDotaElement("HUDSkinTopBarBG");
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
