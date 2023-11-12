using Toybox.Lang;
using Toybox.System;
using Toybox.Application;
using Toybox.WatchUi;


class InputDelegate extends WatchUi.BehaviorDelegate {

    private var _eventHandler;

    function initialize(eventHandler) {
        InputDelegate.initialize();
        _eventHandler = eventHandler.weak();
    }

    // Detect Menu behavior
    function onMenu() {
       return _eventHandler.get().openMenu();
    }

    // Detect Menu button input
    function onKey(keyEvent) {
        var result = _eventHandler.stillAlive()
            ? _eventHandler.get().onKey(keyEvent.getKey())
            : false;
        if (result) {
            WatchUi.requestUpdate();
        }

        return result;
    }


    function onTap(clickEvent) {
        var result = _eventHandler.stillAlive()
            ? _eventHandler.get().onTap(clickEvent.getCoordinates())
            : false;
        if (result) {
            WatchUi.requestUpdate();
        }
        
        return result;
    }
}

(:glance)
class StaticGlanceView extends WatchUi.GlanceView {

    function initialize() {
        GlanceView.initialize();
    }

    function onUpdate(dc) {
        var deviceSettings = System.getDeviceSettings();
        var bgColor = deviceSettings has :isNightModeEnabled && !deviceSettings.isNightModeEnabled
            ? 0xFFFFFF /* COLOR_WHITE */
            : 0x000000 /* COLOR_BLACK */;
        var fgColor = bgColor == 0x000000 /* COLOR_BLACK */
            ? 0xFFFFFF /* COLOR_WHITE */
            : 0x000000 /* COLOR_BLACK */;
        var width = dc.getWidth();
        var height = dc.getHeight();
        dc.setColor(fgColor, bgColor);
        dc.clear();
        //dc.setColor(0xFFFFFF /* COLOR_WHITE */, -1 /* COLOR_TRANSPARENT */);
        dc.drawText(width / 2, height / 2, 2, "Font paddings", 1 /* TEXT_JUSTIFY_CENTER */ | 4 /* TEXT_JUSTIFY_VCENTER */);
    }
    
    function onStop() {
    }
}

(:glance)
class FontPaddingsApp extends Application.AppBase {

    private var _view;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
        _view.onStop();
    }

    // Return the initial view of your application here
    function getInitialView() {
        if (_view == null) {
            _view = new FontPaddingsView();
        }

        return [ _view, new InputDelegate(_view) ];
    }

    function getGlanceView() {
        if (_view == null) {
            _view = new StaticGlanceView();
        }

        return [_view];
    }
}
