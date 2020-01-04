function DebugPrintData(data)
{
    if (data == undefined || data == null || data == "") {return}
	var msg = data.msg
	if (msg == undefined || msg == null || msg == "") {return}
	if (typeof msg == "string") {
	    var arr = msg.split(" ")
        msg = ""
        arr.forEach(function(item, i, arr) {
          msg = msg + $.Localize(item) + " "
        });

    $.Msg(msg)
	}
}

(function()
{
	GameEvents.Subscribe( "DebugMessage", DebugPrintData)
})();

