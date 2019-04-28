function StartWheel() {
    $("#Wheel").visible = true;
    $("#Bubble").visible = true;
    $("#PhrasesContainer").visible = true;
}

function StopWheel() {
    $("#Wheel").visible = false;
    $("#Bubble").visible = false;
    $("#PhrasesContainer").visible = false;
}

function OnSelect(num) {
    //$.Msg(num);
    GameEvents.SendCustomGameEventToServer("SelectVO", {id: Game.GetLocalPlayerID(),num: num});
}

function OnMouseOver(num) {
    //$.Msg(num);
    $( "#WheelPointer" ).RemoveClass( "Hidden" );
    $( "#Arrow" ).RemoveClass( "Hidden" );
    for ( var i = 0; i < 8; i++ )
    {
        if ($("#Wheel").BHasClass("ForWheel"+i))
            $( "#Wheel" ).RemoveClass( "ForWheel"+i );
    }
    $( "#Wheel" ).AddClass( "ForWheel"+num );
}

function OnMouseOut(num) {
    //$.Msg(num);
    $( "#WheelPointer" ).AddClass( "Hidden" );
    $( "#Arrow" ).AddClass( "Hidden" );
}

(function()
{
    var postfixes = new Array("laugh","thank","deny","1","2","3","4","5");
    var hero = Players.GetPlayerSelectedHero(Game.GetLocalPlayerID());
    $("#HeroImage").heroname = hero;
    hero = hero.substring(14);
    for ( var i = 0; i < 8; i++ )
    {
        $("#PhrasesContainer").BCreateChildren("<Button id='Phrase"+i+"' class='MyPhrases' onmouseactivate='OnSelect("+i+")' onmouseover='OnMouseOver("+i+")' onmouseout='OnMouseOut("+i+")' />");//class='Phrase HasSound RequiresHeroBadgeTier BronzeTier'
        $("#Phrase"+i).BLoadLayoutSnippet("Phrase");
        //if (i == 1 || i == 2 || i == 3)
        //    $("#Phrase"+i).GetChild(2).AddClass("MyText1");
        //if (i == 5 || i == 6 || i == 7)
        //    $("#Phrase"+i).GetChild(2).AddClass("MyText2");
        $("#Phrase"+i).GetChild(2).text = $.Localize("#dota_chatwheel_label_"+hero+"_"+postfixes[i]);
    }
    Game.AddCommand("+WheelButton", StartWheel, "", 0);
    Game.AddCommand("-WheelButton", StopWheel, "", 0);
    $("#Wheel").visible = false;
    $("#Bubble").visible = false;
    $("#PhrasesContainer").visible = false;
})();