using Toybox.Ant;
using Toybox.Application.Properties as Properties;

class EBikeSensor {
    private var _fieldIndexes;
    private var _metric;
    private var _deviceNumbers = new [3];
    private var _deviceIndex = 0;
    private var _channel;

    public var data;
    public var searching = true;
    public var totalAssistModes;
    public var manufacturerId;
    public var fitBatteryField;
    public var fitAssistModeField;
    public var lastMessageTime = 0;

    function initialize() {
        // Load paired devices
        setupDeviceNumbers();
    }

    function setup(size, dataIndexes, metric) {
        data = new [size];
        _fieldIndexes = new [15];
        _metric = metric;
        setupDeviceNumbers();
        for (var i = 0; i < _fieldIndexes.size(); i++) {
            _fieldIndexes[i] = (((dataIndexes >> (i * 4)) & 0x0F) - 1).toNumber();
        }
    }

    function open() {
        if (_channel == null) {
            _channel = new Ant.GenericChannel(method(:onMessage), new Ant.ChannelAssignment(Properties.getValue("CT"), 1 /* NETWORK_PLUS */));
            setChannelDeviceNumber();
        }

        resetMessageData();
        return _channel.open();
    }

    function close() {
        var channel = _channel;
        if (channel != null) {
            _channel = null;
            channel.release();
            resetMessageData();
        }
    }

    function onMessage(message) {
        lastMessageTime = System.getTimer();
        var payload = message.getPayload();
        if (0x4E /* MSG_ID_BROADCAST_DATA */ == message.messageId) {
            if (data == null) {
                return;
            }

            var index;
            var indexes = _fieldIndexes;
            var pageNumber = (payload[0] & 0xFF);
            if (pageNumber == 1) {
                // Were we searching?
                if (searching) {
                    searching = false;
                    setNewDeviceNumber();
                }

                index = indexes[8];
                if (index != -1) { setValue(payload[1] & 0x07, index, 0); } // Battery Temperature
                index = indexes[7];
                if (index != -1) { setValue((payload[1] >> 4) & 0x07, index, 0); } // Motor Temperature
                index = indexes[9];
                if (index != -1) { recordValue(fitAssistModeField, (payload[2] >> 3) & 0x07, index); } // Current Assist Level
                index = indexes[3];
                if (index != -1) { data[index] = (payload[3] >> 3) & 0x01; } // Light On/Off
                index = indexes[11];
                if (index != -1) { setValue(payload[5], index, 0); } // Error Message Code
                index = indexes[10];
                if (index != -1) { data[index] = ((((payload[7] & 0x0F) << 8) | payload[6]) / 10f) * (_metric ? 1 : 0.62137f); } // LEV Speed
            } else if (pageNumber == 2 || pageNumber == 34) {
                index = indexes[4];
                if (index != -1) { data[index] = Math.round((((payload[3] << 16) | (payload[2] << 8) | (payload[1])) / 100) * (_metric ? 1 : 0.62137f)).toNumber(); } // Odometer
                if (pageNumber == 2) {
                    index = indexes[5];
                    if (index != -1) { setValue((((payload[5] & 0x0F) << 8) | payload[4]) * (_metric ? 1 : 0.62137f), index, 0); } // Remaining Range
                } else {
                    index = indexes[6];
                    if (index != -1) { setValue((((payload[5] & 0x0F) << 8) | payload[4]) / 10f, index, 0); } // Fuel Consumption
                }
            } else if (pageNumber == 3) {
                index = indexes[0];
                if (index != -1) { recordValue(fitBatteryField, payload[1] & 0x7F, index); } // Battery SOC (State of Charge)
                index = indexes[13];
                if (index != -1) { setValue(payload[5], index, 0xFF); } // % Assist
            } else if (pageNumber == 4) {
                index = indexes[1];
                if (index != -1) { setValue(((payload[3] & 0x0F) << 8) | payload[2], index, 0); } // Charging Cycle Count
                index = indexes[6];
                if (index != -1) { setValue((((payload[3] & 0xF0) << 4) | payload[4]) / 10f, index, 0); } // Fuel Consumption
                index = indexes[2];
                if (index != -1) { setValue(payload[5] * 0.25f, index, 0); } // Battery Voltage
                index = indexes[12];
                if (index != -1) { setValue((((payload[7] << 8) | payload[6]) / 10f) * (_metric ? 1 : 0.62137f), index, 0); } // Distance on Current Charge
            } else if (pageNumber == 5) {
                if (totalAssistModes == null) {
                    totalAssistModes = (payload[2] >> 3) & 0x07; // Number of Assist modes supported
                }
            } else if (pageNumber == 80) {
                if (manufacturerId == null) {
                    manufacturerId = (payload[5] << 8) | payload[4]; // Manufacturer ID
                    index = indexes[14];
                    if (index != -1) { setValue(manufacturerId, index, 0); }
                }
            }
        } else if (0x40 /* MSG_ID_CHANNEL_RESPONSE_EVENT */ == message.messageId) {
            if (0x01 /* MSG_ID_RF_EVENT */ == (payload[0] & 0xFF)) {
                if (0x07 /* MSG_CODE_EVENT_CHANNEL_CLOSED */ == (payload[1] & 0xFF)) {
                    // Channel closed, re-open only when the channel was not manually closed
                    if (_channel != null) {
                        setNextDeviceNumber();
                        open();
                    }
                } else if (0x08 /* MSG_CODE_EVENT_RX_FAIL_GO_TO_SEARCH */ == (payload[1] & 0xFF)) {
                    searching = true;
                }
            } else {
                //It is a channel response.
            }
        }
    }

    private function setNextDeviceNumber() {
        var startDeviceIndex = _deviceIndex;
        do {
          _deviceIndex = (_deviceIndex + 1) % _deviceNumbers.size();
        } while (_deviceNumbers[_deviceIndex] < 0 && startDeviceIndex != _deviceIndex);
        setChannelDeviceNumber();
    }

    private function setChannelDeviceNumber() {
        var deviceNumber = _deviceNumbers[_deviceIndex];
        _channel.setDeviceConfig(new Ant.DeviceConfig({
            :deviceNumber => deviceNumber,
            :deviceType => 20,        // LEV Device
            :messagePeriod => 8192,   // Channel period
            :transmissionType => 0,   // Transmission type
            :radioFrequency => 57     // Ant+ Frequency
        }));
    }

    private function setNewDeviceNumber() {
        var deviceNumbers = _deviceNumbers;
        var newDeviceNumber = _channel.getDeviceConfig().deviceNumber;
        // Find the first empty slot to insert the found device.
        for (var i = 0; i < deviceNumbers.size(); i++) {
            if (deviceNumbers[i] == 0) {
                _deviceIndex = i;
                deviceNumbers[i] = newDeviceNumber;
                Properties.setValue("DN" + i, newDeviceNumber);
                break;
            } else if (deviceNumbers[i] == newDeviceNumber) {
                _deviceIndex = i;
                break;
            }
        }
    }

    private function setupDeviceNumbers() {
        var deviceNumbers = _deviceNumbers;
        for (var i = 0; i < deviceNumbers.size(); i++) {
            deviceNumbers[i] = Properties.getValue("DN" + i);
        }
    }

    private function resetMessageData() {
        totalAssistModes = null;
        manufacturerId = null;
    }

    private function setValue(value, index, defaultValue) {
        data[index] = value == defaultValue ? null : value;
    }

    private function recordValue(fitField, newValue, index) {
        if (fitField != null && data[index] != newValue) {
            fitField.setData(newValue);
        }

        data[index] = newValue;
    }
}