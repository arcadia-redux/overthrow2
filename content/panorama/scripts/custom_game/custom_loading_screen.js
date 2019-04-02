function StartSettings() 
{
	if (Game.GetMapInfo() == null) {
		$.Schedule(0.2, StartSettings);
  }
  else
  {
    if (Game.GetMapInfo().map_display_name == "")
    {
      $.Schedule(0.2, StartSettings);
    }
    else
    {
      if (Game.GetMapInfo().map_display_name == "desert_octet")
      {
        $("#SettingsList").visible = true;
      }
    }
  }
}

function UpdateVote(data) 
{
    var all = data.yes + data.no;
    $("#SchetYes").text = data.yes+"("+((data.yes/all)*100).toFixed(0)+"%)";
    $("#SchetNo").text = data.no+"("+((data.no/all)*100).toFixed(0)+"%)";
}

function Vote(vote) 
{
    GameEvents.SendCustomGameEventToServer("OPVote", {id: Game.GetLocalPlayerID(),vote: vote});
}

(function()
{
    $("#SettingsList").visible = false;
    StartSettings();
    GameEvents.Subscribe("updatevote", UpdateVote);
    //GameEvents.SendCustomGameEventToServer("GetKicks", {id: Game.GetLocalPlayerID()});
})();