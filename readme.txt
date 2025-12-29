## aDF - a small frame that shows armor and few debuffs on your target.
## Author: Atreyyo @ Vanillagaming.org
## Contributor: Autignem version v4.x <-- rework/rewrite
######################################

## 🔄 UPDATE INSTRUCTIONS - READ CAREFULLY!!!!!!!

### ⚠️⚠️⚠️ **BEFORE YOU START - IMPORTANT WARNING: ** ⚠️⚠️⚠️
**DO NOT DELETE YOUR ENTIRE WTF FOLDER!**  
Following these instructions incorrectly can make you lose ALL settings for ALL your addons.

### **STEP-BY-STEP GUIDE:**

#### **1. EXIT WORLD OF WARCRAFT COMPLETELY**
- Close WoW to desktop (don't just `/reload`)
- This allows SavedVariables to save properly

#### **2. FIND YOUR CORRECT WTF FOLDER**
Navigate to **ONE** of these paths:

**For Vanilla WoW 1.12.1 **
World of Warcraft/WTF/Account/[YOUR_ACCOUNT]/SavedVariables/

*(Replace `[YOUR_ACCOUNT]` with your actual account/email name)*

#### **3. DELETE ONLY THESE 2 FILES:**
Inside the `SavedVariables/` folder, find and delete:
- 📄 `aDF.lua` ← DELETE THIS ONE
- 📄 `aDF.lua.bak` ← DELETE THIS TOO (if it exists)

**DO NOT DELETE ANY OTHER FILES IN THIS FOLDER!**

#### **4. INSTALL NEW aDF v4.0:**
1. Delete old addon folder: `Interface/AddOns/aDF/`
2. Extract new v4.0 files to: `Interface/AddOns/aDF/`

#### **5. LAUNCH WORLD OF WARCRAFT**
- Start WoW normally
- aDF v4.0 will create fresh configuration files
- Use `/adf options` to configure your settings

---

### **❌ WHAT NOT TO DO:**
- ❌ **NEVER delete the entire WTF folder** (this would delete ALL addon settings)
- ❌ Don't just overwrite old files (causes conflicts)
- ❌ Don't skip deleting SavedVariables (will cause errors)
- ❌ Don't update while WoW is running

### **✅ WHAT TO DO IF YOU MAKE A MISTAKE:**
If you accidentally delete wrong files:
1. Check Windows Recycle Bin
2. Restore any non-aDF files you deleted
3. Other addons will recreate their settings when you launch WoW

--- New Version --- v4.2

### NEW FEATURES:
- **Centralized Configuration System**: Complete rewrite of settings management using structured profiles
- **Decimal Scale Control**: Slider now supports fine-grained adjustments (0.1-10 with 0.05 steps)
- **Enhanced UI Controls**: Added +/- buttons and numeric input field for scale adjustment

### IMPROVEMENTS:
- **Code Architecture**: Complete reorganization with clear subsections and better documentation
- **Variable Naming**: More descriptive and consistent naming convention (db.display.*, db.locks.*)
- **Future-Proofing**: Profile system foundation laid for future multi-profile support
- **Frame Naming**: Fixed potential conflict by renaming options frame to aDF_OptionsFrame
- **Add New Debuff**: Thunder clap (and other versions), fire vulnerability and demoralizing shout

### TECHNICAL:
- **Configuration Migration**: Safe migration system that preserves existing settings
- **Boolean Consistency**: Unified use of true/false instead of mixed 1/nil values
- **Base Constants**: Added ICON_BASE, FONT_BASE_* constants for clearer calculations
- **Tooltip Management**: Added proper cleanup when closing options panel

### NOTES:
- **⚠️ Requires deleting old SavedVariables** (aDF.lua and aDF.lua.bak) due to configuration structure changes

--- Version --- v4.1

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


