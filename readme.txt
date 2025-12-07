## aDF - a small frame that shows armor and few debuffs on your target.
## Author: Atreyyo @ Vanillagaming.org
## Contributor: Autignem version v4.0
######################################

*** Always delete aDF.lua in the WTF folder when updating this addon, or if you are unsure where to find it, delete entire WTF folder.

--- New version --- v4.1

### Changes Made:

- **Fixed the issue where target debuffs were getting mixed up.
- **Performance improved; the impact should be negligible now.
- **Added a tostring call to prevent excessive function calls

--- New version --- v4.0

###To adjust the sorting order, see the aDFOrder function (approximately line 142). No further changes were made beyond this point at the time of writing

NEW Debuffs shown:

"Expose Armor",
"Sunder Armor",
"Curse of Recklessness",
"Faerie Fire",
"Decaying Flesh",
"Feast of Hakkar",
"Cleave Armor",
"Shattered Armor",
"Holy Sunder",
"Crooked Claw",
"Judgement of Wisdom",
"Curse of Shadows",
"Curse of the Elements",
"Shadow Weaving",
"Nightfall",
"Flame Buffet"

### Changes Made:
# DT-DebuffTracker (Custom Fork)

A complete overhaul of the debuff tracking system, optimized for raid utility and clarity.

## ✨ Main Features & Changes

### **Core System Rework**
- **Priority-Based Sorting:** Debuffs are now ordered via a customizable priority list (see line 142) instead of alphabetically.
- **Extensible Architecture:** The code has been fully refactored for better readability and future maintenance.

### **UI & Display Enhancements**
- **Third Debuff Row:** Added a new, fully functional row for tracking additional debuffs (e.g., weapon procs, set bonuses). The system is designed to be easily extended for more rows or even buff tracking.
- **Resistance Display:** The feature to view target resistances has been restored.
- **Visual Overhaul:** Updated the options panel and debuff frames with a cleaner, more organized visual style.
- **Armor Box Background Toggle:** Added an option to show/hide the background of the armor break display.

### **Options Panel Revamp**
- The configuration panel (`adf options`) has been completely rebuilt with separated, logical sections for easier navigation.

### **Quality of Life & Anti-Spam**
- **Announcement Toggle:** Added an option to enable/disable `/say` announcements for armor breaks to prevent chat spam during raids.

### **Technical Improvements**
- **Full Code Reorganization:** The entire codebase has been restructured to improve legibility and facilitate future contributions.

--- Original Version ---

Debuffs shown:

["Sunder Armor"] 
["Armor Shatter"]
["Faerie Fire"]
["Crystal Yield"]
["Nightfall"]
["Scorch"]
["Ignite"]
["Curse of Recklessness"] 
["Curse of the Elements"]
["Curse of Shadows"]
["Shadow Bolt"]
["Shadow Weaving"]
["Expose Armor"]


Feel free to make any suggestions to the addon.


--- Versions ---

--- aDF 3.0

Added Expose Armor and rewrote some code
Removed ["Elemental Vulnerability"] ( Mage t3 6setbonus proc )

--- aDF 2.9

added Vampiric Embrace

--- aDF 2.8
 
rewrote the update function, should improve performance
added "healermode" which let's you see the debuffs and armor of your friendly targets target

--- aDF 2.7

added ["Elemental Vulnerability"] ( MAge t3 6setbonus proc )

--- aDF 2.6

changed behaviour of the frame to only react when target is in combat rather than the player

--- aDF 2.5
added scaling function to main frame
added scaling slider and dropdown menu to choose channel for announcing armor/debuffs in options frame
added background to armor frame

--- aDF 2.0

added options menu frame
rewrote the core

--- aDF 1.0


First release
