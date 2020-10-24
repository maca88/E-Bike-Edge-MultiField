using Toybox.Application;
using Toybox.WatchUi;

class EBikeMultiFieldApp extends Application.AppBase {
    private var _multiField;

    function initialize() {
        _multiField = new EBikeMultiField();
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
        _multiField.onStart();
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
        _multiField.onStop();
    }

    function onSettingsChanged() {
        _multiField.onSettingsChanged();
    }

    // Return the initial view of your application here
    function getInitialView() {
        return [ _multiField];
    }
}