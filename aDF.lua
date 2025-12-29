---########### armor/resistance and Debuff Frame
-- ########### By Atreyyo @ Vanillagaming.org <--original
-- ########### Contributor: Autignem <--reworked/rewrite
-- ########### Version 4.2

-- order of sections:
-- 1. FRAME INITIALIZATION
-- 2. GLOBAL VARIABLES AND STORAGE
-- 2.1 CENTRALIZED CONFIGURATION SYSTEM
-- 2.2 VARIABLES RUNTIME
-- 3. DATA TABLES: SPELLS AND DEBUFFS
-- 4. DATA TABLE: ARMOR VALUES
-- 5. DATA TABLE: DEBUFF ORDER
-- 6. UTILITY FUNCTIONS
-- 7. DEBUFF FRAME CREATION
-- 8. MAIN ARMOR/RESISTANCE FRAME
-- 8.1 Armor frame
-- 8.2 Resistance frame
-- 8.3 Debuff frame
-- 9. UPDATE FUNCTIONS
-- 10. SORT & POSITIONING
-- 11. DEBUFF DETECTION
-- 12. OPTIONS FRAME & UI
-- 12.1 Options GUI
-- 12.2 Tab system (Display / Notifications / Debuffs)
-- 12.3 Display tab: slider, numeric input, +/- buttons
-- 13. EVENT HANDLING
-- 13.1 ADDON_LOADED and initialization
-- 13.2 UNIT_AURA throttle and target changes
-- 14. SCRIPT REGISTRATION
-- 15. SLASH COMMANDS

-- ==== FRAME INITIALIZATION ==== 
-- Use a distinct global name for the options frame so it doesn't collide with the
-- SavedVariables table `aDF_Options`. UISpecialFrames expects a Frame, not a table.
-- Now the aDF.lua in savedvariables only contains the configuration data.

aDF = CreateFrame('Button', "aDF", UIParent) -- Main event frame
aDF.Options = CreateFrame("Frame","aDF_OptionsFrame",UIParent) -- Options frame (global name for UISpecialFrames ESC handling)

-- Register events

aDF:RegisterEvent("ADDON_LOADED")
aDF:RegisterEvent("UNIT_AURA")
aDF:RegisterEvent("PLAYER_TARGET_CHANGED")

-- ==== GLOBAL VARIABLES AND STORAGE ====

-- Performance locals

local _G = _G
local ipairs, pairs, type, tostring, tonumber = ipairs, pairs, type, tostring, tonumber

-- WoW API functions

local UnitDebuff = UnitDebuff
local UnitBuff = UnitBuff
local UnitExists = UnitExists
local UnitCanAttack = UnitCanAttack
local UnitIsPlayer = UnitIsPlayer
local UnitIsDead = UnitIsDead
local UnitAffectingCombat = UnitAffectingCombat
local UnitResistance = UnitResistance
local UnitName = UnitName
local GetTime = GetTime
local SendChatMessage = SendChatMessage

-- Math functions

local floor = math.floor
local abs = math.abs
local ceil = math.ceil
local min = math.min
local mod = math.mod

-- Table functions

local tinsert, tsort = table.insert, table.sort

-- WoW globals

local UIParent = UIParent
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local GameTooltip = GameTooltip
local PlaySound = PlaySound


-- ===== CENTRALIZED CONFIGURATION SYSTEM ===== subsection
-- The single variable stored between sessions

-- Default configuration

local DEFAULT_CONFIG = {
    version = 1,
    currentProfile = "default",
    profiles = {
        default = {
            positions = {
                armor = {x = 0, y = 0},
                resistance = {x = 0, y = 30},
                debuffs = {x = 0, y = -50}
            },
            display = {
                scale = 1.10,
                showArmorBackground = true,
                showResistanceBackground = true,
                showDebuffBackground = true,
                showArmorText = true,
                showResistanceText = true,
            },
            locks = {
                armor = false,
                resistance = false,
                debuffs = false
            },
            notifications = {
                announceArmorDrop = false,
                channel = "Say",
                channels = {"Say", "Yell", "Party", "Raid", "Raid_Warning"}
            },
            enabledDebuffs = {},
            debuffSettings = {
                maxColumns = 7,
                maxRows = 3,
                hideInactive = false,
                dynamicIcons = true
            }
        }
    }
}

-- Function to copy tables (simple, not deep-recursive)

local function CopyTable(src)
    if type(src) ~= "table" then return src end
    local dst = {}
    for k, v in pairs(src) do
        if type(v) == "table" then
            dst[k] = CopyTable(v)
        else
            dst[k] = v
        end
    end
    return dst
end


-- Function to ensure the configuration structure is complete

local function EnsureConfigStructure()

	-- If missing, create with default values

	if not aDF_Options then
        aDF_Options = CopyTable(DEFAULT_CONFIG)
        return
    end
    
	-- If exists but version is older, migrate while preserving existing profiles

	if not aDF_Options.version or aDF_Options.version < DEFAULT_CONFIG.version then

		-- Preserve existing profiles if present

		local existingProfiles = aDF_Options.profiles or {}
		aDF_Options = CopyTable(DEFAULT_CONFIG)
		aDF_Options.profiles = existingProfiles

		-- Ensure the default profile exists

		if not aDF_Options.profiles["default"] then
			aDF_Options.profiles["default"] = CopyTable(DEFAULT_CONFIG.profiles.default)
		end
		aDF_Options.currentProfile = aDF_Options.currentProfile or "default"
	end

	-- Ensure essential fields

	aDF_Options.profiles = aDF_Options.profiles or {}
	aDF_Options.currentProfile = aDF_Options.currentProfile or "default"

	-- Ensure the current profile exists

	if not aDF_Options.profiles[aDF_Options.currentProfile] then
		aDF_Options.currentProfile = "default"
		if not aDF_Options.profiles["default"] then
			aDF_Options.profiles["default"] = CopyTable(DEFAULT_CONFIG.profiles.default)
		end
	end

	-- Ensure complete structure for the current profile

	local currentProfile = aDF_Options.profiles[aDF_Options.currentProfile]
	local defaultProfile = DEFAULT_CONFIG.profiles.default

	for category, defaultCategory in pairs(defaultProfile) do
		if not currentProfile[category] then
			currentProfile[category] = CopyTable(defaultCategory)
		elseif type(defaultCategory) == "table" then
			for subKey, subDefault in pairs(defaultCategory) do
				if currentProfile[category][subKey] == nil then
					currentProfile[category][subKey] = subDefault
				end
			end
		end
	end
end

-- Safe function to get current configuration (NEVER returns nil)

local function GetConfig()
    EnsureConfigStructure()
    return aDF_Options.profiles[aDF_Options.currentProfile]
end

-- Proxy variable for compatibility with existing code

local DB = {}
setmetatable(DB, {
    __index = function(self, key)
        return GetConfig()[key]
    end,
    __newindex = function(self, key, value)
        GetConfig()[key] = value
    end
})


-- Quick and safe access to the current configuration

local function GetDB()
	return GetConfig()
end

-- Base sizes used for scalable UI (multiplied by db.display.scale)

local ICON_BASE = 24
local FONT_BASE_NR = 16
local FONT_BASE_ARMOR = 18
local FONT_BASE_RES = 14

-- ===== VARIABLES RUNTIME ===== subsection
-- this variables don't savedvariables between sessions

-- Throttle variables

local lastIconUpdate = 0
local ICON_UPDATE_THROTTLE = 0.5
local lastAuraTime = 0
local pendingUpdate = false
local last_target_change_time = GetTime()

-- Containers for frames

aDF_frames = {}       -- Container for all debuff frame elements
aDF_guiframes = {}    -- Container for all GUI checkbox elements

-- Variables temporales de estado

local aDF_target = nil
local aDF_armorprev = 30000
local aDF_lastResUpdate = 0

-- Global frames for external access

aDF_ArmorFrame = nil
aDF_DebuffFrame = nil
aDF_ResFrame = nil

-- ==== DATA TABLES: SPELLS AND DEBUFFS ==== Esta es la tabla de datos de debuffs

-- Translation table for debuff check on target

aDFSpells = {

	--armor

	["Expose Armor"] = "Expose Armor",
	["Sunder Armor"] = "Sunder Armor",
	["Curse of Recklessness"] = "Curse of Recklessness",
	["Faerie Fire"] = {"Faerie Fire", "Faerie Fire (Feral)"},
	["Decaying Flesh"] = "Decaying Flesh", --x3=400
	["Feast of Hakkar"] = "Feast of Hakkar", --400
	["Cleave Armor"] = "Cleave Armor", --300
	["Shattered Armor"] = "Shattered Armor", --250
	["Holy Sunder"] = "Holy Sunder", --50

	--spells

	["Judgement of Wisdom"] = "Judgement of Wisdom",
	["Curse of Shadows"] = "Curse of Shadow",
	["Curse of the Elements"] = "Curse of the Elements",
	["Fire Vulnerability"] = "Fire Vulnerability",
	["Shadow Weaving"] = "Shadow Weaving",
	["Nightfall"] = "Spell Vulnerability",
	["Flame Buffet"] = "Flame Buffet", --arcanite dragon/fire buff

	--other

	["Gift of Arthas"] = "Gift of Arthas", --arthas gift
	["Crooked Claw"] = "Crooked Claw", --scythe pet 2% melee
	["Demoralizing Shout"] = {"Demoralizing Shout", "Demoralizing Roar"}, --need testing
	["Thunder Clap"] = {"Thunder Clap","Thunderfury", "Frigid Blast"} --need testing
}

-- Table with debuff names and their icon textures

aDFDebuffs = {

	--armor

	["Expose Armor"] = "Interface\\Icons\\Ability_Warrior_Riposte",
	["Sunder Armor"] = "Interface\\Icons\\Ability_Warrior_Sunder",
	["Faerie Fire"] = "Interface\\Icons\\Spell_Nature_FaerieFire",
	["Curse of Recklessness"] = "Interface\\Icons\\Spell_Shadow_UnholyStrength",
	["Shattered Armor"] = "Interface\\Icons\\INV_Demonaxe", --400
	["Cleave Armor"] = "Interface\\Icons\\Ability_Warrior_Savageblow", --300
	["Feast of Hakkar"] = "Interface\\Icons\\Spell_Shadow_Bloodboil", --250
	["Holy Sunder"] = "Interface\\Icons\\Spell_Shadow_CurseOfSargeras", --50

	--spells

	["Curse of Shadows"] = "Interface\\Icons\\Spell_Shadow_CurseOfAchimonde",
	["Curse of the Elements"] = "Interface\\Icons\\Spell_Shadow_ChillTouch",
	["Shadow Weaving"] = "Interface\\Icons\\Spell_Shadow_BlackPlague",
	["Fire Vulnerability"] = "Interface\\Icons\\Spell_Fire_SoulBurn",
	["Nightfall"] = "Interface\\Icons\\Spell_Holy_ElunesGrace",
	["Flame Buffet"] = "Interface\\Icons\\Spell_Fire_Fireball",
	["Decaying Flesh"] = "Interface\\Icons\\Spell_Shadow_Lifedrain",
	["Judgement of Wisdom"] = "Interface\\Icons\\Spell_Holy_RighteousnessAura",

	--other

	["Gift of Arthas"] = "Interface\\Icons\\Spell_Nature_NullifyDisease", --arthas gift
	["Crooked Claw"] = "Interface\\Icons\\Ability_Druid_Rake", --scythe pet 2% melee
	["Demoralizing Shout"] = "Interface\\Icons\\Ability_Warrior_WarCry", --reduction melee attack
	["Thunder Clap"] = "Interface\\Icons\\Spell_Nature_Cyclone", --slow attack. Use Thunder Clap, Thunderfury or Frigid Blast this icon
}

-- ==== DATA TABLE: ARMOR VALUES ====

-- Armor reduction values by damage amount (identifies which debuff was applied)

aDFArmorVals = {
	[90]   = "Sunder Armor x1", -- r1 x1
	[180]  = "Sunder Armor",    -- r2 x1, or r1 x2
	[270]  = "Sunder Armor",    -- r3 x1, or r1 x3
	[540]  = "Sunder Armor",    -- r3 x2, or r2 x3
	[810]  = "Sunder Armor x3", -- r3 x3
	[360]  = "Sunder Armor",    -- r4 x1, or r1 x4 or r2 x2
	[720]  = "Sunder Armor",    -- r4 x2, or r2 x4
	[1080] = "Sunder Armor",    -- r4 x3, or r3 x4
	[1440] = "Sunder Armor x4", -- r4 x4
	[450]  = "Sunder Armor x1",    -- r5 x1, or r1 x5
	[900]  = "Sunder Armor x2",    -- r5 x2, or r2 x5
	[1350] = "Sunder Armor x3",    -- r5 x3, or r3 x5
	[1800] = "Sunder Armor x4",    -- r5 x4, or r4 x5
	[2250] = "Sunder Armor x5", -- r5 x5
	[725]  = "Untalented Expose Armor",
	[1050] = "Untalented Expose Armor",
	[1375] = "Untalented Expose Armor",
	[2550] = "Improved Expose Armor",
	[1700] = "Untalented Expose Armor",
	[505]  = "Faerie Fire",
	[395]  = "Faerie Fire R3",
	[285]  = "Faerie Fire R2",
	[175]  = "Faerie Fire R1",
	[640]  = "Curse of Recklessness",
	[465]  = "Curse of Recklessness R3",
	[290]  = "Curse of Recklessness R2",
	[140]  = "Curse of Recklessness R1",
	[163]  = "The Ripper / Vile Sting", -- turtle weps. spell=3396 is NPC-only in 1.12. falsely says 60 on tooltip
	[100]  = "Weapon Proc Faerie Fire", -- non-stacking proc spell=13752, Puncture Armor r1 x1 spell=11791

	-- New value to DT
	
	[400] = "Feast of Hakkar", --chest 300 runs
	[250] = "Shattered Armor", --saber weapon
	[300] = "Cleave Armor", --300
	[50]   = "Holy Sunder",
}

-- ==== DATA TABLE: DEBUFF ORDER ===== 
-- In this section is the order in which the debuffs will be displayed
-- Display order of debuffs (Left → Right, Top → Bottom)

aDFOrder = {

	--armor/melee
	
    "Expose Armor",
    "Sunder Armor", --2200
    "Curse of Recklessness",
    "Faerie Fire",
    "Decaying Flesh", --3 stack = Feast of Hakkar
    "Feast of Hakkar", --400
	"Cleave Armor", --300
    "Shattered Armor", --250
    "Holy Sunder", --50

	--other
	
	"Gift of Arthas", --arthas gift
	"Crooked Claw", --scythe pet
	"Demoralizing Shout",
	"Thunder Clap",

	--spells/caster
	
    "Judgement of Wisdom",
    "Curse of Shadows",
    "Curse of the Elements",
	"Fire Vulnerability",
	"Shadow Weaving",
    "Nightfall",
    "Flame Buffet" --arcanite dragon
}

-- ==== UTILITY FUNCTIONS ==== 
-- Utility functions (defaults, debug)

-- Initialize default configuration for debuff checkboxes

function aDF_Default()
	local db = GetDB()  -- Get current configuration
    
	if not db.enabledDebuffs or not next(db.enabledDebuffs) then
		db.enabledDebuffs = {}
		for k, v in pairs(aDFDebuffs) do
			db.enabledDebuffs[k] = true  -- All active by default
		end
	end
end

-- Debug print function, testing 4.3? 4.4?
	
-- function adfprint(arg1)
-- 	DEFAULT_CHAT_FRAME:AddMessage("|cffCC121D adf debug|r "..arg1)
-- end

-- ==== DEBUFF FRAME CREATION ==== Functions to create debuff frames

-- Creates the debuff frame elements

function aDF.Create_frame(name)
	local db = GetDB()  -- Get current configuration
	local frame = CreateFrame('Button', name, aDF)
	frame:SetBackdrop({ bgFile=[[Interface/Tooltips/UI-Tooltip-Background]] })
	frame:SetBackdropColor(255,255,255,1)
	frame.icon = frame:CreateTexture(nil, 'ARTWORK')
	frame.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	frame.icon:SetPoint('TOPLEFT', 1, -1)
	frame.icon:SetPoint('BOTTOMRIGHT', -1, 1)
	frame.nr = frame:CreateFontString(nil, "OVERLAY")
	frame.nr:SetPoint("CENTER", frame, "CENTER", 0, 0)
	frame.nr:SetFont("Fonts\\FRIZQT__.TTF", math.floor(FONT_BASE_NR * db.display.scale + 0.5))
	frame.nr:SetTextColor(255, 255, 255, 1)
	frame.nr:SetShadowOffset(2,-2)
	frame.nr:SetText("1")
	return frame
end

-- Creates GUI checkboxes for debuff selection in options panel

function aDF.Create_guiframe(name)
	local db = GetDB()  -- Get current configuration
	local frame = CreateFrame("CheckButton", name, aDF.Options, "UICheckButtonTemplate")
	frame:SetFrameStrata("LOW")
	frame:SetScript("OnClick", function() 
		local isChecked = frame:GetChecked()
		if isChecked == nil then 
			db.enabledDebuffs[name] = false  -- Change nil to false, no diference in logic, but more clean
		elseif isChecked == 1 then 
			db.enabledDebuffs[name] = true
		table.sort(db.enabledDebuffs)
		end
		aDF:Sort()
		aDF:Update()
	end)

	frame:SetScript("OnEnter", function() 
		GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
		GameTooltip:SetText(name, 255, 255, 0, 1, 1)
		GameTooltip:Show()
	end)

	frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
	frame:SetChecked(db.enabledDebuffs[name] and true or false)  -- Ensure it's true/false
	frame.Icon = frame:CreateTexture(nil, 'ARTWORK')
	frame.Icon:SetTexture(aDFDebuffs[name])
	frame.Icon:SetWidth(25)
	frame.Icon:SetHeight(25)
	frame.Icon:SetPoint("CENTER",-30,0)
	return frame
end

-- ==== MAIN ARMOR/RESISTANCE FRAME ====

function aDF:Init()
	local db = GetDB()  -- Get current configuration
    
    -- ==== ARMOR FRAME ==== subsection

    aDF_ArmorFrame = CreateFrame('Button', "aDF_ArmorFrame", UIParent)
    aDF_ArmorFrame:SetFrameStrata("BACKGROUND")
	aDF_ArmorFrame:SetWidth(100)
	aDF_ArmorFrame:SetHeight(30)
    aDF_ArmorFrame:SetPoint("CENTER", db.positions.armor.x, db.positions.armor.y)
    aDF_ArmorFrame:SetMovable(1)
    aDF_ArmorFrame:EnableMouse(1)
    aDF_ArmorFrame:RegisterForDrag("LeftButton")
    
	-- Backdrop for armor

    local armorBackdrop = {
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        tile = false, tileSize = 8, edgeSize = 8,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    }
    
    if db.display.showArmorBackground then
        aDF_ArmorFrame:SetBackdrop(armorBackdrop)
        aDF_ArmorFrame:SetBackdropColor(0,0,0,1)
    end
    
	-- Armor text

    aDF_ArmorFrame.armor = aDF_ArmorFrame:CreateFontString(nil, "OVERLAY")
    aDF_ArmorFrame.armor:SetPoint("CENTER", aDF_ArmorFrame, "CENTER", 0, 0)
	aDF_ArmorFrame.armor:SetFont("Fonts\\FRIZQT__.TTF", FONT_BASE_ARMOR)
    aDF_ArmorFrame.armor:SetText("Armor")
    
	-- Drag & Drop for armor

    aDF_ArmorFrame:SetScript("OnDragStart", function()
        if not db.locks.armor and IsShiftKeyDown() then
            this:StartMoving()
        end
    end)
    
    aDF_ArmorFrame:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
        local x, y = this:GetCenter()
        local ux, uy = UIParent:GetCenter()
        db.positions.armor.x, db.positions.armor.y = floor(x - ux + 0.5), floor(y - uy + 0.5)
    end)
    
    -- ==== RESISTANCE FRAME ==== subsection

    aDF_ResFrame = CreateFrame('Button', "aDF_ResFrame", UIParent)
    aDF_ResFrame:SetFrameStrata("BACKGROUND")
	aDF_ResFrame:SetWidth(100)
	aDF_ResFrame:SetHeight(20)
    aDF_ResFrame:SetPoint("CENTER", db.positions.resistance.x, db.positions.resistance.y)
    aDF_ResFrame:SetMovable(1)
    aDF_ResFrame:EnableMouse(1)
    aDF_ResFrame:RegisterForDrag("LeftButton")
    
	-- Resistance text

    aDF_ResFrame.res = aDF_ResFrame:CreateFontString(nil, "OVERLAY")
    aDF_ResFrame.res:SetPoint("CENTER", aDF_ResFrame, "CENTER", 0, 0)
	if aDF_ResFrame then
		aDF_ResFrame.res:SetFont("Fonts\\FRIZQT__.TTF", FONT_BASE_RES)
	end
    aDF_ResFrame.res:SetText("Resistance")
    
	-- Drag & Drop for resistances

    aDF_ResFrame:SetScript("OnDragStart", function()
        if not db.locks.resistance and IsShiftKeyDown() then
            this:StartMoving()
        end
    end)
    
    aDF_ResFrame:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
        local x, y = this:GetCenter()
        local ux, uy = UIParent:GetCenter()
        db.positions.resistance.x, db.positions.resistance.y = floor(x - ux + 0.5), floor(y - uy + 0.5)
    end)
    
    -- ==== DEBUFF FRAME ==== subsection

    aDF_DebuffFrame = CreateFrame('Button', "aDF_DebuffFrame", UIParent)
    aDF_DebuffFrame:SetFrameStrata("BACKGROUND")
	local initSize = math.floor(ICON_BASE * db.display.scale + 0.5)
	aDF_DebuffFrame:SetWidth(initSize * 7)
	aDF_DebuffFrame:SetHeight(initSize * 3)
    aDF_DebuffFrame:SetPoint("CENTER", db.positions.debuffs.x, db.positions.debuffs.y)
    aDF_DebuffFrame:SetMovable(1)
    aDF_DebuffFrame:EnableMouse(1)
    aDF_DebuffFrame:RegisterForDrag("LeftButton")
    
	-- Drag & Drop for debuffs

    aDF_DebuffFrame:SetScript("OnDragStart", function()
        if not db.locks.debuffs and IsShiftKeyDown() then
            this:StartMoving()
        end
    end)
    
    aDF_DebuffFrame:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
        local x, y = this:GetCenter()
        local ux, uy = UIParent:GetCenter()
        db.positions.debuffs.x, db.positions.debuffs.y = floor(x - ux + 0.5), floor(y - uy + 0.5)
    end)
    
	-- Create tooltip for debuff detection

	aDF_tooltip = CreateFrame("GAMETOOLTIP", "buffScan")
    aDF_tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    aDF_tooltipTextL = aDF_tooltip:CreateFontString()
    aDF_tooltipTextR = aDF_tooltip:CreateFontString()
    aDF_tooltip:AddFontStrings(aDF_tooltipTextL,aDF_tooltipTextR)
    
	-- Create debuff frames as children of the debuff frame

    for name, texture in pairs(aDFDebuffs) do
		local aDFsize = math.floor(ICON_BASE * db.display.scale + 0.5)
        aDF_frames[name] = aDF_frames[name] or aDF.Create_frame(name)
        local frame = aDF_frames[name]
        frame:SetParent(aDF_DebuffFrame)
        frame:SetWidth(aDFsize)
        frame:SetHeight(aDFsize)
        frame.icon:SetTexture(texture)
        frame:SetFrameLevel(2)
		frame:Hide()  -- Hide initially; aDF:Sort() will show them. this have fail when new adf.lua saved variables?? need checking but have dream

		-- Keep OnEnter/OnLeave scripts

        frame:SetScript("OnEnter", function() 
            GameTooltip:SetOwner(frame, "ANCHOR_TOPRIGHT")
            GameTooltip:SetText(this:GetName(), 255, 255, 0, 1, 1)
            GameTooltip:Show()
        end)
        frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    
	-- Initialize visibility according to options
	-- visuals match the SavedVariables state on startup.

	if aDF_ArmorFrame then
		if db.display.showArmorBackground then
			local backdrop = {
				edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
				bgFile = "Interface/Tooltips/UI-Tooltip-Background",
				tile="false",
				tileSize="8",
				edgeSize="8",
				insets={left="2",right="2",top="2",bottom="2"}
			}
			aDF_ArmorFrame:SetBackdrop(backdrop)
			aDF_ArmorFrame:SetBackdropColor(0,0,0,1)
		else
			aDF_ArmorFrame:SetBackdrop(nil)
		end
	end

	if aDF_ResFrame then
		if db.display.showResistanceBackground then
			local backdrop = {
				edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
				bgFile = "Interface/Tooltips/UI-Tooltip-Background",
				tile=false, tileSize=8, edgeSize=8,
				insets={left=2, right=2, top=2, bottom=2}
			}
			aDF_ResFrame:SetBackdrop(backdrop)
			aDF_ResFrame:SetBackdropColor(0,0,0,1)
		else
			aDF_ResFrame:SetBackdrop(nil)
		end
	end

	if aDF_DebuffFrame then
		if db.display.showDebuffBackground then
			local backdrop = {
				edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
				bgFile = "Interface/Tooltips/UI-Tooltip-Background",
				tile=false, tileSize=8, edgeSize=8,
				insets={left=2, right=2, top=2, bottom=2}
			}
			aDF_DebuffFrame:SetBackdrop(backdrop)
			aDF_DebuffFrame:SetBackdropColor(0,0,0,0.8)
			aDF_DebuffFrame:SetBackdropBorderColor(0.5,0.5,0.5,0.8)
		else
			aDF_DebuffFrame:SetBackdrop(nil)
		end
	end

	-- Text visibility

	if not db.display.showArmorText then aDF_ArmorFrame.armor:Hide() end
	if not db.display.showResistanceText then aDF_ResFrame.res:Hide() end
end

-- ==== UPDATE FUNCTIONS ==== 
-- Update functions. Main update function for armor/resistance display and debuff icon states

function aDF:Update()
	local db = GetDB()  -- Get current configuration
    
    if not aDF_target or not UnitExists(aDF_target) or UnitIsDead(aDF_target) then
        if aDF_ArmorFrame and aDF_ArmorFrame.armor then
            aDF_ArmorFrame.armor:SetText("")
        end
        if aDF_ResFrame and aDF_ResFrame.res then
            aDF_ResFrame.res:SetText("")
        end
        for i, v in pairs(db.enabledDebuffs) do
            if aDF_frames[i] then
                aDF_frames[i].icon:SetAlpha(0.3)
                aDF_frames[i].nr:SetText("")
            end
        end
        return
    end
    
	-- Throttle for targettarget

    if aDF_target == 'targettarget' and GetTime() < (last_target_change_time + 1.3) then
        return
    end
    
    local armorcurr = UnitResistance(aDF_target,0)
    
    -- update armor text display

    if aDF_ArmorFrame then
        if db.display.showArmorText then
            aDF_ArmorFrame.armor:SetText(armorcurr)
        else
            aDF_ArmorFrame.armor:SetText("")
        end
    end
    
	-- Cache for resistances, only every 2 seconds
	-- this reduces performance impact, but can bug if retargeting very fast

    local now = GetTime()
    if aDF_ResFrame then
        if db.display.showResistanceText then
            if not aDF_lastResUpdate or (now - aDF_lastResUpdate) > 2 then
                local fire = UnitResistance(aDF_target,2)
                local nature = UnitResistance(aDF_target,3)
                local frost = UnitResistance(aDF_target,4)
                local shadow = UnitResistance(aDF_target,5)
                local arcane = UnitResistance(aDF_target,6)
                aDF_ResFrame.res:SetText("|cffFF0000 "..fire.." |cffADFF2F "..nature.." |cff4AE8F5 "..frost.." |cff9966CC "..shadow.." |cffFEFEFA "..arcane)
                aDF_lastResUpdate = now
            end
        else
            aDF_ResFrame.res:SetText("")
        end
    end
    
    -- Announce armor drops

    if armorcurr > aDF_armorprev then
        local armordiff = armorcurr - aDF_armorprev
		local diffreason = ""
		if aDF_armorprev ~= 0 and aDFArmorVals[armordiff] then
			diffreason = " (Dropped " .. tostring(aDFArmorVals[armordiff]) .. ")"
		end
		local targetName = UnitName(aDF_target) or "Unknown"
		local msg = tostring(targetName) .. "'s armor: " .. tostring(aDF_armorprev) .. " -> " .. tostring(armorcurr) .. diffreason
        
        if aDF_target == 'target' and db.notifications.announceArmorDrop then
            SendChatMessage(msg, db.notifications.channel)
        end
    end
    aDF_armorprev = armorcurr

    -- Update debuff icon states, use basic throttling

    now = GetTime()
    
	-- Only update icons at most every 500ms
	-- This reduces performance impact during heavy aura changes, but warrior cry because don't see sunder very fast, 0,5s is good i think

	if now - lastIconUpdate > ICON_UPDATE_THROTTLE then
        lastIconUpdate = now
        
        for debuffName, _ in pairs(db.enabledDebuffs) do
            local frame = aDF_frames[debuffName]
            if frame then
                local hasDebuff = aDF:GetDebuff(aDF_target, aDFSpells[debuffName])
                local stacks = hasDebuff and aDF:GetDebuff(aDF_target, aDFSpells[debuffName], 1) or 0
                
                frame.icon:SetAlpha(hasDebuff and 1 or 0.3)
                frame.nr:SetText((stacks > 1) and tostring(stacks) or "")
            end
        end
    end
end

-- ==== SORT & POSITIONING ==== 
-- This block positions the icons. Sort function to show/hide frames and position them correctly

function aDF:Sort()
	local db = GetDB()  -- Get current configuration

	-- First, build ordered list according to aDFOrder

    local ordered = {}
    for _, debuffName in ipairs(aDFOrder) do
		-- Only include if present in aDFDebuffs and enabled in db.enabledDebuffs
        if aDFDebuffs[debuffName] and db.enabledDebuffs[debuffName] then
            table.insert(ordered, debuffName)
        end
    end
    
	-- Hide all first

    for name, _ in pairs(aDFDebuffs) do
        if aDF_frames[name] then
            aDF_frames[name]:Hide()
        end
    end
    
	-- Show and position only active ones

	local size = math.floor(ICON_BASE * db.display.scale + 0.5)
    local maxColumns = db.debuffSettings.maxColumns
    
	-- Count elements in ordered
	-- needed for frame size adjustment, and need math module in this file

    local orderedCount = 0
    for _ in ipairs(ordered) do
        orderedCount = orderedCount + 1
    end
    
    for index, debuffName in ipairs(ordered) do
        local frame = aDF_frames[debuffName]
        if frame then
            frame:Show()
            frame:ClearAllPoints()

            local currentColumn = mod((index - 1), maxColumns)
            local currentRow = floor((index - 1) / maxColumns)
            
            frame:SetPoint("TOPLEFT", aDF_DebuffFrame, "TOPLEFT", 
                          size * currentColumn, 
                          -size * currentRow)
        end
    end
    
	-- Adjust debuff frame size as needed

    local totalRows = 0
    if orderedCount > 0 then
        totalRows = ceil(orderedCount / maxColumns)
    else
        totalRows = 1
    end
    
    if aDF_DebuffFrame then
        local widthColumns = min(maxColumns, orderedCount)
        aDF_DebuffFrame:SetWidth(size * widthColumns)
        aDF_DebuffFrame:SetHeight(size * totalRows)
    end
end

-- ==== DEBUFF DETECTION ====
-- Function to check for a debuff/buff on a unit, by name or tooltip text
-- We need checking debuff and buff because when debuff slot is full, some debuffs are applied as buffs slot

function aDF:GetDebuff(name, buff, wantStacks)
    if not name or not UnitExists(name) then
        if wantStacks then
            return false, 0
        else
            return false
        end
    end
    
    local function CheckAura(auraFunc)
        local a = 1
        while auraFunc(name, a) do
            local _, stacks = auraFunc(name, a)
            aDF_tooltip:SetOwner(UIParent, "ANCHOR_NONE")
            aDF_tooltip:ClearLines()
            if auraFunc == UnitDebuff then
                aDF_tooltip:SetUnitDebuff(name, a)
            else
                aDF_tooltip:SetUnitBuff(name, a)
            end
            local aDFtext = aDF_tooltipTextL:GetText()
            
            if type(buff) == "table" then
                for _, buffName in ipairs(buff) do
                    if aDFtext and string.find(aDFtext, buffName) then
                        return true, stacks
                    end
                end
            else
                if aDFtext and string.find(aDFtext, buff) then
                    return true, stacks
                end
            end
            a = a + 1
        end
        return false, 0
    end
    
    local found, stacks = CheckAura(UnitDebuff)
    if not found then
        found, stacks = CheckAura(UnitBuff)
    end
    
    if wantStacks then
        return stacks
    else
        return found
    end
end

-- ==== OPTIONS FRAME & UI ==== 
-- Here is the options frame and its UI, have more subsection

function aDF.Options:Gui()
	local db = GetDB()  -- Get current configuration
    
	aDF.Options.Drag = { }
	function aDF.Options.Drag:StartMoving()
		this:StartMoving()
	end
	
	function aDF.Options.Drag:StopMovingOrSizing()
		this:StopMovingOrSizing()
	end

	local backdrop = {
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		tile="false",
		tileSize="4",
		edgeSize="8",
		insets={left="2", right="2", top="2", bottom="2"}
	}
	
	self:SetFrameStrata("BACKGROUND")
	self:SetWidth(400)
	self:SetHeight(550)
	self:SetPoint("CENTER",0,0)
	self:SetMovable(1)
	self:EnableMouse(1)
	self:RegisterForDrag("LeftButton")
	self:SetScript("OnDragStart", aDF.Options.Drag.StartMoving)
	self:SetScript("OnDragStop", aDF.Options.Drag.StopMovingOrSizing)
	self:SetBackdrop(backdrop)
	self:SetBackdropColor(0,0,0,1)

	-- Clear any tooltip that may be open

	self:SetScript("OnHide", function() 
		
		GameTooltip:Hide()
	end)
	
	-- ESC key handling: add to UISpecialFrames for automatic close
	-- Register the frame global name (must match the CreateFrame name above)

	tinsert(UISpecialFrames, "aDF_OptionsFrame")
	
	-- Options title

	self.text = self:CreateFontString(nil, "OVERLAY")
    self.text:SetPoint("CENTER", self, "CENTER", 0, 240)
    self.text:SetFont("Fonts\\FRIZQT__.TTF", 25)
	self.text:SetTextColor(255, 255, 0, 1)
	self.text:SetShadowOffset(2,-2)
    self.text:SetText("Options")
	
	-- Decorative lines

	self.left = self:CreateTexture(nil, "BORDER")
	self.left:SetWidth(125)
	self.left:SetHeight(2)
	self.left:SetPoint("CENTER", -62, 200)
	self.left:SetTexture(1, 1, 0, 1)
	self.left:SetGradientAlpha("Horizontal", 0, 0, 0, 0, 102, 102, 102, 0.6)

	self.right = self:CreateTexture(nil, "BORDER")
	self.right:SetWidth(125)
	self.right:SetHeight(2)
	self.right:SetPoint("CENTER", 63, 200)
	self.right:SetTexture(1, 1, 0, 1)
	self.right:SetGradientAlpha("Horizontal", 255, 255, 0, 0.6, 0, 0, 0, 0)
	
	-- ==== TAB SYSTEM ==== subsection

	local tabHeight = 30
	local tabWidth = 100
	local tabSpacing = 5
	
	self.tabs = {}
	self.tabContents = {}
	
	-- Tab 2: Notifications (CENTER)

	self.tabs[2] = CreateFrame("Button", "aDF_Tab_Notifications", self, "GameMenuButtonTemplate")
	self.tabs[2]:SetPoint("TOP", self, "TOP", 0, -100)
	self.tabs[2]:SetWidth(tabWidth)
	self.tabs[2]:SetHeight(tabHeight)
	self.tabs[2]:SetText("Notifications")
	self.tabs[2].tabIndex = 2
	self.tabs[2]:SetScript("OnClick", function()
		aDF.Options:SelectTab(2)
	end)
	
	-- Tab 1: Display (LEFT of Notifications)

	self.tabs[1] = CreateFrame("Button", "aDF_Tab_Display", self, "GameMenuButtonTemplate")
	self.tabs[1]:SetPoint("RIGHT", self.tabs[2], "LEFT", -tabSpacing, 0)
	self.tabs[1]:SetWidth(tabWidth)
	self.tabs[1]:SetHeight(tabHeight)
	self.tabs[1]:SetText("Display")
	self.tabs[1].tabIndex = 1
	self.tabs[1]:SetScript("OnClick", function()
		aDF.Options:SelectTab(1)
	end)
	
	-- Tab 3: Debuffs (RIGHT of Notifications)

	self.tabs[3] = CreateFrame("Button", "aDF_Tab_Debuffs", self, "GameMenuButtonTemplate")
	self.tabs[3]:SetPoint("LEFT", self.tabs[2], "RIGHT", tabSpacing, 0)
	self.tabs[3]:SetWidth(tabWidth)
	self.tabs[3]:SetHeight(tabHeight)
	self.tabs[3]:SetText("Debuffs")
	self.tabs[3].tabIndex = 3
	self.tabs[3]:SetScript("OnClick", function()
		aDF.Options:SelectTab(3)
	end)
	
	-- ==== TAB 1: DISPLAY (LEFT) ==== subsection

	self.tabContents[1] = CreateFrame("Frame", nil, self)
	self.tabContents[1]:SetWidth(560)
	self.tabContents[1]:SetHeight(420)
	self.tabContents[1]:SetPoint("TOP", self, "TOP", 0, -90)
	
	-- Size slider

	self.Slider = CreateFrame("Slider", "aDF Slider", self.tabContents[1], 'OptionsSliderTemplate')
	self.Slider:SetWidth(200)
	self.Slider:SetHeight(20)
	self.Slider:SetPoint("CENTER", self.tabContents[1], "CENTER", 0, 140)
	self.Slider:SetMinMaxValues(0.1, 10)
	self.Slider:SetValue(db.display.scale)
	self.Slider:SetValueStep(0.05)
	getglobal(self.Slider:GetName() .. 'Low'):SetText('0.1')
	getglobal(self.Slider:GetName() .. 'High'):SetText('10')
	-- Prevent re-entrant updates when programmatically changing the slider
	local updatingScale = false

	-- Helper to apply a new scale value and update UI (does NOT change armor/res fonts)

	local function ApplyScale(newScale)
		if updatingScale then return end
		if not newScale then return end

		-- clamp scale value

		if newScale < 0.1 then newScale = 0.1 end
		if newScale > 10 then newScale = 10 end
		db.display.scale = newScale
		local aDFsize = math.floor(ICON_BASE * db.display.scale + 0.5)

		-- update debuff icon frames, ONLY DEBUFFS by now

		for _, frame in pairs(aDF_frames) do
			frame:SetWidth(aDFsize)
			frame:SetHeight(aDFsize)
			frame.nr:SetFont("Fonts\\FRIZQT__.TTF", math.floor(FONT_BASE_NR * db.display.scale + 0.5))
		end

		-- update debuff container size (use configured maxColumns/maxRows)
		-- can be changed by user in debuff tab, but need updating here too and probably bug. im dont testing

		if aDF_DebuffFrame then
			aDF_DebuffFrame:SetWidth(aDFsize * (db.debuffSettings.maxColumns or 7))
			aDF_DebuffFrame:SetHeight(aDFsize * (db.debuffSettings.maxRows or 3))
		end

		-- sync slider and display (avoid triggering OnValueChanged handler)

		updatingScale = true
		self.Slider:SetValue(db.display.scale)
		updatingScale = false
		if self.SliderValue then
			self.SliderValue:SetText(string.format("%.2f", db.display.scale))
		end
		aDF:Sort()
	end

	-- == Slider change handler == subsection
	-- by now only debuff icons are scaled

	self.Slider:SetScript("OnValueChanged", function()
		local v = this and this:GetValue() or self.Slider:GetValue()
		if not updatingScale then
			ApplyScale(v)
		end
	end)

	-- Numeric display for current scale (editable)

	self.SliderValue = CreateFrame("EditBox", nil, self.tabContents[1], "InputBoxTemplate")
	self.SliderValue:SetWidth(40)
	self.SliderValue:SetHeight(20)

	-- Place the numeric EditBox centered below the slider to save horizontal space

	self.SliderValue:SetPoint("TOP", self.Slider, "BOTTOM", 0, 0)
	self.SliderValue:SetFont("Fonts\\FRIZQT__.TTF", 12)
	self.SliderValue:SetAutoFocus(false)
	self.SliderValue:SetText(string.format("%.2f", db.display.scale))
	self.SliderValue:SetScript("OnEnterPressed", function()
		local v = tonumber(self.SliderValue:GetText())
		if v then ApplyScale(v) end
		this:ClearFocus()
	end)

	self.SliderValue:SetScript("OnEscapePressed", function() this:ClearFocus() end)
	self.SliderValue:SetScript("OnEditFocusLost", function() -- keep display in sync
		self.SliderValue:SetText(string.format("%.2f", db.display.scale))
	end)

	-- Increment / Decrement buttons

	local step = 0.05

	-- == Button - == subsection lvl 2
	-- Decrement button (left of number)

	self.SliderDec = CreateFrame("Button", nil, self.tabContents[1], "UIPanelButtonTemplate")
	self.SliderDec:SetWidth(20)
	self.SliderDec:SetHeight(20)

	-- Decrement button immediately left of the number
	self.SliderDec:SetPoint("RIGHT", self.SliderValue, "LEFT", -6, 0)
	self.SliderDec:SetText("-")
	self.SliderDec:SetScript("OnClick", function()
		ApplyScale(math.floor((db.display.scale - step) * 100 + 0.5) / 100)
	end)

	-- == Button + == subsection lvl 2
	-- Increment button (right of number)

	self.SliderInc = CreateFrame("Button", nil, self.tabContents[1], "UIPanelButtonTemplate")
	self.SliderInc:SetWidth(20)
	self.SliderInc:SetHeight(20)

	-- Increment button immediately right of the number

	self.SliderInc:SetPoint("LEFT", self.SliderValue, "RIGHT", 6, 0)
	self.SliderInc:SetText("+")
	self.SliderInc:SetScript("OnClick", function()
		ApplyScale(math.floor((db.display.scale + step) * 100 + 0.5) / 100)
	end)
	self.Slider:Show()
	
	-- == show/lock titles == subsection 
	-- Options title "Show" 

	self.showTitle = self.tabContents[1]:CreateFontString(nil, "OVERLAY")
    self.showTitle:SetPoint("CENTER", self.tabContents[1], "CENTER", -100, 100)
    self.showTitle:SetFont("Fonts\\FRIZQT__.TTF", 12)
    self.showTitle:SetText("Show Options")

	-- Options title "Lock" 

	self.lockTitle = self.tabContents[1]:CreateFontString(nil, "OVERLAY")
    self.lockTitle:SetPoint("CENTER", self.tabContents[1], "CENTER", 100, 100)
    self.lockTitle:SetFont("Fonts\\FRIZQT__.TTF", 12)
    self.lockTitle:SetText("Lock Options")

	-- == Checkbox: Show/hide == subsection

	-- Checkbox: Show armor background

	self.armorBackgroundCheckbox = CreateFrame("CheckButton", "aDF_ArmorBackgroundCheckbox", self.tabContents[1], "UICheckButtonTemplate")
	self.armorBackgroundCheckbox:SetPoint("CENTER", self.tabContents[1], "CENTER", -160, 60)
	
	self.armorBackgroundCheckboxText = self.armorBackgroundCheckbox:CreateFontString(nil, "OVERLAY")
	self.armorBackgroundCheckboxText:SetPoint("LEFT", self.armorBackgroundCheckbox, "RIGHT", 5, 0)
	self.armorBackgroundCheckboxText:SetFont("Fonts\\FRIZQT__.TTF", 12)
	self.armorBackgroundCheckboxText:SetText("Armor Background")

	self.armorBackgroundCheckbox:SetChecked(db.display.showArmorBackground)

	self.armorBackgroundCheckbox:SetScript("OnClick", function()
		db.display.showArmorBackground = self.armorBackgroundCheckbox:GetChecked() and true or false
		if aDF_ArmorFrame then
			if db.display.showArmorBackground then
				local backdrop = {
					edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
					bgFile = "Interface/Tooltips/UI-Tooltip-Background",
					tile="false",
					tileSize="8",
					edgeSize="8",
					insets={left="2",right="2",top="2",bottom="2"}
				}
				aDF_ArmorFrame:SetBackdrop(backdrop)
				aDF_ArmorFrame:SetBackdropColor(0,0,0,1)
			else
				aDF_ArmorFrame:SetBackdrop(nil)
			end
		end
	end)

	self.armorBackgroundCheckbox:SetScript("OnEnter", function()
		GameTooltip:SetOwner(self.armorBackgroundCheckbox, "ANCHOR_RIGHT")
		GameTooltip:SetText("Show or hide the background border of the armor panel.", 1, 1, 1, 1, true)
		GameTooltip:Show()
	end)

	self.armorBackgroundCheckbox:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	-- Checkbox: Show/hide resistance background

	self.resBackgroundCheckbox = CreateFrame("CheckButton", "aDF_ResBackgroundCheckbox", self.tabContents[1], "UICheckButtonTemplate")
	self.resBackgroundCheckbox:SetPoint("CENTER", self.tabContents[1], "CENTER", -160, 20)
	self.resBackgroundCheckboxText = self.resBackgroundCheckbox:CreateFontString(nil, "OVERLAY")
	self.resBackgroundCheckboxText:SetPoint("LEFT", self.resBackgroundCheckbox, "RIGHT", 5, 0)
	self.resBackgroundCheckboxText:SetFont("Fonts\\FRIZQT__.TTF", 12)
	self.resBackgroundCheckboxText:SetText("Resistance Background")
	self.resBackgroundCheckbox:SetChecked(db.display.showResistanceBackground)
	self.resBackgroundCheckbox:SetScript("OnClick", function()
		db.display.showResistanceBackground = self.resBackgroundCheckbox:GetChecked() and true or false
		if aDF_ResFrame then
			if db.display.showResistanceBackground then
				local backdrop = {
					edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
					bgFile = "Interface/Tooltips/UI-Tooltip-Background",
					tile=false, tileSize=8, edgeSize=8,
					insets={left=2, right=2, top=2, bottom=2}
				}
				aDF_ResFrame:SetBackdrop(backdrop)
				aDF_ResFrame:SetBackdropColor(0,0,0,1)
			else
				aDF_ResFrame:SetBackdrop(nil)
			end
		end
	end)

	self.resBackgroundCheckbox:SetScript("OnEnter", function()
		GameTooltip:SetOwner(self.resBackgroundCheckbox, "ANCHOR_RIGHT")
		GameTooltip:SetText("Show or hide the background border of the resistance panel.", 1, 1, 1, 1, true)
		GameTooltip:Show()
	end)

	self.resBackgroundCheckbox:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	-- Checkbox: Show/hide debuff background

	self.debuffBackgroundCheckbox = CreateFrame("CheckButton", "aDF_DebuffBackgroundCheckbox", self.tabContents[1], "UICheckButtonTemplate")
	self.debuffBackgroundCheckbox:SetPoint("CENTER", self.tabContents[1], "CENTER", -160, -20)
	self.debuffBackgroundCheckboxText = self.debuffBackgroundCheckbox:CreateFontString(nil, "OVERLAY")
	self.debuffBackgroundCheckboxText:SetPoint("LEFT", self.debuffBackgroundCheckbox, "RIGHT", 5, 0)
	self.debuffBackgroundCheckboxText:SetFont("Fonts\\FRIZQT__.TTF", 12)
	self.debuffBackgroundCheckboxText:SetText("Debuff Background")
	self.debuffBackgroundCheckbox:SetChecked(db.display.showDebuffBackground)
	self.debuffBackgroundCheckbox:SetScript("OnClick", function()
		db.display.showDebuffBackground = self.debuffBackgroundCheckbox:GetChecked() and true or false
		if aDF_DebuffFrame then
			if db.display.showDebuffBackground then
				local backdrop = {
					edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
					bgFile = "Interface/Tooltips/UI-Tooltip-Background",
					tile=false, tileSize=8, edgeSize=8,
					insets={left=2, right=2, top=2, bottom=2}
				}
				aDF_DebuffFrame:SetBackdrop(backdrop)
				aDF_DebuffFrame:SetBackdropColor(0,0,0,0.8)
				aDF_DebuffFrame:SetBackdropBorderColor(0.5,0.5,0.5,0.8)
			else
				aDF_DebuffFrame:SetBackdrop(nil)
			end
		end
	end)

	self.debuffBackgroundCheckbox:SetScript("OnEnter", function()
		GameTooltip:SetOwner(self.debuffBackgroundCheckbox, "ANCHOR_RIGHT")
		GameTooltip:SetText("Show or hide the background border of the debuff panel", 1, 1, 1, 1, true)
		GameTooltip:Show()
	end)

	self.debuffBackgroundCheckbox:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	-- Ensure checkboxes reflect actual db values and apply backdrops accordingly
	
	self.armorBackgroundCheckbox:SetChecked(db.display.showArmorBackground and true or false)
	self.resBackgroundCheckbox:SetChecked(db.display.showResistanceBackground and true or false)
	self.debuffBackgroundCheckbox:SetChecked(db.display.showDebuffBackground and true or false)

	-- Apply armor backdrop according to current config
	if aDF_ArmorFrame then
		if db.display.showArmorBackground then
			local backdrop = {
				edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
				bgFile = "Interface/Tooltips/UI-Tooltip-Background",
				tile="false",
				tileSize="8",
				edgeSize="8",
				insets={left="2",right="2",top="2",bottom="2"}
			}
			aDF_ArmorFrame:SetBackdrop(backdrop)
			aDF_ArmorFrame:SetBackdropColor(0,0,0,1)
		else
			aDF_ArmorFrame:SetBackdrop(nil)
		end
	end

	-- Apply resistance backdrop according to current config
	if aDF_ResFrame then
		if db.display.showResistanceBackground then
			local backdrop = {
				edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
				bgFile = "Interface/Tooltips/UI-Tooltip-Background",
				tile=false, tileSize=8, edgeSize=8,
				insets={left=2, right=2, top=2, bottom=2}
			}
			aDF_ResFrame:SetBackdrop(backdrop)
			aDF_ResFrame:SetBackdropColor(0,0,0,1)
		else
			aDF_ResFrame:SetBackdrop(nil)
		end
	end

	-- Apply debuff backdrop according to current config
	if aDF_DebuffFrame then
		if db.display.showDebuffBackground then
			local backdrop = {
				edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
				bgFile = "Interface/Tooltips/UI-Tooltip-Background",
				tile=false, tileSize=8, edgeSize=8,
				insets={left=2, right=2, top=2, bottom=2}
			}
			aDF_DebuffFrame:SetBackdrop(backdrop)
			aDF_DebuffFrame:SetBackdropColor(0,0,0,0.8)
			aDF_DebuffFrame:SetBackdropBorderColor(0.5,0.5,0.5,0.8)
		else
			aDF_DebuffFrame:SetBackdrop(nil)
		end
	end

	-- Checkbox: Show/hide armor text

	self.armorTextCheckbox = CreateFrame("CheckButton", "aDF_ArmorTextCheckbox", self.tabContents[1], "UICheckButtonTemplate")
	self.armorTextCheckbox:SetPoint("CENTER", self.tabContents[1], "CENTER", -160, -60)
	self.armorTextCheckboxText = self.armorTextCheckbox:CreateFontString(nil, "OVERLAY")
	self.armorTextCheckboxText:SetPoint("LEFT", self.armorTextCheckbox, "RIGHT", 5, 0)
	self.armorTextCheckboxText:SetFont("Fonts\\FRIZQT__.TTF", 12)
	self.armorTextCheckboxText:SetText("Armor")
	self.armorTextCheckbox:SetChecked(db.display.showArmorText)
	self.armorTextCheckbox:SetScript("OnClick", function()
		db.display.showArmorText = self.armorTextCheckbox:GetChecked() and true or false
		if aDF_ArmorFrame then
			if db.display.showArmorText then
				aDF_ArmorFrame.armor:Show()
			else
				aDF_ArmorFrame.armor:Hide()
			end
		end
	end)

	self.armorTextCheckbox:SetScript("OnEnter", function()
		GameTooltip:SetOwner(self.armorTextCheckbox, "ANCHOR_RIGHT")
		GameTooltip:SetText("Show or hide the armor text.", 1, 1, 1, 1, true)
		GameTooltip:Show()
	end)

	self.armorTextCheckbox:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	-- Checkbox: Show/hide resistance text

	self.resTextCheckbox = CreateFrame("CheckButton", "aDF_ResTextCheckbox", self.tabContents[1], "UICheckButtonTemplate")
	self.resTextCheckbox:SetPoint("CENTER", self.tabContents[1], "CENTER", -160, -100)
	self.resTextCheckboxText = self.resTextCheckbox:CreateFontString(nil, "OVERLAY")
	self.resTextCheckboxText:SetPoint("LEFT", self.resTextCheckbox, "RIGHT", 5, 0)
	self.resTextCheckboxText:SetFont("Fonts\\FRIZQT__.TTF", 12)
	self.resTextCheckboxText:SetText("Resistance")
	self.resTextCheckbox:SetChecked(db.display.showResistanceText)
	self.resTextCheckbox:SetScript("OnClick", function()
		db.display.showResistanceText = self.resTextCheckbox:GetChecked() and true or false
		if aDF_ResFrame then
			if db.display.showResistanceText then
				aDF_ResFrame.res:Show()
			else
				aDF_ResFrame.res:Hide()
			end
		end
	end)

	self.resTextCheckbox:SetScript("OnEnter", function()
		GameTooltip:SetOwner(self.resTextCheckbox, "ANCHOR_RIGHT")
		GameTooltip:SetText("Show or hide the resistance text.", 1, 1, 1, 1, true)
		GameTooltip:Show()
	end)

	self.resTextCheckbox:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	-- == Checkbox: Lock/Unlock == subsection

	-- Checkbox: Lock armor frame

	self.lockArmorCheckbox = CreateFrame("CheckButton", "aDF_LockArmorCheckbox", self.tabContents[1], "UICheckButtonTemplate")
	self.lockArmorCheckbox:SetPoint("CENTER", self.tabContents[1], "CENTER", 60, 60)
	self.lockArmorCheckboxText = self.lockArmorCheckbox:CreateFontString(nil, "OVERLAY")
	self.lockArmorCheckboxText:SetPoint("LEFT", self.lockArmorCheckbox, "RIGHT", 5, 0)
	self.lockArmorCheckboxText:SetFont("Fonts\\FRIZQT__.TTF", 12)
	self.lockArmorCheckboxText:SetText("Armor frame")
	self.lockArmorCheckbox:SetChecked(db.locks.armor)
	self.lockArmorCheckbox:SetScript("OnClick", function()
		db.locks.armor = self.lockArmorCheckbox:GetChecked() and true or false
	end)

	self.lockArmorCheckbox:SetScript("OnEnter", function()
		GameTooltip:SetOwner(self.lockArmorCheckbox, "ANCHOR_RIGHT")
		GameTooltip:SetText("Lock the armor frame (prevents moving). Use Reset to restore.", 1, 1, 1, 1, true)
		GameTooltip:Show()
	end)

	self.lockArmorCheckbox:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	-- Checkbox: Lock resistance frame

	self.lockResCheckbox = CreateFrame("CheckButton", "aDF_LockResCheckbox", self.tabContents[1], "UICheckButtonTemplate")
	self.lockResCheckbox:SetPoint("CENTER", self.tabContents[1], "CENTER", 60, 20)
	self.lockResCheckboxText = self.lockResCheckbox:CreateFontString(nil, "OVERLAY")
	self.lockResCheckboxText:SetPoint("LEFT", self.lockResCheckbox, "RIGHT", 5, 0)
	self.lockResCheckboxText:SetFont("Fonts\\FRIZQT__.TTF", 12)
	self.lockResCheckboxText:SetText("Resistance frame")
	self.lockResCheckbox:SetChecked(db.locks.resistance)
	self.lockResCheckbox:SetScript("OnClick", function()
		db.locks.resistance = self.lockResCheckbox:GetChecked() and true or false
	end)

	self.lockResCheckbox:SetScript("OnEnter", function()
		GameTooltip:SetOwner(self.lockResCheckbox, "ANCHOR_RIGHT")
		GameTooltip:SetText("Lock the resistance frame (prevents moving).", 1, 1, 1, 1, true)
		GameTooltip:Show()
	end)

	self.lockResCheckbox:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	-- Checkbox: Lock debuff frame

	self.lockDebuffCheckbox = CreateFrame("CheckButton", "aDF_LockDebuffCheckbox", self.tabContents[1], "UICheckButtonTemplate")
	self.lockDebuffCheckbox:SetPoint("CENTER", self.tabContents[1], "CENTER", 60, -20)
	self.lockDebuffCheckboxText = self.lockDebuffCheckbox:CreateFontString(nil, "OVERLAY")
	self.lockDebuffCheckboxText:SetPoint("LEFT", self.lockDebuffCheckbox, "RIGHT", 5, 0)
	self.lockDebuffCheckboxText:SetFont("Fonts\\FRIZQT__.TTF", 12)
	self.lockDebuffCheckboxText:SetText("Debuff frame")
	self.lockDebuffCheckbox:SetChecked(db.locks.debuffs)
	self.lockDebuffCheckbox:SetScript("OnClick", function()
		db.locks.debuffs = self.lockDebuffCheckbox:GetChecked() and true or false
	end)

	self.lockDebuffCheckbox:SetScript("OnEnter", function()
		GameTooltip:SetOwner(self.lockDebuffCheckbox, "ANCHOR_RIGHT")
		GameTooltip:SetText("Lock the debuff frame (prevents moving).", 1, 1, 1, 1, true)
		GameTooltip:Show()
	end)

	self.lockDebuffCheckbox:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	-- ==== TAB 2: NOTIFICATIONS (CENTER) ==== subsection

	self.tabContents[2] = CreateFrame("Frame", nil, self)
	self.tabContents[2]:SetWidth(560)
	self.tabContents[2]:SetHeight(420)
	self.tabContents[2]:SetPoint("TOP", self, "TOP", 40, -90)
	
	-- Checkbox: Announce armor drops

	self.armorDropCheckbox = CreateFrame("CheckButton", "aDF_ArmorDropCheckbox", self.tabContents[2], "UICheckButtonTemplate")
	self.armorDropCheckbox:SetPoint("CENTER", self.tabContents[2], "CENTER", -150, 140)
	
	self.armorDropCheckboxText = self.armorDropCheckbox:CreateFontString(nil, "OVERLAY")
	self.armorDropCheckboxText:SetPoint("LEFT", self.armorDropCheckbox, "RIGHT", 5, 0)
	self.armorDropCheckboxText:SetFont("Fonts\\FRIZQT__.TTF", 12)
	self.armorDropCheckboxText:SetText("Announce armor drop")

	self.armorDropCheckbox:SetChecked(db.notifications.announceArmorDrop)
	
	self.armorDropCheckbox:SetScript("OnClick", function()
		db.notifications.announceArmorDrop = self.armorDropCheckbox:GetChecked() and true or false
	end)

	self.armorDropCheckbox:SetScript("OnEnter", function()
		GameTooltip:SetOwner(self.armorDropCheckbox, "ANCHOR_RIGHT")
		GameTooltip:SetText("When enabled, armor reductions will be announced in chat.", 1, 1, 1, 1, true)
		GameTooltip:Show()
	end)

	self.armorDropCheckbox:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	
	-- Chat channel dropdown

	self.dropdown = CreateFrame('Button', 'chandropdown', self.tabContents[2], 'UIDropDownMenuTemplate')
	self.dropdown:SetPoint("CENTER", self.tabContents[2], "CENTER", -100, 80)
	InitializeDropdown = function() 
		local info = {}
		for k, v in pairs(db.notifications.channels) do
			info = {}
			info.text = v
			info.value = v
			info.func = function()
				UIDropDownMenu_SetSelectedValue(chandropdown, this.value)
				db.notifications.channel = UIDropDownMenu_GetText(chandropdown)
			end
			info.checked = nil
			UIDropDownMenu_AddButton(info, 1)
			if db.notifications.channel == nil then
				UIDropDownMenu_SetSelectedValue(chandropdown, "Say")
			else
				UIDropDownMenu_SetSelectedValue(chandropdown, db.notifications.channel)
			end
		end
	end
	UIDropDownMenu_Initialize(chandropdown, InitializeDropdown)
	
	-- ==== TAB 3: DEBUFFS (RIGHT) ==== subsection

	self.tabContents[3] = CreateFrame("Frame", nil, self)
	self.tabContents[3]:SetWidth(560)
	self.tabContents[3]:SetHeight(420)
	self.tabContents[3]:SetPoint("TOP", self, "TOP", 80, -90)
	
	-- Create debuff checkboxes

	local temptable = {}
	if type(aDFOrder) == "table" then
		for _,name in ipairs(aDFOrder) do
			if aDFDebuffs[name] then
				table.insert(temptable, name)
			end
		end
	else
		for name,_ in pairs(aDFDebuffs) do
			table.insert(temptable, name)
		end
		table.sort(temptable, function(a,b) return a<b end)
	end

	local x,y= 60,-20
	for _,name in pairs(temptable) do
		y=y-40
		if y < -350 then y=-60; x=x+140 end
		aDF_guiframes[name] = aDF_guiframes[name] or aDF.Create_guiframe(name)
		local frame = aDF_guiframes[name]
		frame:SetParent(self.tabContents[3])
		frame:SetPoint("TOPLEFT", self.tabContents[3], "TOPLEFT", x, y)
	end
	
	-- ==== TAB SELECTION FUNCTION ==== subsection

	function aDF.Options:SelectTab(tabIndex)
		for i = 1, 3 do
			if i == tabIndex then
				self.tabContents[i]:Show()
				self.tabs[i]:SetDisabledFontObject(GameFontNormalSmall)
				self.tabs[i]:Disable()
			else
				self.tabContents[i]:Hide()
				self.tabs[i]:Enable()
			end
		end
	end
	
	-- Show third tab by default
	-- we always open options to debuff tab, when write /adf options

	self:SelectTab(3)
	
	-- ==== DONE BUTTON ==== subsection

	self.dbutton = CreateFrame("Button",nil,self,"UIPanelButtonTemplate")
	self.dbutton:SetPoint("BOTTOM",0,10)
	self.dbutton:SetFrameStrata("LOW")
	self.dbutton:SetWidth(79)
	self.dbutton:SetHeight(18)
	self.dbutton:SetText("Done")
	self.dbutton:SetScript("OnClick", function() 
		PlaySound("igMainMenuOptionCheckBoxOn")
		aDF:Sort()
		aDF:Update()
		-- Close the options frame
		if aDF.Options and aDF.Options.Hide then
			aDF.Options:Hide()
		end
	end)
	self:Hide()

end

-- ==== EVENT HANDLING ==== Main event handling

function aDF:OnEvent()

	-- ==== ADDON LOADED ==== subsection
	-- Initialize addon when loaded, set up frames, defaults, etc.

	if event == "ADDON_LOADED" and arg1 == "aDF" then

		-- Ensure the configuration structure is valid

		EnsureConfigStructure()
		
		-- Initialize defaults for debuffs if needed

		aDF_Default()
		
		-- Initialize state variables

		aDF_target = nil
		aDF_armorprev = 30000
		aDF_lastResUpdate = 0
		
		-- Create frames!!!!!!
		
		aDF:Init()
		aDF.Options:Gui()
		aDF:Sort()
		aDF:Update()

        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A aDF:|r Loaded",1,1,1)
        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A aDF:|r type |cFFFFFF00 /adf show|r to show frame",1,1,1)
        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A aDF:|r type |cFFFFFF00 /adf hide|r to hide frame",1,1,1)
        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A aDF:|r type |cFFFFFF00 /adf options|r for options frame",1,1,1)
        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A aDF:|r type |cFFFFFF00 /adf reset|r to reset positions",1,1,1)
        
		return
    end
    
	-- ==== THROTTLE FOR UNIT_AURA ====

    if event == "UNIT_AURA" then

		-- Only our target or player

        if arg1 ~= aDF_target and not (arg1 == "player" and aDF_target == "targettarget") then
            return
        end
        
		-- Throttle updates to at most once every 0.5 seconds
		-- This 0,5 can be slow to sunder, and warrior cry. But is necessary to performance

        local now = GetTime()
        if now - lastAuraTime > 0.5 then
            aDF:Update()
            lastAuraTime = now
            pendingUpdate = false
        else
            pendingUpdate = true
        end
        return
    end
    
    -- ==== ACTIONS ON OTHER EVENTS ====
	
    if pendingUpdate and GetTime() - lastAuraTime > 0.5 then
        aDF:Update()
        lastAuraTime = GetTime()
        pendingUpdate = false
    end
    
    if event == "PLAYER_TARGET_CHANGED" then
        pendingUpdate = false
        
        aDF_target = nil
        last_target_change_time = GetTime()
        if UnitIsPlayer("target") then
            aDF_target = "targettarget"
        end
        if UnitCanAttack("player", "target") then
            aDF_target = "target"
        end
        aDF_armorprev = 30000
        aDF:Update()
        return
    end
end

-- ==== SCRIPT REGISTRATION ====
-- Register the main event handler, if commented/delete the addon will not work, plis don't touch :(

aDF:SetScript("OnEvent", aDF.OnEvent)


-- ==== SLASH COMMANDS ==== Define the /adf commands

function aDF.slash(arg1,arg2,arg3)
	local db = GetDB()  -- Get current configuration
    
    if arg1 == nil or arg1 == "" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A aDF:|r type |cFFFFFF00 /adf show|r to show frame",1,1,1)
        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A aDF:|r type |cFFFFFF00 /adf hide|r to hide frame",1,1,1)
        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A aDF:|r type |cFFFFFF00 /adf options|r for options frame",1,1,1)
        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A aDF:|r type |cFFFFFF00 /adf reset|r to reset positions",1,1,1)
        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A aDF:|r type |cFFFFFF00 You can move frames by holding Shift and clicking on them",1,1,1)
    else

        if arg1 == "show" then
            if aDF_ArmorFrame then aDF_ArmorFrame:Show() end
            if aDF_ResFrame then aDF_ResFrame:Show() end
            if aDF_DebuffFrame then aDF_DebuffFrame:Show() end

        elseif arg1 == "hide" then
            if aDF_ArmorFrame then aDF_ArmorFrame:Hide() end
            if aDF_ResFrame then aDF_ResFrame:Hide() end
            if aDF_DebuffFrame then aDF_DebuffFrame:Hide() end

        elseif arg1 == "options" then
            aDF.Options:Show()

        elseif arg1 == "reset" then
            db.positions.armor.x, db.positions.armor.y = 0, 0
            db.positions.resistance.x, db.positions.resistance.y = 0, 30
            db.positions.debuffs.x, db.positions.debuffs.y = 0, -50
            if aDF_ArmorFrame then 
                aDF_ArmorFrame:ClearAllPoints()
                aDF_ArmorFrame:SetPoint("CENTER", 0, 0) 
            end

            if aDF_ResFrame then 
                aDF_ResFrame:ClearAllPoints()
                aDF_ResFrame:SetPoint("CENTER", 0, 30) 
            end

            if aDF_DebuffFrame then 
                aDF_DebuffFrame:ClearAllPoints()
                aDF_DebuffFrame:SetPoint("CENTER", 0, -50) 
            end

            DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A aDF:|r Positions reset",1,1,1)

        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A aDF:|r unknown command",1,0.3,0.3)
        end
    end
end

SlashCmdList['ADF_SLASH'] = aDF.slash
SLASH_ADF_SLASH1 = '/adf'
SLASH_ADF_SLASH2 = '/ADF'
