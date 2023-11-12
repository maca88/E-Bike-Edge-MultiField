using Toybox.WatchUi;
using Toybox.Lang;
using Toybox.Application.Properties as Properties;

const useSystemFonts = false;
const fontPadding = 3;

class FontPaddingsView extends WatchUi.View {

    private var _insideMenu = false;

    private var _counter = 0;
    private var _devicePartNumber;
    private var _paddingLineColor;
    private var _stringText =  ".7 kHW";
    private var _numberText =  ".8%";
    private var _currentPage = 0;
    private var _paddings;
    private var _monochrome;
    private var _language;
    private var _fontPaging;

    public var currentView = 0;
    public var currentFont = 0;

    function initialize() {
        DataField.initialize();
        _language = WatchUi.loadResource(Rez.Strings.LANG);
        var settings = WatchUi.loadResource(Rez.JsonData.Settings);
        _monochrome = settings[0];
        setupPaddings();
    }

    function openMenu() {
        if (_insideMenu) {
            return false;
        }

        var menu = new Settings.Menu(self);
        WatchUi.pushView(menu, new Settings.MenuDelegate(menu), WatchUi.SLIDE_IMMEDIATE);
        _insideMenu = true;

        return true;
    }

    function onTap(location) {
         return false;
    }

    function onKey(key) {
        if (currentView == 0) {
            if (key == WatchUi.KEY_UP && _currentPage > 0) {
                _currentPage--;
                return true;
            } else if (key == WatchUi.KEY_DOWN && _currentPage + 1 < _fontPaging.size()) {
                _currentPage++;
                return true;
            }
        }

        if (currentView == 2) {
            if (key == WatchUi.KEY_DOWN) {
                _paddings[currentFont]++;
                return true;
            } else if (key == WatchUi.KEY_UP && _paddings[currentFont] > 0) {
                _paddings[currentFont]--;
                return true;
            }
        }

        return false;
    }

    function onShow() {
        if (_insideMenu) {
            _insideMenu = false;
            WatchUi.requestUpdate();
            return;
        }
    }

    function onHide() {
        if (_insideMenu) {
            return;
        }
    }

    function onStop() {
        Properties.setValue("TP", getPaddingsValue(_paddings).toString());
    }

    // Update the view
    function onUpdate(dc) {
        if (_fontPaging == null) {
            preCalculate(dc);
        }

        var deviceSettings = System.getDeviceSettings();
        var bgColor = deviceSettings has :isNightModeEnabled && !deviceSettings.isNightModeEnabled
            ? Graphics.COLOR_WHITE
            : Graphics.COLOR_BLACK;
        var fgColor = Graphics.COLOR_WHITE;
        if (bgColor == Graphics.COLOR_WHITE) {
            fgColor = Graphics.COLOR_BLACK;
        }

        dc.setColor(fgColor, bgColor);
        dc.clear();

        if (currentView == 0) {
            drawFontsPage(dc, fgColor);
        } else if (currentView == 1) {
            drawTopPaddings(dc);
        } else if (currentView == 2 /* Configure font */) {
            var height = dc.getHeight();
            var width = dc.getWidth();
            drawFont(currentFont, width / 2, height / 2, dc, fgColor);
        }
    }

    private function drawTopPaddings(dc) {
        var height = dc.getHeight();
        var width = dc.getWidth();
        var text = "";
        var totalFonts = _paddings.size();
        for (var i = 0; i < totalFonts; i++) {
            text += _paddings[i].toString();
            if ((i + 1) < totalFonts) {
                text += ", ";
            }
        }

        var y = height / 2;
        dc.drawText(width / 2, y, 2, text, Graphics.TEXT_JUSTIFY_CENTER);

        y -= (dc.getFontHeight(2) + 10);
        dc.drawText(width / 2, y, 2, _language, Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawFontsPage(dc, fgColor) {
        var page = _fontPaging[_currentPage];
        for (var i = 0; i < page.size(); i++) {
            var data = page[i];
            drawFont(data[0], data[1], data[2], dc, fgColor);
        }
    }

    private function drawFont(font, x, y, dc, fgColor) {
        var text = font.toString() + (font > 4 ? _numberText : _stringText);
        var dim = dc.getTextDimensions(text, font);
        var fontX = x - (dim[0] / 2);
        setDrawColor(dc, fgColor);
        dc.drawText(fontX, y, font, text, Graphics.TEXT_JUSTIFY_LEFT);

        setDrawColor(dc, Graphics.COLOR_RED);
        dc.drawRectangle(fontX, y, dim[0], dim[1]);

        // Draw paddings
        setDrawColor(dc, Graphics.COLOR_BLUE);
        var py = y + dim[1] - dc.getFontDescent(font);
        dc.drawLine(fontX, py, fontX + dim[0], py);
        
        if (_paddings != null) {
            setDrawColor(dc, Graphics.COLOR_DK_GREEN);
            py = y + _paddings[font];
            dc.drawLine(fontX, py, fontX + dim[0], py);
        }

        return dim;
    }

    private function preCalculate(dc) {
        var height = dc.getHeight();
        var width = dc.getWidth();
        var x = width / 2;
        var y = fontPadding;

        var paging = [];
        var currentPage = [];
        for (var font = 0; font < 9; font++) {
            var text = font.toString() + (font > 4 ? _numberText : _stringText);
            var dim = dc.getTextDimensions(text, font);
            var fontHeight = dim[1];
            if ((y + fontHeight) >= height) {
                paging.add(currentPage);
                currentPage = [];
                y = fontPadding;
            }

            currentPage.add([font, x, y]);
            y += (fontHeight + fontPadding);
        }

        if (currentPage.size() > 0) {
            paging.add(currentPage);
        }

        _fontPaging = paging;
    }

    (:readOnly)
    private function setupPaddings() {
        var paddings = getPaddings();
        if (paddings == null || paddings[_language] == null) {
            return;
        }

        _paddings = paddings[_language];
        System.println("Language=" + _language + " Top paddings=" + _paddings);
        var keys = paddings.keys();
        for (var i = 0; i < keys.size(); i++) {
            var language = keys[i];
            var value = getPaddingsValue(paddings[language]);

            System.println("Language=" + language + " Top paddings value=" + value);
        }
    }

    (:write)
    private function setupPaddings() {
        var value = Properties.getValue("TP");
        var paddings;
        if (value != null && value.length() > 0) {
            var long = value.toLong();
            paddings = [];
            for (var j = 0; j < 9; j++) {
                paddings.add((long >> (7 * j)) & 0x7F);
            }
        } else {
            paddings = WatchUi.loadResource(Rez.JsonData.FontTopPaddings);
        }

        _paddings = paddings;
    }

    (:device)
    private function getPaddings() {
        return WatchUi.loadResource(Rez.JsonData.DeviceFontPaddings);
    }

    (:simulator)
    private function getPaddings() {
        return WatchUi.loadResource(Rez.JsonData.SimulatorFontPaddings);
    }

    private function getPaddingsValue(paddings) {
        var value = 0L;
        for (var j = 0; j < 9; j++) {
            value |= (paddings[j].toLong() << (7 * j));
        }

        return value;
    }

    private function setDrawColor(dc, color) {
        dc.setColor(_monochrome ? Graphics.COLOR_BLACK : color, Graphics.COLOR_TRANSPARENT);
    }
}
