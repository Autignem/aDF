# aDF for Turtle WoW
aDF adds a small HUD that standardizes critical info about your target's defences, including Armor, Resistence, and specific debuffs. This HUD should be useful to all DPS and Tank players who would play differently depending on the state of their enemy's defenses and vulnerabilities.
This is a specific version customized for Doom Turtle, adapted to our raid group's specific needs

<img width="560" height="771" alt="adf_1" src="https://github.com/user-attachments/assets/f6ca1fde-ae0b-4e1d-9ff5-ad206e3f1cec" />

<img width="249" height="168" alt="adf_2" src="https://github.com/user-attachments/assets/d0eb3ac4-b37e-45d2-aa0f-3c4e34827876" />

The version for 1.12 exists on the `master` branch while a version with changes specific to TurtleWoW exists on the `masterturtle` branch.

## Features
* The HUD displays your current PVE target's armor and debuffs.
* As enemy and friendly players' armor values are not exposed to the API by vmangos servers, the armor reading will not work in PVP. 
* Hold Shift and left click to drag and move the HUD.
* Right click the armor reading to share the value with others, or right click a debuff to announce if its up or not. 
* Type `/adf options` to configure which debuffs are shown for you, and which chat channel announcements are made in.

## Known issues

This version can see in https://github.com/Autignem/aDF/issues. Pull request are welcome

## Credits

Currently developed and maintained by Zaas-TurtleWoW
See originaL in https://github.com/Zebouski/aDF/

Some code merged in by Github @Goffauxs

Originally developed by Atreyyo-Vanillagaming.org

Last version developed Zebouski
