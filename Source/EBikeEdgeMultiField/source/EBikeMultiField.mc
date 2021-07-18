using Toybox.WatchUi;
using Toybox.Application.Properties as Properties;

(:gpsMap)
const testString = "88.88";

(:noGpsMap)
const testString = "188.88";


class EBikeMultiField extends WatchUi.DataField {
    private var _errorCode; // The current error code of the datafield
    private var _fields; // Precalcuated fields labels, values and units to draw
    private var _separators; // Precalculated separator lines
    private var _sensor; // LEV sensor
    private var _temperatureNames; // Names of motor/battery temperatures
    private var _onOffNames; // Names for ON and OFF
    private var _assistModes; // Names of assist modes
    private var _manufacturerId; // The LEV manufacturer id
    private var _defaultValues; // Array of default values
    private var _colorScreen; // Whether the screen is colored
    private var _padding; // Default padding
    private var _separatorColor; // Color for the separators

    function initialize() {
        DataField.initialize();
        _sensor = new EBikeSensor();
    }

    // Called from EBikeMultiFieldApp.onSettingsChanged()
    function onSettingsChanged() {
        _fields = null; // Force to precalculate again
    }

    // Called from EBikeMultiFieldApp.onStart()
    function onStart() {
        var errorCode = null;
        try {
            if (!_sensor.open()) {
                errorCode = 2;
            }
        } catch(e instanceof Ant.UnableToAcquireChannelException) {
            errorCode = 1;
        }

        _errorCode = errorCode;
    }

    // Called from EBikeMultiFieldApp.onStop()
    function onStop() {
        if (_sensor != null) {
            _sensor.close();
            _sensor = null;
        }
    }

    // Overrides DataField.onLayout
    function onLayout(dc) {
        _fields = null; // Force to precalculate again
    }

    // Overrides DataField.onUpdate
    function onUpdate(dc) {
        var sensor = _sensor;
        var lastMessageTime = sensor.lastMessageTime;
        // In case the device goes to sleep for a longer period of time the channel will be closed by the system
        // and EBikeSensor.onMessage won't be called anymore. In such case release the current channel and open
        // a new one. To detect a sleep we check whether the last message was received more than the value of
        // the option "searchTimeoutLowPriority" ago, which in our case is set to 15 seconds.
        if (lastMessageTime > 0 && System.getTimer() - lastMessageTime > 20000) {
            _sensor.close();
            onStart();
            onSettingsChanged();
        }

        if (_fields == null) {
            preCalculate(dc, sensor);
        }

        var backgroundColor = getBackgroundColor();
        var foregroundColor = 0x000000; /* COLOR_BLACK */
        if (backgroundColor == 0x000000 /* COLOR_BLACK */) {
            foregroundColor = 0xFFFFFF; /* COLOR_WHITE */
        }

        dc.setColor(foregroundColor, backgroundColor);
        dc.clear();

        if (_errorCode != null) {
            dc.setColor(_colorScreen ? 0xFF0000 /* COLOR_RED */ : 0x000000 /* COLOR_BLACK */, -1 /* COLOR_TRANSPARENT */);
            dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, 4, "Error " + _errorCode, 1 /* TEXT_JUSTIFY_CENTER */ | 4 /* TEXT_JUSTIFY_VCENTER */);
            return;
        }

        // Draw the grid layout
        var separators = _separators;
        if (separators != null) {
            dc.setColor(_separatorColor, -1 /* COLOR_TRANSPARENT */);
            dc.setPenWidth(_colorScreen ? 2 : 1); // Edge 130 has one pixel separator lines
            for (var i = 0; i < separators.size(); i = i + 4) {
                dc.drawLine(separators[i], separators[i + 1], separators[i + 2], separators[i + 3]);
            }
        }

        dc.setColor(foregroundColor, -1 /* COLOR_TRANSPARENT */);

        var units;
        var args;
        var j;
        var val;
        var valueWidth;
        var offsetX;
        var fields = _fields;
        for (var i = 0; i < fields.size(); i++) {
            args = fields[i];
            // Draw labels
            dc.drawText(args[0], args[1], args[2], args[3], args[4]);

            // Draw value
            units = args[12];
            val = getFieldValue(args[8], args[9], args[10]);
            if (units == null) {
                dc.drawText(args[5], args[6], args[7], val, args[11]);
            } else {
                // We have to calculate the center of value + unit combined
                valueWidth = dc.getTextWidthInPixels(val, args[7]);
                offsetX = args[5] - ((args[5] - valueWidth) + ((valueWidth + args[13] + _padding) / 2));

                dc.drawText(args[5] + offsetX, args[6], args[7], val, args[11]);
                for (j = 0; j < units.size(); j++) {
                    args = units[j];
                    dc.drawText(args[0] + offsetX, args[1], args[2], args[3], args[4]);
                }
            }
        }
    }

    private function preCalculate(dc, sensor) {
        if (_errorCode == 3) {
            _errorCode = null;
        } else if (_errorCode != null) { // Do not precalculate in case the sensor was not initialized
            return;
        }

        if (sensor.fitBatteryField == null && Properties.getValue("FF0")) {
            sensor.fitBatteryField = createField(
                "ebike_battery",
                0, // Id
                2 /*DATA_TYPE_UINT8 */,
                {
                    :mesgType=> 20 /* Fit.MESG_TYPE_RECORD */,
                    :units=> "%"
                }
            );
        }

        if (sensor.fitAssistModeField == null && Properties.getValue("FF1")) {
            sensor.fitAssistModeField = createField(
                "ebike_assist_mode",
                1, // Id
                2 /*DATA_TYPE_UINT8 */,
                {
                    :mesgType=> 20 /* Fit.MESG_TYPE_RECORD */
                }
            );
        }

        var layouts = [
            :FL100,
            :FL201,
            :FL202,
            :FL303,
            :FL304,
            :FL405,
            :FL406,
            :FL507,
            :FL508,
            :FL609,
            :FL610,
            :FL711,
            :FL712,
            :FL813,
            :FL814,
            :FL915,
            :FL916,
            :FL1017
        ];
        var fieldLabels = [
            :Battery,
            :BatteryChargingCycles,
            :BatteryVoltage,
            :Lights,
            :Odometer,
            :RemainingRange,
            :FuelConsumption,
            :TemperatureMotor,
            :TemperatureBattery,
            :AssistMode,
            :Speed,
            :ErrorCode,
            :CurrentChargeDistance,
            :Assist
        ];
        var i;
        var width = dc.getWidth();
        var height = dc.getHeight();
        var deviceSettings = System.getDeviceSettings();
        var orientation = deviceSettings.screenWidth < deviceSettings.screenHeight ? 1 : 2;
        var layout;
        var layoutData;
        var widthRatio = Math.round((width.toFloat() / deviceSettings.screenWidth) * 100) / 100 + 0.01f;
        var heightRatio = Math.round((height.toFloat() / deviceSettings.screenHeight) * 100) / 100 + 0.01f;
        var settings = loadJson(:Settings);
        var labelAlignment = settings[1];
        var valueHorizontalAlignment = settings[3];
        var maxLabelFont = settings[7];
        var topPadding = settings[6];

        // Find the first supported layout
        for (i = 0; i < 3; i++) {
            layout = Properties.getValue("FL" + i);
            layoutData = loadJson(layouts[layout % 100]);
            var requirements = layoutData[2];
            if ((requirements[0] == 0 || requirements[0] == orientation) &&
                requirements[1] <= widthRatio && requirements[2] <= heightRatio) {
                break;
            } else {
                layout = null;
            }
        }

        if (layout == null) {
            _errorCode = 3;
            return;
        }

        _defaultValues = loadJson(:DefaultValues);
        _colorScreen = settings[0];
        _padding = settings[5];
        _separatorColor = _colorScreen ? Properties.getValue("SC") : 0x000000; /* COLOR_BLACK */

        var fieldLocations = layoutData[0];
        var separators = layoutData[1];
        var totalFields = layout / 100;
        var fontTopPaddings = loadJson(:FontTopPaddings)[0];
        var fieldUnits = settings[4] ? loadJson(:FieldUnits) : null;
        var distanceUnits = Properties.getValue("U");
        var metric = distanceUnits < 0 ? deviceSettings.distanceUnits == 0 : distanceUnits == 0;
        var defaultValues = metric ? 0x2202160 : 0x2202960;  // Fields default value indexes of _defaultValues, 2 bits per field
        var formatTypes = metric ? 0x1013221004100l : 0x1013221104100l; //0x11E9010 : 0x11E9410;  // Fields value format types, 4 bits per field
        var array;

        // Precalculate separators
        if (separators == null) {
            _separators = null;
        } else {
            array = new [separators.size()];
            for (i = 0; i < separators.size(); i = i + 4) {
                array[i] = Math.round(separators[i] * width); // x1
                array[i + 1] = Math.round(separators[i + 1] * height); // y1
                array[i + 2] = Math.round(separators[i + 2] * width); // x2
                array[i + 3] = Math.round(separators[i + 3] * height); // y2
            }

            _separators = array;
        }

        array = new [totalFields];
        var dataIndexes = 0l;
        var dataSize = 0;
        var dataIndex;
        // Fit fields have to be received from the sensor even if they are not displayed
        if (sensor.fitBatteryField != null) {
            dataIndexes |= (dataSize + 1l); // Index 0
            dataSize++;
        }

        if (sensor.fitAssistModeField != null) {
            dataIndexes |= (dataSize + 1l) << (9 * 4); // Index 9
            dataSize++;
        }

        for (i = 0; i < totalFields; i++) {
            var j = i * 4;
            var x = Math.round(fieldLocations[j] * width); // Top left x
            var y = Math.round(fieldLocations[j + 1] * height) + topPadding; // Top left y
            var w = Math.round(fieldLocations[j + 2] * width); // Width
            var h = Math.round(fieldLocations[j + 3] * height) - topPadding; // Height
            var fieldType = Properties.getValue("FT" + i);
            var labelText = WatchUi.loadResource(Rez.Strings[fieldLabels[fieldType]]);
            var labelFont = selectFont(dc, w, h, maxLabelFont);
            var labelFontTopPadding = getFontTopPadding(labelFont, fontTopPaddings);
            var labelFontHeight = getRealFontHeight(dc, labelFont, fontTopPaddings);
            var maxValueFont = ((0x3C77 >> fieldType) & 0x01) == 1 ? 8 : 4;
            var valueFont = selectFont(dc, w, h - dc.getFontHeight(labelFont) + settings[2], maxValueFont);
            var valueFontTopPadding = getFontTopPadding(valueFont, fontTopPaddings);
            var valueFontBottomPadding = dc.getFontDescent(valueFont);
            var valueFontYOffset = valueFontBottomPadding - ((valueFontBottomPadding + valueFontTopPadding) / 2);
            var valueFontHeight = dc.getFontHeight(valueFont);
            var valueX = valueHorizontalAlignment == 1 ? x + (w / 2) /* Center */ : x + w - _padding /* Right */;
            var valueY = y + labelFontHeight + ((h - labelFontHeight) / 2) + (valueFontYOffset / 2);
            var unitWidth = null;
            var unitLabels = null;
            var units = fieldUnits != null ? getFieldUnits(fieldUnits, fieldType, metric) : null;
            if (units != null) {
                var unitsSize = units.size();
                var maxUnitFont = ((0x2001 >> fieldType) & 0x01) == 1 ? 8 : 4;
                var unitFont = selectFont(dc, null, valueFontHeight / unitsSize, maxUnitFont);
                unitWidth = dc.getTextWidthInPixels(units[0], unitFont);

                unitLabels = new [unitsSize];
                var unitFontBottomPadding = dc.getFontDescent(unitFont);
                var unitFontTopPadding = getFontTopPadding(unitFont, fontTopPaddings);
                var unitFontHeight = dc.getFontHeight(unitFont);
                var unitsHeight = (unitFontHeight * unitsSize + 2 /* line spacing */ * (unitsSize - 1)) - ((unitFontBottomPadding + unitFontTopPadding) * (unitsSize - 1));
                var unitY = valueY + (valueFontHeight / 2) - valueFontBottomPadding - unitsHeight + (unitFontHeight / 2 + unitFontBottomPadding);
                var unitCenter = (0x440 >> fieldType) & 0x01;
                for (j = 0; j < unitsSize; j++) {
                    unitLabels[j] = [
                        (unitCenter ? valueX + (unitWidth / 2) : valueX) + _padding,
                        unitY + (j * (getRealFontHeight(dc, unitFont, fontTopPaddings) + 2 /* line spacing */)),
                        unitFont,
                        units[j],
                        (unitCenter ? 1 /* TEXT_JUSTIFY_CENTER */ : 2 /* TEXT_JUSTIFY_LEFT */) | 4 /* TEXT_JUSTIFY_VCENTER */
                    ];
                }
            }

            if ((fieldType == 7 /* Motor temperature */ || fieldType == 8 /* Battery temperature */) && _temperatureNames == null) {
                // Initialize temperature names
                _temperatureNames = loadNames([
                    null, // Unknown
                    :ColdTemperature,
                    :ColdWarmTemperature,
                    :WarmTemperature,
                    :WarmHotTemperature,
                    :HotTemperature
                ], 1);
            } else if (fieldType == 3 /* Lights */ && _onOffNames == null) {
                // Initialize ON/OFF names
                _onOffNames = loadNames([:Off, :On], 0);
            }

            dataIndex = (((dataIndexes >> (fieldType * 4)) & 0x0F) - 1).toNumber();
            if (dataIndex == -1) {
                dataIndexes |= (dataSize + 1l) << (fieldType * 4);
                dataIndex = dataSize;
                dataSize++;
            }

            array[i] = [
                labelAlignment == 1 ? x + (w / 2) /* Center */ : x + _padding /* Left */, // Label x
                y - labelFontTopPadding, // Label y
                labelFont, // Label font
                labelText, // Label text
                labelAlignment, // Label justification

                valueX, // Value x
                valueY, // Value y
                valueFont, // Value font
                dataIndex, // Data index
                (defaultValues >> (2 * fieldType)) & 0x03, // Default value index of _defaultValues
                (formatTypes >> (4 * fieldType)) & 0x0F, // Value format type
                units == null // Value justification
                    ? valueHorizontalAlignment | 4 // TEXT_JUSTIFY_(CENTER/RIGHT) | TEXT_JUSTIFY_VCENTER
                    : 0 | 4, // TEXT_JUSTIFY_RIGHT | TEXT_JUSTIFY_VCENTER
                unitLabels, // Unit labels
                unitWidth // Unit width
            ];
        }

        _fields = array;

        sensor.setup(dataSize, dataIndexes, metric);
    }

    private function selectFont(dc, width, height, startFont) {
        var i;
        var textWidth;
        var textHeight;
        // Search through fonts from biggest to smallest
        for (i = startFont; i > 0; i--) {
            textHeight = dc.getFontHeight(i);
            textWidth = width != null ? dc.getTextWidthInPixels($.testString, i) : null;
            if ((textWidth == null || textWidth <= width) && textHeight <= height) {
                // If this font fits, it is the biggest one that does
                break;
            }
        }

        return i;
    }

    private function getRealFontHeight(dc, font, fontTopPaddings) {
        // Do not take into account font top/bottom padding
        return dc.getFontHeight(font) - dc.getFontDescent(font) - getFontTopPadding(font, fontTopPaddings);
    }

    private function getFontTopPadding(font, fontTopPaddings) {
        return ((fontTopPaddings >> (font * 7)) & 0x7F).toNumber();
    }

    private function getFieldUnits(fieldUnits, type, metric) {
        // Every field is represented with 4bits, where the first 3 bits represents the index of fieldUnits array and the fourth bit
        // represents whether the unit is different for mertic and statute. In case it is different the statute counterpart is located
        // one index ahead.
        var data = ((0x1B0F000DBB0201l >> (type * 4)) & 0x0F).toNumber();
        var index = (data & 0x07) - 1;
        if (index < 0) {
            return null;
        }

        if (!metric && ((data >> 3) & 0x01) == 1) {
            index++;
        }

        return fieldUnits[index];
    }

    private function getFieldValue(dataIndex, defaultValueIndex, formatType) {
        var value = _sensor.data[dataIndex];
        if (value == null || _sensor.searching) {
            return _defaultValues[defaultValueIndex];
        }

        return formatType == 0 ? value.toString()
            : formatType == 1 ? value.format("%.1f")
            : formatType == 2 ? _temperatureNames[value]
            : formatType == 3 ? getAssistMode(value, _assistModes, _sensor, defaultValueIndex)
            : _onOffNames[value];
    }

    private function getAssistMode(value, assistModes, sensor, defaultValueIndex) {
        if (_manufacturerId != sensor.manufacturerId) {
            _manufacturerId = sensor.manufacturerId;
            assistModes = updateAssistModes(_manufacturerId);
        }

        return assistModes != null && value < assistModes.size()
            ? assistModes[value]
            : sensor.manufacturerId != null && sensor.totalAssistModes != null
                ? value + " / " + sensor.totalAssistModes
                : _defaultValues[defaultValueIndex];
    }

    private function updateAssistModes(newManufacturerId) {
        _assistModes = newManufacturerId == 108 /* Giant */ ? loadJson(:GiantAssistModes)
                : newManufacturerId == 63 /* Specialized */ ? loadJson(:SpecializedAssistModes)
                : newManufacturerId == 299 /* Mahle */ ? loadJson(:MahleAssistModes)
                : null;

        return _assistModes;
    }

    private function loadNames(array, startIndex) {
        for (var i = startIndex; i < array.size(); i++) {
            array[i] = WatchUi.loadResource(Rez.Strings[array[i]]);
        }

        return array;
    }

    private function loadJson(key) {
        return WatchUi.loadResource(Rez.JsonData[key]);
    }
}