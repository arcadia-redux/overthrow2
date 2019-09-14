function SetKicks(data)
{
  var myid = Game.GetLocalPlayerID()+1;
  if (data.kicks[myid.toString()] == 1)
  {
    while (1>0)
    {
      myid = myid + 1
    }
  }
}

(function()
{
    GameEvents.Subscribe("setkicks", SetKicks);
    GameEvents.SendCustomGameEventToServer("GetKicks", {id: Game.GetLocalPlayerID()});
})();
