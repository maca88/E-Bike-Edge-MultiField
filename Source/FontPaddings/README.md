FontPaddings
=================

![Font padding](/Images/FontPadding.png?raw=true)

This project is used to detect font paddings on various Garmin devices. Unfortunately, the font paddings differ between a real device and its simulator. If you own a device that has not been aligned yet and are willing to contribute, please feel free to make a PR (pull request).


## How to use

1. Connect the Garmin device to a computer
2. Copy the `FontPaddings.prg` file into the `/Garmin/Apps` folder on the Garmin device
3. Disconnect the Garmin device from the computer and turn it on
4. Open the `Font Paddings` widget
5. Do the following for all displayed fonts (9 in total) where the green line does not touch the text:
    1. Open the menu, go to `Configure paddings` and select the font to align
    2. Move the green line down so that it touches the text. To move the green line you need to tap the bottom (Down) or upper (Up) part of the screen on a touch screen device or use the `Up` and `Down` buttons
    3. Repeat the above two steps for all fonts that are not aligned
6. Go to menu and select `View all fonts` to check if all fonts are correctly aligned. Here is an example of a correct alignment:
![Font padding](/Images/FontPaddingAligned.png?raw=true)
7. Go to menu and select `View paddings`, write down the paddings and provide them to the developer


## Currently aligned Garmin devices:
- Edge 1000 (WW)
- Edge 1040 (WW)
- Edge 840 (WW)