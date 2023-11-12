using Toybox;
using Toybox.Lang;
using Toybox.WatchUi;

(:touchScreen) const fontValues = [0, 1, 2, 3, 4, 5, 6, 7, 8];
(:touchScreen) const fontNames = ["XTINY font", "TINY font", "SMALL font", "MEDIUM font", "LARGE font", "NUMBER_MILD font", "NUMBER_MEDIUM font", "NUMBER_HOT font", "NUMBER_THAI_HOT font"];

module Settings {

    class Menu extends WatchUi.Menu2 {

        private var _view;

        function initialize(view) {
            Menu2.initialize(null);
            _view = view.weak();
            Menu2.setTitle("Menu");

            // View all fonts
            Menu2.addItem(new WatchUi.MenuItem("View all fonts", null, 0, null));
            // View paddings
            Menu2.addItem(new WatchUi.MenuItem("View paddings", null, 1, null));
            // Configure paddings
            Menu2.addItem(new WatchUi.MenuItem("Configure paddings", view.currentView == 2 ? fontNames[view.currentFont] : null, 2, null));
        }

        function onSelect(index, menuItem) {
            var view = _view.get();
            if (index == 2) {
                var menu = new ConfigurePaddingsMenu(view, menuItem);
                WatchUi.pushView(menu, new MenuDelegate(menu), WatchUi.SLIDE_IMMEDIATE);
                return;
            }

            view.currentView = index;
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        }
    }

    class ConfigurePaddingsMenu extends SettingMenu {

        private var _view;

        function initialize(view, menuItem) {
            SettingMenu.initialize("Configure paddings", menuItem, fontValues, fontNames);
            _view = view.weak();
        }

        protected function updateValue(value) {
            var view = _view.get();
            view.currentFont = value;
            view.currentView = 2;
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        }
    }

    class SettingMenu extends WatchUi.Menu2 {

        private var _menuItem;
        private var _values;
        private var _names;

        function initialize(title, menuItem, values, names) {
            Menu2.initialize(null);
            Menu2.setTitle(title);
            _menuItem = menuItem.weak();
            _values = values;
            _names = names;
            for (var i = 0; i < values.size(); i++) {
                var value = values[i];
                var name = names[i];
                Menu2.addItem(new WatchUi.MenuItem(name, null, value, null));
            }
        }

        function onSelect(value, menuItem) {
            // Set new value
            updateValue(value);
            // Set parent sub label
            var index = _values.indexOf(value);
            if (_menuItem.stillAlive() && index >= 0) {
                var name = _names[index];
                _menuItem.get().setSubLabel(name);
            }

            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        }

        protected function updateValue(value) {
        }
    }

    class MenuDelegate extends WatchUi.Menu2InputDelegate {

        private var _menu;

        function initialize(menu) {
            Menu2InputDelegate.initialize();
            _menu = menu.weak();
        }

        function onSelect(menuItem) {
            if (_menu.stillAlive()) {
                _menu.get().onSelect(menuItem.getId(), menuItem);
            }
        }

        function onBack() {
            _menu = null;
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            return false;
        }
    }
}

