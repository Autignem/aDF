--########### armor/resistance and Debuff Frame
--########### By Atreyyo @ Vanillagaming.org <--original
--########### Contributor: Autignem <--reworked/rewrite

-- order of sections:
-- 1. FRAME INITIALIZATION
-- 2. GLOBAL VARIABLES AND STORAGE
-- 3. DATA TABLES: SPELLS AND DEBUFFS
-- 4. DATA TABLE: ARMOR VALUES
-- 5. DATA TABLE: DEBUFF ORDER
-- 6. UTILITY FUNCTIONS
-- 7. DEBUFF FRAME CREATION
-- 8. MAIN ARMOR/RESISTANCE FRAME
-- 9. UPDATE FUNCTIONS
-- 10. SORT & POSITIONING
-- 11. DEBUFF DETECTION
-- 12. OPTIONS FRAME & UI
-- 13. EVENT HANDLING
-- 14. SCRIPT REGISTRATION

-- ==== FRAME INITIALIZATION ==== Aqui declaramos los frames principales

aDF = CreateFrame('Button', "aDF", UIParent) -- Main event frame
aDF.Options = CreateFrame("Frame","aDF_Options",UIParent) -- Options frame (global name for UISpecialFrames ESC handling)

-- Register events

aDF:RegisterEvent("ADDON_LOADED")
aDF:RegisterEvent("UNIT_AURA")
aDF:RegisterEvent("PLAYER_TARGET_CHANGED")

-- ==== GLOBAL VARIABLES AND STORAGE ==== Variables globales y tablas

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

local floor, abs = math.floor, math.abs

-- Table functions

local tinsert, tsort = table.insert, table.sort

-- WoW globals

local UIParent = UIParent
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local GameTooltip = GameTooltip
local PlaySound = PlaySound

-- Throttle variables

local lastIconUpdate = 0
local ICON_UPDATE_THROTTLE = 0.5
local lastAuraTime = 0
local pendingUpdate = false

-- Containers, this help fps

aDF_frames = {} -- Container for all debuff frame elements
aDF_guiframes = {} -- Container for all GUI checkbox elements
gui_Options = gui_Options or {} -- Checklist options storage
gui_Optionsxy = gui_Optionsxy or 1 -- Size scaling factor
gui_showArmorBackground = gui_showArmorBackground or 1
gui_showArmorText = gui_showArmorText or 1
gui_showResText = gui_showResText or 1
gui_announceArmorDrop = gui_announceArmorDrop or nil
gui_chan = gui_chan or "Say"
aDF_x, aDF_y = aDF_x or 0, aDF_y or 0
local last_target_change_time = GetTime() -- Timing for target changes

-- Chat channel options
gui_chantbl = {
	"Say",
	"Yell",
	"Party",
	"Raid",
	"Raid_Warning"
}

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
	["Gift of Arthas"] = "Gift of Arthas", --arthas gift
	["Crooked Claw"] = "Crooked Claw", --scythe pet 2% melee

	--spells
	["Judgement of Wisdom"] = "Judgement of Wisdom",
	["Curse of Shadows"] = "Curse of Shadow",
	["Curse of the Elements"] = "Curse of the Elements",
	["Nightfall"] = "Spell Vulnerability",
	["Shadow Weaving"] = "Shadow Weaving",
	["Flame Buffet"] = "Flame Buffet", --arcanite dragon/fire buff
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
	["Gift of Arthas"] = "Interface\\Icons\\Spell_Nature_NullifyDisease", --arthas gift
	["Crooked Claw"] = "Interface\\Icons\\Ability_Druid_Rake", --scythe pet 2% melee

	--spells
	["Curse of Shadows"] = "Interface\\Icons\\Spell_Shadow_CurseOfAchimonde",
	["Curse of the Elements"] = "Interface\\Icons\\Spell_Shadow_ChillTouch",
	["Nightfall"] = "Interface\\Icons\\Spell_Holy_ElunesGrace",
	["Flame Buffet"] = "Interface\\Icons\\Spell_Fire_Fireball",
	["Decaying Flesh"] = "Interface\\Icons\\Spell_Shadow_Lifedrain",
	["Judgement of Wisdom"] = "Interface\\Icons\\Spell_Holy_RighteousnessAura",
	["Shadow Weaving"] = "Interface\\Icons\\Spell_Shadow_BlackPlague",
}

-- ==== DATA TABLE: ARMOR VALUES ==== Aqui declaramos los valores de reduccion de armadura

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
	[450]  = "Sunder Armor",    -- r5 x1, or r1 x5
	[900]  = "Sunder Armor",    -- r5 x2, or r2 x5
	[1350] = "Sunder Armor",    -- r5 x3, or r3 x5
	[1800] = "Sunder Armor",    -- r5 x4, or r4 x5
	[2250] = "Sunder Armor x5", -- r5 x5
	[725]  = "Untalented Expose Armor",
	[1050] = "Untalented Expose Armor",
	[1375] = "Untalented Expose Armor",
	[510]  = "Fucked up IEA?",
	[1020] = "Fucked up IEA?",
	[1530] = "Fucked up IEA?",
	[2040] = "Fucked up IEA?",
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

	-- Nuevos valores de DT

	[400] = "Feast of Hakkar", --chest 300 runs
	[250] = "Shattered Armor", --saber weapon
	[300] = "Cleave Armor", --300
	[50]   = "Holy Sunder",
}

-- ==== DATA TABLE: DEBUFF ORDER ===== Aqui declaramos el orden de los debuffs en pantalla y como aparecen

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
	"Gift of Arthas", --arthas gilft
	"Crooked Claw", --scythe pet

	--spells/caster
    "Judgement of Wisdom",
    "Curse of Shadows",
    "Curse of the Elements",
	"Shadow Weaving",
    "Nightfall",
    "Flame Buffet" --arcanite dragon
}

-- ==== UTILITY FUNCTIONS ==== Funciones de utilidad (defaults, debug)

-- Initialize default configuration for debuff checkboxes

function aDF_Default()
	if guiOptions == nil then
		guiOptions = {}
		for k,v in pairs(aDFDebuffs) do
			if guiOptions[k] == nil then
				guiOptions[k] = 1
			end
		end
	end
end

-- Debug print function

function adfprint(arg1)
	DEFAULT_CHAT_FRAME:AddMessage("|cffCC121D adf debug|r "..arg1)
end

-- ==== DEBUFF FRAME CREATION ==== Funciones de creacion de frames de los debuffs

-- Creates the debuff frame elements

function aDF.Create_frame(name)
	local frame = CreateFrame('Button', name, aDF)
	frame:SetBackdrop({ bgFile=[[Interface/Tooltips/UI-Tooltip-Background]] })
	frame:SetBackdropColor(255,255,255,1)
	frame.icon = frame:CreateTexture(nil, 'ARTWORK')
	frame.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	frame.icon:SetPoint('TOPLEFT', 1, -1)
	frame.icon:SetPoint('BOTTOMRIGHT', -1, 1)
	frame.nr = frame:CreateFontString(nil, "OVERLAY")
	frame.nr:SetPoint("CENTER", frame, "CENTER", 0, 0)
	frame.nr:SetFont("Fonts\\FRIZQT__.TTF", 16+gui_Optionsxy)
	frame.nr:SetTextColor(255, 255, 255, 1)
	frame.nr:SetShadowOffset(2,-2)
	frame.nr:SetText("1")
	return frame
end

-- Creates GUI checkboxes for debuff selection in options panel

function aDF.Create_guiframe(name)
	local frame = CreateFrame("CheckButton", name, aDF.Options, "UICheckButtonTemplate")
	frame:SetFrameStrata("LOW")
	frame:SetScript("OnClick", function () 
		if frame:GetChecked() == nil then 
			guiOptions[name] = nil
		elseif frame:GetChecked() == 1 then 
			guiOptions[name] = 1 
			table.sort(guiOptions)
		end
		aDF:Sort()
		aDF:Update()
		end)
	frame:SetScript("OnEnter", function() 
		GameTooltip:SetOwner(frame, "ANCHOR_RIGHT");
		GameTooltip:SetText(name, 255, 255, 0, 1, 1);
		GameTooltip:Show()
	end)
	frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
	frame:SetChecked(guiOptions[name])
	frame.Icon = frame:CreateTexture(nil, 'ARTWORK')
	frame.Icon:SetTexture(aDFDebuffs[name])
	frame.Icon:SetWidth(25)
	frame.Icon:SetHeight(25)
	frame.Icon:SetPoint("CENTER",-30,0)
	return frame
end

-- ==== MAIN ARMOR/RESISTANCE FRAME ====

function aDF:Init()
	aDF.Drag = { }
	function aDF.Drag:StartMoving()
		if ( IsShiftKeyDown() ) then
			this:StartMoving()
		end
	end
	
	function aDF.Drag:StopMovingOrSizing()
		this:StopMovingOrSizing()
		local x, y = this:GetCenter()
		local ux, uy = UIParent:GetCenter()
		aDF_x, aDF_y = floor(x - ux + 0.5), floor(y - uy + 0.5)
	end
	
	-- Backdrop styling for armor panel
	local backdrop = {
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			tile="false",
			tileSize="8",
			edgeSize="8",
			insets={
				left="2",
				right="2",
				top="2",
				bottom="2"
			}
	}
	
	self:SetFrameStrata("BACKGROUND")
	gui_Optionsxy = gui_Optionsxy or 1
	self:SetWidth((24+gui_Optionsxy)*7)
	self:SetHeight(24+gui_Optionsxy)
	self:SetPoint("CENTER",aDF_x,aDF_y)
	self:SetMovable(1)
	self:EnableMouse(1)
	self:RegisterForDrag("LeftButton")

	if gui_showArmorBackground == 1 then
		self:SetBackdrop(backdrop)
		self:SetBackdropColor(0,0,0,1)
	end

	self:SetScript("OnDragStart", aDF.Drag.StartMoving)
	self:SetScript("OnDragStop", aDF.Drag.StopMovingOrSizing)
	self:SetScript("OnMouseDown", function()
		if (arg1 == "RightButton") then
			if aDF_target ~= nil then
				if UnitAffectingCombat(aDF_target) and UnitCanAttack("player", aDF_target) then	
					SendChatMessage(UnitName(aDF_target).." has ".. UnitResistance(aDF_target,0).." armor", gui_chan) 
				end
			end
		end
	end)
	
	-- Armor text display

	self.armor = self:CreateFontString(nil, "OVERLAY")
    self.armor:SetPoint("CENTER", self, "CENTER", 0, 0)
    self.armor:SetFont("Fonts\\FRIZQT__.TTF", 18+gui_Optionsxy)
    self.armor:SetText("Armor")

	-- Resistance text display

	self.res = self:CreateFontString(nil, "OVERLAY")
    self.res:SetPoint("CENTER", self, "CENTER", 0, 20+gui_Optionsxy)
    self.res:SetFont("Fonts\\FRIZQT__.TTF", 14+gui_Optionsxy)
    self.res:SetText("Resistance")

	-- Respect text visibility options

	if gui_showArmorText == 1 then
		self.armor:Show()
	else
		self.armor:Hide()
	end

	if gui_showResText == 1 then
		self.res:Show()
	else
		self.res:Hide()
	end
	
	-- Create tooltip for debuff detection

	aDF_tooltip = CreateFrame("GAMETOOLTIP", "buffScan")
	aDF_tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
	aDF_tooltipTextL = aDF_tooltip:CreateFontString()
	aDF_tooltipTextR = aDF_tooltip:CreateFontString()
	aDF_tooltip:AddFontStrings(aDF_tooltipTextL,aDF_tooltipTextR)
	
	-- Create all debuff frame elements

	f_ =  0
	for name,texture in pairs(aDFDebuffs) do
		aDFsize = 24+gui_Optionsxy
		aDF_frames[name] = aDF_frames[name] or aDF.Create_frame(name)
		local frame = aDF_frames[name]
		frame:SetWidth(aDFsize)
		frame:SetHeight(aDFsize)
		frame:SetPoint("BOTTOMLEFT",aDFsize*f_,-aDFsize)
		frame.icon:SetTexture(texture)
		frame:SetFrameLevel(2)
		frame:Show()
		frame:SetScript("OnEnter", function() 
			GameTooltip:SetOwner(frame, "ANCHOR_BOTTOMRIGHT");
			GameTooltip:SetText(this:GetName(), 255, 255, 0, 1, 1);
			GameTooltip:Show()
			end)
		frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
		frame:SetScript("OnMouseDown", function()
			if (arg1 == "RightButton") then
				tdb=this:GetName()
				if aDF_target ~= nil then
					if UnitAffectingCombat(aDF_target) and UnitCanAttack("player", aDF_target) and guiOptions[tdb] ~= nil then
						if not aDF:GetDebuff(aDF_target,aDFSpells[tdb]) then
							SendChatMessage("["..tdb.."] is not active on "..UnitName(aDF_target), gui_chan)
						else
							if aDF:GetDebuff(aDF_target,aDFSpells[tdb],1) == 1 then
								s_ = "stack"
							elseif aDF:GetDebuff(aDF_target,aDFSpells[tdb],1) > 1 then
								s_ = "stacks"
							end
							if aDF:GetDebuff(aDF_target,aDFSpells[tdb],1) >= 1 and aDF:GetDebuff(aDF_target,aDFSpells[tdb],1) < 5 and tdb ~= "Armor Shatter" then
								SendChatMessage(UnitName(aDF_target).." has "..aDF:GetDebuff(aDF_target,aDFSpells[tdb],1).." ["..tdb.."] "..s_, gui_chan)
							end
							if tdb == "Armor Shatter" and aDF:GetDebuff(aDF_target,aDFSpells[tdb],1) >= 1 and aDF:GetDebuff(aDF_target,aDFSpells[tdb],1) < 3 then
								SendChatMessage(UnitName(aDF_target).." has "..aDF:GetDebuff(aDF_target,aDFSpells[tdb],1).." ["..tdb.."] "..s_, gui_chan)
							end
						end
					end
				end
			end
		end)
		f_ = f_+1
	end
end

-- ==== UPDATE FUNCTIONS ==== Funciones de actualizacion. Main update function for armor/resistance display and debuff icon states

function aDF:Update()

	if not aDF_target or not UnitExists(aDF_target) or UnitIsDead(aDF_target) then
		aDF.armor:SetText("")
		aDF.res:SetText("")
		for i,v in pairs(guiOptions) do
			aDF_frames[i].icon:SetAlpha(0.3)
			aDF_frames[i].nr:SetText("")
		end
		return
	end
	
	-- Throttle para targettarget

	if aDF_target == 'targettarget' and GetTime() < (last_target_change_time + 1.3) then
		return
	end
	
	local armorcurr = UnitResistance(aDF_target,0)
	
	-- update armor text display

	if gui_showArmorText == 1 then
		aDF.armor:SetText(armorcurr)
	else
		aDF.armor:SetText("")
	end
	
	-- 4. Cache para resistencias, solo cada 2 segundos

	local now = GetTime()
	if not self.lastResUpdate or (now - self.lastResUpdate) > 2 then
		if gui_showResText == 1 then

			-- Concatenación directa, se usa para evitar un string.format 

			local fire = UnitResistance(aDF_target,2)
			local nature = UnitResistance(aDF_target,3)
			local frost = UnitResistance(aDF_target,4)
			local shadow = UnitResistance(aDF_target,5)
			local arcane = UnitResistance(aDF_target,6)
			aDF.res:SetText("|cffFF0000 "..fire.." |cffADFF2F "..nature.." |cff4AE8F5 "..frost.." |cff9966CC "..shadow.." |cffFEFEFA "..arcane)
		else
			aDF.res:SetText("")
		end
		self.lastResUpdate = now
	end
	
	-- Announce armor drops

	if armorcurr > aDF_armorprev then
		local armordiff = armorcurr - aDF_armorprev
		local diffreason = ""
		if aDF_armorprev ~= 0 and aDFArmorVals[armordiff] then
			diffreason = " (Dropped " .. aDFArmorVals[armordiff] .. ")"
		end
		local msg = UnitName(aDF_target).."'s armor: "..aDF_armorprev.." -> "..armorcurr..diffreason
		
		if aDF_target == 'target' and gui_announceArmorDrop == 1 then
			SendChatMessage(msg, gui_chan)
		end
	end
	aDF_armorprev = armorcurr

	-- Update debuff icon states, use basic throttling
	now = GetTime()
    
    -- Solo actualizar íconos cada 500ms máximo

    if now - lastIconUpdate > ICON_UPDATE_THROTTLE then
        lastIconUpdate = now
        
        for debuffName, _ in pairs(guiOptions) do
            local frame = aDF_frames[debuffName]
        	local hasDebuff = aDF:GetDebuff(aDF_target, aDFSpells[debuffName])
        	local stacks = hasDebuff and aDF:GetDebuff(aDF_target, aDFSpells[debuffName], 1) or 0
            
            frame.icon:SetAlpha(hasDebuff and 1 or 0.3)
            frame.nr:SetText((stacks > 1) and tostring(stacks) or "")
        end
	end
end

-- ==== SORT & POSITIONING ==== Este es el bloque que posiciona los iconos. Sort function to show/hide frames and position them correctly

function aDF:Sort()

    -- Show or hide debuff frames

    for name,_ in pairs(aDFDebuffs) do
        if guiOptions[name] == nil then
            aDF_frames[name]:Hide()
        else
            aDF_frames[name]:Show()
        end
    end

    -- Build ordered list from aDFOrder

    local ordered = {}
    for _, debuffName in ipairs(aDFOrder) do
        if guiOptions[debuffName] == 1 or guiOptions[debuffName] == true then
            table.insert(ordered, debuffName)
        end
    end

    -- Position icons in grid

    for index, debuffName in ipairs(ordered) do
        local frame = aDF_frames[debuffName]
        frame:ClearAllPoints()

        local size = (24 + gui_Optionsxy)

        if index <= 7 then
            -- First row
            frame:SetPoint("BOTTOMLEFT", aDF, "BOTTOMLEFT", size * (index - 1), -size)
        elseif index <= 14 then
            -- Second row
            frame:SetPoint("BOTTOMLEFT", aDF, "BOTTOMLEFT", size * ((index - 1) - 7), -(size * 2))
        else
    		-- Third row
			frame:SetPoint("BOTTOMLEFT", aDF, "BOTTOMLEFT", size * ((index - 1) - 14), -(size * 3))
			-- Teoricamente, se podrian añadir filas infinitas con esta logica.
		end
    end
end

-- ==== DEBUFF DETECTION ==== Aqui se detectan los debuff del objetivo
-- Se vera que se usa Debuff y Buff. Esto es porque cuando se alcanza el tope de 16 debuff, internamente para el servidor se usa los slot 
-- de buff para poner mas debuff, por lo que hay que revisar ambos.Tambien pueden existir 16 debuff o buff mas, pero esos se pieden en el servidor
-- y el cliente no los detecta
-- Vanilla has a 16 debuff limit on UI. When exceeded, the server places additional debuffs in BUFF slots (but they're still debuffs).
-- Therefore we must check both UnitDebuff() AND UnitBuff(). There's also a total 48 effect limit (16 debuffs + 32 buffs).
-- Any effects beyond this are LOST SERVER-SIDE and undetectable by client (16 slots). Tooltip scanning required because debuff names in API are localized.

-- Check unit for a specific debuff/buff and optional stacks

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

-- ==== OPTIONS FRAME & UI ==== Aqui se crea el frame de opciones y su UI

function aDF.Options:Gui()
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
			insets={
				left="2",
				right="2",
				top="2",
				bottom="2"
			}
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
	self:SetBackdropColor(0,0,0,1);
	
	-- ESC key handling: add to UISpecialFrames for automatic close

	tinsert(UISpecialFrames, "aDF_Options")
	
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
	
	-- ==== TAB SYSTEM ====
	local tabHeight = 30
	local tabWidth = 100
	local tabSpacing = 5
	
	self.tabs = {}
	self.tabContents = {}
	
	-- Tab 2: Notifications (CENTER)
	-- Center tab is created first for easier positioning of left/right tabs
	-- Lo usamos como centro para encuadrar el resto debemos usar este como referencia

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
	
	-- ==== TAB 1: DISPLAY (LEFT) ====

	self.tabContents[1] = CreateFrame("Frame", nil, self)
	self.tabContents[1]:SetWidth(560)
	self.tabContents[1]:SetHeight(420)
	self.tabContents[1]:SetPoint("TOP", self, "TOP", 0, -90)
	
	-- Size slider

	self.Slider = CreateFrame("Slider", "aDF Slider", self.tabContents[1], 'OptionsSliderTemplate')
	self.Slider:SetWidth(200)
	self.Slider:SetHeight(20)
	self.Slider:SetPoint("CENTER", self.tabContents[1], "CENTER", 0, 140)
	self.Slider:SetMinMaxValues(1, 10)
	self.Slider:SetValue(gui_Optionsxy)
	self.Slider:SetValueStep(1)
	getglobal(self.Slider:GetName() .. 'Low'):SetText('1')
	getglobal(self.Slider:GetName() .. 'High'):SetText('10')
	self.Slider:SetScript("OnValueChanged", function() 
		gui_Optionsxy = this:GetValue()
		for _, frame in pairs(aDF_frames) do
			frame:SetWidth(24+gui_Optionsxy)
			frame:SetHeight(24+gui_Optionsxy)
			frame.nr:SetFont("Fonts\\FRIZQT__.TTF", 16+gui_Optionsxy)
		end
		aDF:SetWidth((24+gui_Optionsxy)*7)
		aDF:SetHeight(24+gui_Optionsxy)
		aDF.armor:SetFont("Fonts\\FRIZQT__.TTF", 24+gui_Optionsxy)
		aDF.res:SetFont("Fonts\\FRIZQT__.TTF", 14+gui_Optionsxy)
		aDF.res:SetPoint("CENTER", aDF, "CENTER", 0, 20+gui_Optionsxy)
		aDF:Sort()
	end)
	self.Slider:Show()
	
	-- Checkbox: Show armor background

	self.armorBackgroundCheckbox = CreateFrame("CheckButton", "aDF_ArmorBackgroundCheckbox", self.tabContents[1], "UICheckButtonTemplate")
	self.armorBackgroundCheckbox:SetPoint("CENTER", self.tabContents[1], "CENTER", -100, 60)
	
	self.armorBackgroundCheckboxText = self.armorBackgroundCheckbox:CreateFontString(nil, "OVERLAY")
	self.armorBackgroundCheckboxText:SetPoint("LEFT", self.armorBackgroundCheckbox, "RIGHT", 5, 0)
	self.armorBackgroundCheckboxText:SetFont("Fonts\\FRIZQT__.TTF", 12)
	self.armorBackgroundCheckboxText:SetText("Show armor background")

	self.armorBackgroundCheckbox:SetChecked(gui_showArmorBackground == 1)

	self.armorBackgroundCheckbox:SetScript("OnClick", function()
		gui_showArmorBackground = self.armorBackgroundCheckbox:GetChecked() and 1 or 0
		if gui_showArmorBackground == 1 then
			local backdrop = {
				edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
				bgFile = "Interface/Tooltips/UI-Tooltip-Background",
				tile="false",
				tileSize="8",
				edgeSize="8",
				insets={left="2",right="2",top="2",bottom="2"}
			}
			aDF:SetBackdrop(backdrop)
			aDF:SetBackdropColor(0,0,0,1)
		else
			aDF:SetBackdrop(nil)
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

	-- Checkbox: Show/hide armor text

	self.armorTextCheckbox = CreateFrame("CheckButton", "aDF_ArmorTextCheckbox", self.tabContents[1], "UICheckButtonTemplate")
	self.armorTextCheckbox:SetPoint("CENTER", self.tabContents[1], "CENTER", -100, 20)
	self.armorTextCheckboxText = self.armorTextCheckbox:CreateFontString(nil, "OVERLAY")
	self.armorTextCheckboxText:SetPoint("LEFT", self.armorTextCheckbox, "RIGHT", 5, 0)
	self.armorTextCheckboxText:SetFont("Fonts\\FRIZQT__.TTF", 12)
	self.armorTextCheckboxText:SetText("Show armor")
	self.armorTextCheckbox:SetChecked(gui_showArmorText == 1)
	self.armorTextCheckbox:SetScript("OnClick", function()
		gui_showArmorText = self.armorTextCheckbox:GetChecked() and 1 or 0
		if gui_showArmorText == 1 then
			aDF.armor:Show()
		else
			aDF.armor:Hide()
		end
	end)

	-- Checkbox: Show/hide resistance text

	self.resTextCheckbox = CreateFrame("CheckButton", "aDF_ResTextCheckbox", self.tabContents[1], "UICheckButtonTemplate")
	self.resTextCheckbox:SetPoint("CENTER", self.tabContents[1], "CENTER", -100, -20)
	self.resTextCheckboxText = self.resTextCheckbox:CreateFontString(nil, "OVERLAY")
	self.resTextCheckboxText:SetPoint("LEFT", self.resTextCheckbox, "RIGHT", 5, 0)
	self.resTextCheckboxText:SetFont("Fonts\\FRIZQT__.TTF", 12)
	self.resTextCheckboxText:SetText("Show resistance")
	self.resTextCheckbox:SetChecked(gui_showResText == 1)
	self.resTextCheckbox:SetScript("OnClick", function()
		gui_showResText = self.resTextCheckbox:GetChecked() and 1 or 0
		if gui_showResText == 1 then
			aDF.res:Show()
		else
			aDF.res:Hide()
		end
	end)
	
	-- ==== TAB 2: NOTIFICATIONS (CENTER) ====

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

	self.armorDropCheckbox:SetChecked(gui_announceArmorDrop == 1)

	-- Sin esto no funcioan el checkbox correctamente
	
	self.armorDropCheckbox:SetScript("OnClick", function()
		gui_announceArmorDrop = self.armorDropCheckbox:GetChecked() and 1 or nil
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
		for k,v in pairs(gui_chantbl) do
			info = {}
			info.text = v
			info.value = v
			info.func = function()
			UIDropDownMenu_SetSelectedValue(chandropdown, this.value)
			gui_chan = UIDropDownMenu_GetText(chandropdown)
			end
			info.checked = nil
			UIDropDownMenu_AddButton(info, 1)
			if gui_chan == nil then
				UIDropDownMenu_SetSelectedValue(chandropdown, "Say")
			else
				UIDropDownMenu_SetSelectedValue(chandropdown, gui_chan)
			end
		end
	end
	UIDropDownMenu_Initialize(chandropdown, InitializeDropdown)
	
	-- ==== TAB 3: DEBUFFS (RIGHT) ====

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
	
	-- ==== TAB SELECTION FUNCTION ====

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

	self:SelectTab(3)
	
	-- ==== DONE BUTTON ====

	self.dbutton = CreateFrame("Button",nil,self,"UIPanelButtonTemplate")
	self.dbutton:SetPoint("BOTTOM",0,10)
	self.dbutton:SetFrameStrata("LOW")
	self.dbutton:SetWidth(79)
	self.dbutton:SetHeight(18)
	self.dbutton:SetText("Done")
	self.dbutton:SetScript("OnClick", function() PlaySound("igMainMenuOptionCheckBoxOn"); aDF:Sort(); aDF:Update(); aDF.Options:Hide() end)
	self:Hide()
end

-- ==== EVENT HANDLING ==== Aqui se manejan los eventos principales
-- 1. ADDON_LOADED --> Initialize saved variables, create frames
-- 2. PLAYER_TARGET_CHANGED --> Set aDF_target (target or targettarget)
-- 3. UNIT_AURA (throttled) --> Update debuffs if for our target
-- 4. (No OnUpdate!) --> Pure event-driven architecture

-- Main event handler
function aDF:OnEvent()

	-- ==== ADDON LOADED ====

    if event == "ADDON_LOADED" and arg1 == "aDF" then
        aDF_Default()
        aDF_target = nil
        aDF_armorprev = 30000
        aDF.lastResUpdate = 0
        if gui_chan == nil then gui_chan = "Say" end
        if gui_announceArmorDrop ~= 1 then 
            gui_announceArmorDrop = nil
        end
        if gui_showArmorBackground == nil then
            gui_showArmorBackground = 1
        end
        if gui_showArmorText == nil then
            gui_showArmorText = 1
        end
        if gui_showResText == nil then
            gui_showResText = 1
        end
        aDF:Init()
        aDF.Options:Gui()
        aDF:Sort()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A aDF:|r Loaded",1,1,1)
        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A aDF:|r type |cFFFFFF00 /adf show|r to show frame",1,1,1)
        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A aDF:|r type |cFFFFFF00 /adf hide|r to hide frame",1,1,1)
        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A aDF:|r type |cFFFFFF00 /adf options|r for options frame",1,1,1)
        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A aDF:|r type |cFFFFFF00 You can move the debuff icons by holding Shift and clicking on them",1,1,1)
        return
    end
    
    -- ==== THROTTLE PARA UNIT_AURA ====
	-- UNIT_AURA fires VERY frequently, on every aura application/removal. Cause we need throttling

    if event == "UNIT_AURA" then

        -- Solo nuestro target o player

        if arg1 ~= aDF_target and not (arg1 == "player" and aDF_target == "targettarget") then
            return
        end
        
        local now = GetTime()

        -- Si pasó más de 500ms desde la última actualización, actualizar inmediatamente
		-- If more than 500ms have passed since the last update, update immediately

        if now - lastAuraTime > 0.5 then
            aDF:Update()
            lastAuraTime = now
            pendingUpdate = false
        else
            -- Marcar que hay update pendiente
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

        -- Limpiar estado pendiente
		-- Clear pending state

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
-- Aqui se registran los scripts principales, por el amor de dios no lo toques, si se borra se jode todo el addom, es codigo de herencia
-- This is legacy code, please do not modify or remove it. If you delete or comment aDF:SetScript("OnEvent", aDF.OnEvent), the addon will break.

aDF:SetScript("OnEvent", aDF.OnEvent)

-- ==== SLASH COMMANDS ==== Aqui definimos los comandos de /adf

function aDF.slash(arg1,arg2,arg3)
	if arg1 == nil or arg1 == "" then
		DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A aDF:|r type |cFFFFFF00 /adf show|r to show frame",1,1,1)
		DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A aDF:|r type |cFFFFFF00 /adf hide|r to hide frame",1,1,1)
		DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A aDF:|r type |cFFFFFF00 /adf options|r for options frame",1,1,1)
		DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A aDF:|r type |cFFFFFF00 You can move the debuff icons by holding Shift and clicking on them",1,1,1)
		else
		if arg1 == "show" then
			aDF:Show()
		elseif arg1 == "hide" then
			aDF:Hide()
		elseif arg1 == "options" then
			aDF.Options:Show()
		else
			DEFAULT_CHAT_FRAME:AddMessage(arg1)
			DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A aDF:|r unknown command",1,0.3,0.3);
		end
	end
end

SlashCmdList['ADF_SLASH'] = aDF.slash
SLASH_ADF_SLASH1 = '/adf'
SLASH_ADF_SLASH2 = '/ADF'

