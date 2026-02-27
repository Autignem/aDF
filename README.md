# aDF - Amor/debuff Frame for Turtle WoW

### 🔄 **UPDATING FROM OLDER VERSIONS? READ THIS!** v1.0-v4.3

aDF v4.2.1 is a **complete codebase rewrite** with different data structures. You **MUST** clean your SavedVariables:

#### Step-by-Step Update Guide:
1. **Exit WoW completely** (to desktop, not just `/reload`)
2. Navigate to your WTF folder: <br>
World of Warcraft/Turtle WoW/WTF/Account/[YOUR_ACCOUNT]/SavedVariables/
3. Delete **ONLY** these 2 files:
- `aDF.lua`
- `aDF.lua.bak` (if exists)
4. Install new aDF v4.3 to `Interface/AddOns/aDF/`
5. Launch WoW - fresh config will be created

**⚠️ WARNING:** Never delete your entire WTF folder! This would lose ALL addon settings.

### CRITICAL CLEANUP STEP ⚠️: <br>

Search for any other aDF.lua files in your SavedVariables folders. They can sometimes be orphaned in server-specific or even character-specific paths, like:
World of Warcraft/Turtle WoW/WTF/Account/[YOUR_ACCOUNT]/[Server]/[YOUR_CHARACTER]/SavedVariables
Delete all of them to ensure a clean reset.

** More info in Readme.txt **

### Description

aDF is a **complete rewrite** of the classic armor/debuff tracking addon, specifically optimized on Turtle WoW. It displays critical defensive information about your target in a lightweight, efficient HUD.

<img width="977" height="657" alt="image" src="https://github.com/user-attachments/assets/e3f4166f-e6df-44cd-8466-e442ad8398d9" />

------

<img width="211" height="130" alt="image" src="https://github.com/user-attachments/assets/ade1c3b1-f368-4238-ae4e-8505476c1031" />

### Features

- **Real-time armor monitoring** with drop announcements
- **Resistance tracking** (Fire, Nature, Frost, Shadow, Arcane)
- **Debuff detection** with configurable display
- **Chat announcements** (toggleable, configurable channel)
- Custom debuff tables for Turtle-specific content
- Support for Turtle-specific armor reduction effects

### Basic Commands

- /adf show - Show the HUD
- /adf hide - Hide the HUD
- /adf options - Open configuration panel
- /adf reset - Resert positions

## Known issues

This version can see in https://github.com/Autignem/aDF/issues. Pull request are welcome

## Credits

### Current Development & Maintenance

- **Autignem** - Complete v4.x rewrite from scratch and performance optimization

## Original Concept & Legacy Versions

- **Atreyyo @ Vanillagaming.org** - Original aDF concept and v1.0-3.0 (2006)  
- **Zebouski** - Previous maintenance and updates. See originaL in https://github.com/Zebouski/aDF/ 
- **Goffauxs** - Code contributions and improvements

Last version developed Zebouski





