"use strict";

var skip = false

function Selection_New(msg)
{
    var entities = msg.entities
    for (var i in entities) {
        if (i==1)
            GameUI.SelectUnit(entities[i], false) //New
        else
            GameUI.SelectUnit(entities[i], true) //Add
    };
}

function Selection_Add(msg)
{
    var entities = msg.entities
    for (var i in entities) {
        GameUI.SelectUnit(entities[i], true)
    };
}

function Selection_Remove(msg)
{
    var remove_entities = msg.entities
    var selected_entities = GetSelectedEntities();
    for (var i in remove_entities) {
        var index = selected_entities.indexOf(remove_entities[i])
        if (index > -1)
            selected_entities.splice(index, 1)
    };

    if (selected_entities.length == 0)
    {
        Selection_Reset()
        return
    }

    for (var i in selected_entities) {
        if (i==0)
            GameUI.SelectUnit(selected_entities[i], false) //New
        else
            GameUI.SelectUnit(selected_entities[i], true) //Add
    };
}

function Selection_Reset(msg)
{
    var playerID = Players.GetLocalPlayer()
    var heroIndex = Players.GetPlayerHeroEntityIndex(playerID)
    GameUI.SelectUnit(heroIndex, false)
}

function GetSelectedEntities(msg) {
    return Players.GetSelectedEntities(Players.GetLocalPlayer());
}

(function () {
    GameEvents.Subscribe( "selection_new", Selection_New);
    GameEvents.Subscribe( "selection_add", Selection_Add);
    GameEvents.Subscribe( "selection_remove", Selection_Remove);
})();