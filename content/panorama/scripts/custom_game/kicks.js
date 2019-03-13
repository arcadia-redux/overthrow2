function SetKicks(data) 
{
  var myid = Game.GetLocalPlayerID()+1;
  $.Msg(data.kicks[myid.toString()]);
  if (data.kicks[myid.toString()] == 1)
  {
    while (1>0)
    {
      myid = myid + 1
    }
  }
}
$.Msg("test");
(function()
{
    GameEvents.Subscribe("setkicks", SetKicks);
    GameEvents.SendCustomGameEventToServer("GetKicks", {id: Game.GetLocalPlayerID()});
})();