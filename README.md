E-Bike Edge MultiField
=================

E-Bike Edge MultiField is a [data field](https://developer.garmin.com/connect-iq/connect-iq-basics/data-fields/) IQ Connect application for Garmin Edge devices, that displays up to 10 data fields from an ANT+ LEV (Light Electronic Vehicle) device. As separate data fields on the same screen cannot connect to an ANT+ LEV device or share its data, this data field renders its own grid system that mimics the native one in order to display multiple LEV fields.

## Features
- 18 different layouts from one to ten fields
- Displaying different layouts based on the data field size
- Pairing up to three ANT+ LEV devices
- Tracking battery level and assist mode that is displayed in Garmin Connect
- 14 different field types retrieved from ANT+ LEV device
- Displaying Giant assist modes (OFF, ECO, BASIC, ACTIVE, AUTO, SPORT, POWER)
- Displaying Specialized assist modes (OFF, ECO, TRAIL, TURBO)
- Displaying Mahle assist modes (OFF, ECO, TRAIL, TURBO)

## How to use

1. Download the data field application from Garmin Connect Store and synchronize your Garmin Edge
2. Select the data screen where you want put the data field
3. On the chosen field select `Connect IQ` -> `E-Bike MultiField`
4. Pair your ANT+ LEV device (see below for instructions)
5. Use Garmin Express or Garmin Connect Mobile to configure the data field layout and fields

## Pairing

1. Turn your ANT+ LEV device on.
2. Select the data screen where the data field is displayed
3. With the data screen active put the Garmin Edge close to the LEV device (for Giant E-Bikes this is Giant RideControl)
4. Wait until the battery level is displayed (this should take up to 15 seconds)

**NOTE:** This data field cannot be used with other LEV/E-Bike data fields, only one LEV/E-Bike data field can be displayed on a data screen. In case your Garmin device supports EBike connection via `Sensors` menu, it must be disconnected from there.

For unpair a LEV device set the `Primary LEV Device Number` setting to zero by using Garmin Express or Garmin Connect Mobile.

## Pair multiple E-Bikes

By default only one E-Bike will be paired in order to prevent pairing E-Bikes from other people when our is off. To pair an additional E-Bike:
1. Update `Secondary LEV Device Number` app settings value from `-1` to `0`
2. Make sure that the E-Bike that was already paired is either off or far away from Garmin Edge
3. Follow the [pairing steps](#pairing) to pair the second E-Bike.

## Currently tested ANT+ LEV devices:
- Giant RideControl Ergo (setting `ANT channel type` must be set to `Receive Only (Slave)`)

## Currently tested Garmin devices:
- Edge 1000

**NOTE:** Due to differences between simulators and real devices, text may not be correctly aligned. In case you want to help with the text alignment check [FontPaddingTest](/Source/FontPaddingTest) project.

## Layouts
| 1 Field | 10 Fields |
| :-----: | :-------: |
| ![1 Field](/Images/1Field.png?raw=true) | ![10 Fields](/Images/10Fields.png?raw=true) |
| **Requirements:** / | **Requirements:** Portrait display, Full screen |

| 2 Fields A | 2 Fields B |
| :--------: | :--------: |
| ![2 Fields A](/Images/2FieldsA.png?raw=true) | ![2 Fields B](/Images/2FieldsB.png?raw=true) |
| **Requirements:** Full width, at least 1/2 screen height | **Requirements:** Full width, at least 1/5 screen height |

| 3 Fields A | 3 Fields B |
| :--------: | :--------: |
|![3 Fields A](/Images/3FieldsA.png?raw=true) | ![3 Fields B](/Images/3FieldsB.png?raw=true) |
| **Requirements:** Portrait display, Full screen | **Requirements:** Full width, at least 1/2 screen height |

| 4 Fields A | 4 Fields B |
| :--------: | :--------: |
|![4 Fields A](/Images/4FieldsA.png?raw=true) | ![4 Fields B](/Images/4FieldsB.png?raw=true) |
| **Requirements:** Portrait display, Full screen | **Requirements:** Full width, at least 1/2 screen height |

| 5 Fields A | 5 Fields B |
| :--------: | :--------: |
|![5 Fields A](/Images/5FieldsA.png?raw=true) | ![5 Fields B](/Images/5FieldsB.png?raw=true) |
| **Requirements:** Portrait display, Full screen | **Requirements:** Landscape display, Full screen |

| 6 Fields A | 6 Fields B |
| :--------: | :--------: |
|![6 Fields A](/Images/6FieldsA.png?raw=true) | ![6 Fields B](/Images/6FieldsB.png?raw=true) |
| **Requirements:** Portrait display, Full screen | **Requirements:** Landscape display, Full screen |

| 7 Fields A | 7 Fields B |
| :--------: | :--------: |
|![7 Fields A](/Images/7FieldsA.png?raw=true) | ![7 Fields B](/Images/7FieldsB.png?raw=true) |
| **Requirements:** Portrait display, Full screen | **Requirements:** Landscape display, Full screen |

| 8 Fields A | 8 Fields B |
| :--------: | :--------: |
|![8 Fields A](/Images/8FieldsA.png?raw=true) | ![8 Fields B](/Images/8FieldsB.png?raw=true) |
| **Requirements:** Portrait display, Full screen | **Requirements:** Landscape display, Full screen |

| 9 Fields A | 9 Fields B |
| :--------: | :--------: |
|![9 Fields A](/Images/9FieldsA.png?raw=true) | ![9 Fields B](/Images/9FieldsB.png?raw=true) |
| **Requirements:** Portrait display, Full screen | **Requirements:** Landscape display, Full screen |

## Field Types

- Battery level (%)
- Charging Cycle Count
- Battery Voltage (V)
- LEV Lights (ON/OFF)
- LEV Odometer (km or m)
- Remaining Range (km or m)
- Fuel Consumption (Wh/km or Wh/m)
- Motor Temperature (Cold, Warm-, Warm, Warm+, Hot)
- Battery Temperature (Cold, Warm-, Warm, Warm+, Hot)
- Assist Mode (For unknown LEV devices: <Current assist level> / <Total assist levels>)
- LEV Speed (km/h or m/h)
- LEV Error Code (1-255)
- Distance on Current Charge (km or m)
- Assist (0-100%)

**NOTE:** An ANT+ LEV device may not support all field types, unsupported field values won't be displayed.

## Error codes

In case an invalid combination of settings is selected or there an issue with the ANT channel, an error will be displayed on the screen. The following errors can be displayed:
- **Error 1:** An error occured while trying to initialize the ANT channel. Check that this data field is the only LEV/E-Bike data field displayed.
- **Error 2:** The initialized ANT channel could not be opened. Check that this data field is the only LEV/E-Bike data field displayed.
- **Error 3:** The selected layout is too big to fit in the selected field. Check above for the requirements of the selected layout.