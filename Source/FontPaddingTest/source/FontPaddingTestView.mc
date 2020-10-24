using Toybox.WatchUi;
using Toybox.Lang;

const useSystemFonts = false;
const startFont = useSystemFonts ? 17 : 8;

class FontPaddingTestView extends WatchUi.DataField {

    private var _counter = 0;
    private var _devicePartNumber;
    private var _paddingLineColor;
    private var _stringText =  ".7 kHW";
    private var _numberText =  ".8%";
    private var _currentFont = startFont;
    private var _paddings;
    private var _monochrome;

    function initialize() {
        DataField.initialize();
        var language = WatchUi.loadResource(Rez.Strings.LANG);
        var settings = WatchUi.loadResource(Rez.JsonData.Settings);
        _monochrome = settings[0];
        var paddings = getPaddings();
        if (paddings == null || paddings[language] == null) {
            return;
        }

        _paddings = paddings[language];
        System.println("Language=" + language + " Top paddings=" + _paddings);
        var keys = paddings.keys();
        for (var i = 0; i < keys.size(); i++) {
            language = keys[i];
            var languagePaddings = paddings[language];
            var value = 0L;
            for (var j = 0; j < 9; j++) {
                value |= (languagePaddings[j].toLong() << (7 * j));
            }

            System.println("Language=" + language + " Top paddings value=" + value);
        }
    }

    (:device)
    private function getPaddings() {
        return WatchUi.loadResource(Rez.JsonData.DeviceFontPaddings);
    }

    (:simulator)
    private function getPaddings() {
        return WatchUi.loadResource(Rez.JsonData.SimulatorFontPaddings);
    }

    function onLayout(dc) {
        for (var i = 0; i < 18; i++) {
            System.println("Font=" + i + " Height=" + dc.getFontHeight(i) + " FontDescent=" + dc.getFontDescent(i) + " FontAscent=" + dc.getFontAscent(i));
        }
    }

    // Update the view
    function onUpdate(dc) {
        var bgColor = getBackgroundColor();
        var fgColor = Graphics.COLOR_WHITE;

        if (bgColor == Graphics.COLOR_WHITE) {
            fgColor = Graphics.COLOR_BLACK;
        }

        dc.setColor(fgColor, bgColor);
        dc.clear();

        var height = dc.getHeight();
        var width = dc.getWidth();
        var font = _currentFont;
        var fontOffset = useSystemFonts ? 9 : 0;
        var padding = 3;
        var y = padding;
        var x = width / 2;
        while (font >= 0 && (y + dc.getFontHeight(font)) < height) {
            var text = font.toString() + (font > (4 + fontOffset) ? _numberText : _stringText);
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
                py = y + _paddings[font - fontOffset];
                dc.drawLine(fontX, py, fontX + dim[0], py);
            }

            y += (dim[1] + padding);
            font -= 1;
        }

        _counter = (_counter + 1) % ((_currentFont - font) * 2);
        if (_counter == 0) {
            _currentFont = font < fontOffset ? startFont : font;
        }
    }

    private function setDrawColor(dc, color) {
        dc.setColor(_monochrome ? Graphics.COLOR_BLACK : color, Graphics.COLOR_TRANSPARENT);
    }
}
