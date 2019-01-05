"use strict";

function UpdateTimer( data )
{
	//$.Msg( "UpdateTimer: ", data );
	//var timerValue = Game.GetDOTATime( false, false );

	//var sec = Math.floor( timerValue % 60 );
	//var min = Math.floor( timerValue / 60 );

	//var timerText = "";
	//timerText += min;
	//timerText += ":";

	//if ( sec < 10 )
	//{
	//	timerText += "0";
	//}
	//timerText += sec;

	var timerText = "";
	timerText += data.timer_minute_10;
	timerText += data.timer_minute_01;
	timerText += ":";
	timerText += data.timer_second_10;
	timerText += data.timer_second_01;

	$( "#Timer" ).text = timerText;

	//$.Schedule( 0.1, UpdateTimer );
}

function ShowTimer( data )
{
	$( "#Timer" ).AddClass( "timer_visible" );
}

function AlertTimer( data )
{
	$( "#Timer" ).AddClass( "timer_alert" );
}

function HideTimer( data )
{
	$( "#Timer" ).AddClass( "timer_hidden" );
}

function P3Click( data )
{
	if (data == true)
	{
		GameEvents.SendCustomGameEventToServer( "P3ButtonClick", {});
	}
	$( "#P3Button" ).AddClass( "OffP3Button" );
}

(function()
{
	// We use a nettable to communicate victory conditions to make sure we get the value regardless of timing.
	SubscribeToNetTableKey("game_state", "victory_condition", function(data) {
        if (data) {
            $("#VictoryPoints").text = data.kills_to_win;
        }
	});

	SubscribeToNetTableKey("game_state", "players_who_acted_on_victory_condition", function(data) {
		if (data) {
			var localPlayedAlreadyAddedToVictoryCondition = !!data[Game.GetLocalPlayerID()];

			if (localPlayedAlreadyAddedToVictoryCondition) {
                $( "#P3Button" ).visible = false;
			}
		}
	});

    GameEvents.Subscribe( "countdown", UpdateTimer );
    GameEvents.Subscribe( "show_timer", ShowTimer );
    GameEvents.Subscribe( "timer_alert", AlertTimer );
	GameEvents.Subscribe( "overtime_alert", HideTimer );
	GameEvents.Subscribe( "OffP3Button", P3Click );
	//UpdateTimer();
})();

