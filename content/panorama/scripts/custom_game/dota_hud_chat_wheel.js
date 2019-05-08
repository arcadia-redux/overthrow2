//Players.GetPlayerSelectedHero(Game.GetLocalPlayerID()).substring(14)
var heronames = new Array(
    new Array("Abaddon","Alchemist","Ancient Apparition","Anti-Mage","Arc Warden","Axe","Bane","Batrider"),
    new Array("Beastmaster","Bloodseeker","Bounty Hunter","Brewmaster","Bristleback","Broodmother","Centaur Warrunner","Chaos Knight"),
    new Array("Chen","Clinkz","Clockwerk","Crystal Maiden","Dark Seer","Dark Willow","Dazzle","Death Prophet"),
    new Array("Disruptor","Doom","Dragon Knight","Drow Ranger","Earth Spirit","Earthshaker","Elder Titan","Ember Spirit"),
    new Array("Enchantress","Enigma","Faceless Void","Grimstroke","Gyrocopter","Huskar","Invoker","Io"),
    new Array("Jakiro","Juggernaut","Keeper of the Light","Kunkka","Legion Commander","Leshrac","Lich","Lifestealer"),
    new Array("Lina","Lion","Lone Druid","Luna","Lycan","Magnus","Mars","Medusa"),
    new Array("Meepo","Mirana","Monkey King","Morphling","Naga Siren","Nature's Prophet","Necrophos","Night Stalker"),
    new Array("Nyx Assassin","Ogre Magi","Omniknight","Oracle","Outworld Devourer","Pangolier","Phantom Assassin","Phantom Lancer"),
    new Array("Phoenix","Puck","Pudge","Pugna","Queen of Pain","Razor","Riki","Rubick"),
    new Array("Sand King","Shadow Demon","Shadow Fiend","Shadow Shaman","Silencer","Skywrath Mage","Slardar","Slark"),
    new Array("Sniper","Spectre","Spirit Breaker","Storm Spirit","Sven","Techies","Templar Assassin","Terrorblade"),
    new Array("Tidehunter","Timbersaw","Tinker","Tiny","Treant Protector","Troll Warlord","Tusk","Underlord"),
    new Array("Undying","Ursa","Vengeful Spirit","Venomancer","Viper","Visage","Warlock","Weaver"),
    new Array("Windranger","Winter Wyvern ","Witch Doctor","Wraith King","Zeus","","","")
);
var heronames2 = new Array(
    "abaddon",
    "alchemist",
    "ancient_apparition",
    "antimage",
    "arc_warden",
    "axe",
    "bane",
    "batrider",
    "beastmaster",
    "bloodseeker",
    "bounty_hunter",
    "brewmaster",
    "bristleback",
    "broodmother",
    "centaur",
    "chaos_knight",
    "chen",
    "clinkz",
    "rattletrap",
    "crystal_maiden",
    "dark_seer",
    "dark_willow",
    "dazzle",
    "death_prophet",
    "disruptor",
    "doom_bringer",
    "dragon_knight",
    "drow_ranger",
    "earth_spirit",
    "earthshaker",
    "elder_titan",
    "ember_spirit",
    "enchantress",
    "enigma",
    "faceless_void",
    "grimstroke",
    "gyrocopter",
    "huskar",
    "invoker",
    "wisp",
    "jakiro",
    "juggernaut",
    "keeper_of_the_light",
    "kunkka",
    "legion_commander",
    "leshrac",
    "lich",
    "life_stealer",
    "lina",
    "lion",
    "lone_druid",
    "luna",
    "lycan",
    "magnataur",
    "mars",
    "medusa",
    "meepo",
    "mirana",
    "monkey_king",
    "morphling",
    "naga_siren",
    "furion",
    "necrolyte",
    "night_stalker",
    "nyx_assassin",
    "ogre_magi",
    "omniknight",
    "oracle",
    "obsidian_destroyer",
    "pangolier",
    "phantom_assassin",
    "phantom_lancer",
    "phoenix",
    "puck",
    "pudge",
    "pugna",
    "queenofpain",
    "razor",
    "riki",
    "rubick",
    "sand_king",
    "shadow_demon",
    "nevermore",
    "shadow_shaman",
    "silencer",
    "skywrath_mage",
    "slardar",
    "slark",
    "sniper",
    "spectre",
    "spirit_breaker",
    "storm_spirit",
    "sven",
    "techies",
    "templar_assassin",
    "terrorblade",
    "tidehunter",
    "shredder",
    "tinker",
    "tiny",
    "treant",
    "troll_warlord",
    "tusk",
    "abyssal_underlord",
    "undying",
    "ursa",
    "vengefulspirit",
    "venomancer" ,
    "viper",
    "visage",
    "warlock",
    "weaver",
    "windrunner",
    "winter_wyvern",
    "witch_doctor",
    "skeleton_king",
    "zuus"
);
var mesarrs = new Array(
    "_laugh",
    "_thank",
    "_deny",
    "_1",
    "_2",
    "_3",
    "_4",
    "_5"
 );
var herostartnum = 80;
var herostartrings = 30;
var rings = new Array(
    new Array(//0 start
        new Array("#englishannouncer","#chineseannouncer","#russianannouncer","#more","#misc","#hero","#dotaplus2","#dotaplus"),
        new Array(false,false,false,false,false,false,false,false),
        new Array(6,2,3,4,11,1,7,8)
    ),
    new Array(//1 hero
        new Array("","","","","","","",""),
        new Array(true,true,true,true,true,true,true,true),
        new Array(0,0,0,0,0,0,0,0)
    ),
    new Array(//2 chineseannouncer
        new Array("#chineseannouncer2","#","#","#","#","#","#","#"),
        new Array(false,true,true,true,true,true,true,true),
        new Array(9,40,41,42,43,44,45,46)
    ),
    new Array(//3 russianannouncer
        new Array("#russianannouncer2","#bozhe_ti_posmotri","#zhil_do_konsta","#ay_ay_ay","#ehto_g_g","#eto_prosto_netchto","#krasavchik","#bozhe_kak_eto_bolno"),
        new Array(false,true,true,true,true,true,true,true),
        new Array(10,55,56,57,58,59,60,61)
    ),
    new Array(//4 more1
        new Array("#heros_a-b","#heros_b-c","#heros_c-d","#more","#heros_d-e","#heros_e-i","#heros_j-l","#heros_l-m"),
        new Array(false,false,false,false,false,false,false,false),
        new Array(13,14,15,12,16,17,18,19)
    ),
    new Array(//5 englishannouncer2
        new Array("#next_level","#","#","#","#","#","#","#"),
        new Array(true,true,true,true,true,true,true,true),
        new Array(32,33,34,35,36,37,38,39)
    ),
    new Array(//6 englishannouncer
        new Array("#englishannouncer2","#patience","#wow","#all_dead","#brutal","#disastah","#easiest_money","#echo_slama_jama"),
        new Array(false,true,true,true,true,true,true,true),
        new Array(5,25,26,27,28,29,30,31)
    ),
    new Array(//7 dotaplus2
        new Array("#dota_chatwheel_label_Headshake","#dota_chatwheel_label_Kiss","#dota_chatwheel_label_Ow","#dota_chatwheel_label_Snore","#dota_chatwheel_label_Bockbock","#dota_chatwheel_label_Crybaby","#dota_chatwheel_label_Sad_Trombone","#dota_chatwheel_label_Yahoo"),
        new Array(true,true,true,true,true,true,true,true),
        new Array(9,10,11,12,13,14,15,16)
    ),
    new Array(//8 dotaplus
        new Array("#dota_chatwheel_label_Applause","#dota_chatwheel_label_Crash_and_Burn","#dota_chatwheel_label_Crickets","#dota_chatwheel_label_Party_Horn","#dota_chatwheel_label_Rimshot","#dota_chatwheel_label_Charge","#dota_chatwheel_label_Drum_Roll","#dota_chatwheel_label_Frog"),
        new Array(true,true,true,true,true,true,true,true),
        new Array(1,2,3,4,5,6,7,8)
    ),
    new Array(//9 chineseannouncer2
        new Array("#","#","#","#","#","#","#","#"),
        new Array(true,true,true,true,true,true,true,true),
        new Array(47,48,49,50,51,52,53,54)
    ),
    new Array(//10 russianannouncer2
        new Array("#oy_oy_bezhat","#eto_nenormalno","#eto_sochno","","","","",""),
        new Array(true,true,true,false,false,false,false,false),
        new Array(62,63,64,65,66,67,68,69)
    ),
    new Array(//11 misc
        new Array("#","#dota_chatwheel_message_Sleighbells","#dota_chatwheel_message_Sparkling_Celebration","#dota_chatwheel_message_Greevil_Laughter","#dota_chatwheel_message_Frostivus_Magic","#dota_chatwheel_message_Ceremonial_Drums","#dota_chatwheel_message_Oink_Oink","#dota_chatwheel_message_Celebratory_Gong"),
        new Array(true,true,true,true,true,true,true,true),
        new Array(17,18,19,20,21,22,23,24)
    ),
    new Array(//12 more2
        new Array("#heros_m-n","#heros_n-p","#heros_p-r","#heros_w-z","#heros_s-s","#heros_s-t","#heros_t-u","#heros_u-w"),
        new Array(false,false,false,false,false,false,false,false),
        new Array(20,21,22,23,24,25,26,27)
    )
);
for ( var i = 0; i < heronames.length; i++ )
{
    var msg = heronames[i];
    var numsb = new Array(false,false,false,false,false,false,false,false);
    var numsi = new Array(herostartrings+i*8,herostartrings+i*8+1,herostartrings+i*8+2,herostartrings+i*8+3,herostartrings+i*8+4,herostartrings+i*8+5,herostartrings+i*8+6,herostartrings+i*8+7);
    rings[rings.length] = new Array(msg,numsb,numsi);
}
for ( var i = 0; i < heronames2.length; i++ )
{
    var msg = new Array();
    var numsb = new Array(true,true,true,true,true,true,true,true);
    var numsi = new Array();
    for ( var x = 0; x < 8; x++ )
    {
        msg[x] = "#dota_chatwheel_label_"+heronames2[i]+mesarrs[x];
        numsi[x] = herostartnum+(i*8)+x;
    }
    rings[herostartrings+i] = new Array(msg,numsb,numsi);
}
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
    if (nowselect != 0)
    {
        $("#PhrasesContainer").RemoveAndDeleteChildren();
        for ( var i = 0; i < 8; i++ )
        {
            $("#PhrasesContainer").BCreateChildren("<Button id='Phrase"+i+"' class='MyPhrases' onmouseactivate='OnSelect("+i+")' onmouseover='OnMouseOver("+i+")' onmouseout='OnMouseOut("+i+")' />");//class='Phrase HasSound RequiresHeroBadgeTier BronzeTier'
            $("#Phrase"+i).BLoadLayoutSnippet("Phrase");
            $("#Phrase"+i).GetChild(0).visible = rings[0][1][i];
            $("#Phrase"+i).GetChild(2).text = $.Localize(rings[0][0][i]);
        }
        nowselect = 0;
    }
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
    //var hero = Players.GetPlayerSelectedHero(Game.GetLocalPlayerID());
    //$("#HeroImage").heroname = hero;
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