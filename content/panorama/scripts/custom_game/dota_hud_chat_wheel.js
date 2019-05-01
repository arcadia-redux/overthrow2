var ring1text = new Array("#dota_chatwheel_label_"+Players.GetPlayerSelectedHero(Game.GetLocalPlayerID()).substring(14)+"_laugh","#test","#dota_chatwheel_label_"+Players.GetPlayerSelectedHero(Game.GetLocalPlayerID()).substring(14)+"_deny","#dota_chatwheel_label_"+Players.GetPlayerSelectedHero(Game.GetLocalPlayerID()).substring(14)+"_1","#dota_chatwheel_label_"+Players.GetPlayerSelectedHero(Game.GetLocalPlayerID()).substring(14)+"_2","#dota_chatwheel_label_"+Players.GetPlayerSelectedHero(Game.GetLocalPlayerID()).substring(14)+"_3","#dota_chatwheel_label_"+Players.GetPlayerSelectedHero(Game.GetLocalPlayerID()).substring(14)+"_4","#dota_chatwheel_label_"+Players.GetPlayerSelectedHero(Game.GetLocalPlayerID()).substring(14)+"_5");//"#dota_chatwheel_label_"+Players.GetPlayerSelectedHero(Game.GetLocalPlayerID()).substring(14)+"_thank"
var ring1voicon = new Array(true,false,true,true,true,true,true,true);
var ring1nums = new Array(0,1,2,3,4,5,6,7);
var ring1 = new Array(ring1text,ring1voicon,ring1nums);
var ring2text = new Array("#test1","#test2","#test3","#test4","#back","#test5","#test6","#test7");
var ring2voicon = new Array(true,true,true,true,false,true,true,true);
var ring2nums = new Array(0,0,0,0,0,0,0,0);
var ring2 = new Array(ring2text,ring2voicon,ring2nums);
var rings = new Array(ring1,ring2);
var nowselect = 0;

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
    var newnum = rings[nowselect][2][num];
    if (rings[nowselect][1][num])
    {
        GameEvents.SendCustomGameEventToServer("SelectVO", {id: Game.GetLocalPlayerID(),num: newnum});
    }
    else
    {
        $("#PhrasesContainer").RemoveAndDeleteChildren();
        for ( var i = 0; i < 8; i++ )
        {
            $("#PhrasesContainer").BCreateChildren("<Button id='Phrase"+i+"' class='MyPhrases' onmouseactivate='OnSelect("+i+")' onmouseover='OnMouseOver("+i+")' onmouseout='OnMouseOut("+i+")' />");//class='Phrase HasSound RequiresHeroBadgeTier BronzeTier'
            $("#Phrase"+i).BLoadLayoutSnippet("Phrase");
            $("#Phrase"+i).GetChild(0).visible = rings[newnum][1][i];
            $("#Phrase"+i).GetChild(2).text = $.Localize(rings[newnum][0][i]);
        }
        nowselect = newnum;
    }
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
    var hero = Players.GetPlayerSelectedHero(Game.GetLocalPlayerID());
    $("#HeroImage").heroname = hero;
    for ( var i = 0; i < 8; i++ )
    {
        $("#PhrasesContainer").BCreateChildren("<Button id='Phrase"+i+"' class='MyPhrases' onmouseactivate='OnSelect("+i+")' onmouseover='OnMouseOver("+i+")' onmouseout='OnMouseOut("+i+")' />");//class='Phrase HasSound RequiresHeroBadgeTier BronzeTier'
        $("#Phrase"+i).BLoadLayoutSnippet("Phrase");
        //if (i == 1 || i == 2 || i == 3)
        //    $("#Phrase"+i).GetChild(2).AddClass("MyText1");
        //if (i == 5 || i == 6 || i == 7)
        //    $("#Phrase"+i).GetChild(2).AddClass("MyText2");
        $("#Phrase"+i).GetChild(0).visible = rings[0][1][i];
        $("#Phrase"+i).GetChild(2).text = $.Localize(rings[0][0][i]);
    }
    Game.AddCommand("+WheelButton", StartWheel, "", 0);
    Game.AddCommand("-WheelButton", StopWheel, "", 0);
    $("#Wheel").visible = false;
    $("#Bubble").visible = false;
    $("#PhrasesContainer").visible = false;
})();