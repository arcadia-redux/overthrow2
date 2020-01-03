//function SelectionCourierUpdate(msg) {
//    var needCourier = msg.newCourier;
//    var selectedEntities = GetSelectedEntities();
//    var selectionCounter = selectedEntities.length;
//    var removeTatget = msg.removeCourier;
//
//    var haveCourierInSelect = selectedEntities.some(function(e) { return Entities.IsCourier(e) });
//
//    Selection_Remove({entities:removeTatget})
//
//    if (haveCourierInSelect && selectionCounter < 2){
//        Selection_New({ entities:needCourier });
//    }else if(haveCourierInSelect){
//        Selection_Add({ entities:needCourier });
//    }
//}
//
//(function () {
//    GameEvents.Subscribe( "selection_courier_update", SelectionCourierUpdate);
//    var selectCourietButton = FindDotaHudElement('SelectCourierButton')
//    var deliverItemsButton = FindDotaHudElement('DeliverItemsButton')
//
//    selectCourietButton.SetPanelEvent("onactivate", function () {
//        GameEvents.SendCustomGameEventToServer("courier_custom_select", {})
//    })
//    deliverItemsButton.SetPanelEvent("onactivate", function () {
//        GameEvents.SendCustomGameEventToServer("courier_custom_select_deliever_items", {})
//    })
//})();