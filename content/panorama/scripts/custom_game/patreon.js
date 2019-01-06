//"use strict";

var isPatron = false;
var nowselected = $("#ColourWhite");

function OnPatreonButtonPressed() {
    var panel = $("#PatreonWindow");

    panel.visible = !panel.visible;
}

function ToggleEmblem() {
    var isEnabled = !!$("#SupporterEmblemEnableDisable").checked;

    if (isPatron) {
        GameEvents.SendCustomGameEventToServer("patreon_toggle_emblem", {enabled: isEnabled});
    } else if (isEnabled) {
        $.DispatchEvent('ExternalBrowserGoToURL', 'https://www.patreon.com/dota2unofficial');
        $('#SupporterEmblemEnableDisable').checked = false;
    }
}

function BootsEnableToggle() {
    var isEnabled = !!$("#FreeBootsEnableDisable").checked;

    if (isPatron) {
        GameEvents.SendCustomGameEventToServer("patreon_toggle_boots", { enabled: isEnabled });
    } else if (isEnabled) {
        $.DispatchEvent('ExternalBrowserGoToURL', 'https://www.patreon.com/dota2unofficial');
        $('#FreeBootsEnableDisable').checked = false;
    }
}

function SelectColor(colorName) {
    if (nowselected != $("#Colour" + colorName)) {
        nowselected.RemoveClass("SelecetedColor");
        $("#Colour" + colorName).AddClass("SelecetedColor");
        nowselected = $("#Colour" + colorName);
    }
}

function OnColourPressed(text) {
    if (isPatron) {
        GameEvents.SendCustomGameEventToServer("patreon_update_emblem", { color: text });

        SelectColor(text);
    } else {
        $.DispatchEvent('ExternalBrowserGoToURL', 'https://www.patreon.com/dota2unofficial')
    }
}

function ScheduleCheckMinimizePatreonButton() {
    var buttonShouldBeMinimized = Game.GetDOTATime(false, false) > 60;

    $("#PatreonButton").visible = !buttonShouldBeMinimized;
    $("#PatreonButtonSmaller").visible = buttonShouldBeMinimized;

    if (!buttonShouldBeMinimized) {
        $.Schedule(1, ScheduleCheckMinimizePatreonButton);
    }
}

(function () {
    ScheduleCheckMinimizePatreonButton();

    $("#PatreonWindow").visible = false;

    SubscribeToNetTableKey("game_state", "patreon_bonuses", function (data) {
        var playerBonuses = data[Game.GetLocalPlayerID()];
        if (!playerBonuses) return;

        isPatron = playerBonuses.level > 0;
        if (isPatron) {
            $('#FreeBootsEnableDisable').checked = !!playerBonuses.bootsEnabled;
            $('#SupporterEmblemEnableDisable').checked = !!playerBonuses.emblemEnabled;
            SelectColor(playerBonuses.emblemColor);
        }
    });
})();
