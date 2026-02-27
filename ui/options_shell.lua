-- Module: options_shell.lua
-- Purpose: main 3-column options UI and interactive setting views.
-- Exports: aDF.Options:Gui(), section/child/view handlers.
-- Depends on: GetDB(), options registry/widgets, frame globals.
-- Used by: core/events.lua init and /adf options|config.

-- New 3 column options shell.

local tinsert = table.insert
local floor = math.floor

local DEBUFF_CATEGORY_MAP = {
    armor = {
        ["Expose Armor"] = true,
        ["Sunder Armor"] = true,
        ["Curse of Recklessness"] = true,
        ["Faerie Fire"] = true,
        ["Decaying Flesh"] = true,
        ["Feast of Hakkar"] = true,
        ["Cleave Armor"] = true,
        ["Shattered Armor"] = true,
        ["Holy Sunder"] = true,
    },
    resistance = {
        ["Curse of Shadows"] = true,
        ["Curse of the Elements"] = true,
        ["Fire Vulnerability"] = true,
        ["Shadow Weaving"] = true,
        ["Shadow Vulnerability"] = true,
    },
    utility = {
        ["Judgement of Wisdom"] = true,
        ["Nightfall"] = true,
        ["Gift of Arthas"] = true,
        ["Flame Buffet"] = true,
        ["Elune's Twilight"] = true,
        ["Seal of the Crusader"] = true,
        ["Crooked Claw"] = true,
    },
    damage = {
        -- empty for now
    },
    other = {
        ["Demoralizing Shout"] = true,
        ["Thunder Clap"] = true,
    },
}

local function GetDebuffsByCategory(categoryKey)
    local list = {}
    local selected = DEBUFF_CATEGORY_MAP[categoryKey] or {}
    local seen = {}

    if type(aDFOrder) == "table" then
        for _, name in ipairs(aDFOrder) do
            if selected[name] and aDFDebuffs[name] then
                tinsert(list, name)
                seen[name] = true
            end
        end
    end

    for name in pairs(selected) do
        if not seen[name] and aDFDebuffs[name] then
            tinsert(list, name)
            seen[name] = true
        end
    end

    return list
end

local function MakeBackdrop(alpha)
    return {
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        tile = false, tileSize = 8, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
        _alpha = alpha or 1
    }
end

local function ApplyBackdrop(frame, bd)
    frame:SetBackdrop(bd)
    frame:SetBackdropColor(0, 0, 0, bd._alpha or 1)
end

local function ApplyPanelBackdrops(db)
    if aDF_ArmorFrame then
        if db.display.showArmorBackground then
            aDF_ArmorFrame:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = false, tileSize = 8, edgeSize = 8, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
            aDF_ArmorFrame:SetBackdropColor(0, 0, 0, 1)
        else
            aDF_ArmorFrame:SetBackdrop(nil)
        end
    end

    if aDF_ResFrame then
        if db.display.showResistanceBackground then
            aDF_ResFrame:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = false, tileSize = 8, edgeSize = 8, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
            aDF_ResFrame:SetBackdropColor(0, 0, 0, 1)
        else
            aDF_ResFrame:SetBackdrop(nil)
        end
    end

    if aDF_DebuffFrame then
        if db.display.showDebuffBackground then
            aDF_DebuffFrame:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = false, tileSize = 8, edgeSize = 8, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
            aDF_DebuffFrame:SetBackdropColor(0, 0, 0, 0.8)
            aDF_DebuffFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
        else
            aDF_DebuffFrame:SetBackdrop(nil)
        end
    end
end

function aDF.Options:LayoutColumns(hasSubOptions)
    local pad = 10
    local topOffset = 40
    local bottomOffset = 42
    local gap = 6
    local leftW = 145
    local middleW = 114
    local h = self:GetHeight() - topOffset - bottomOffset

    self.leftColumn:ClearAllPoints()
    self.leftColumn:SetPoint("TOPLEFT", self, "TOPLEFT", pad, -topOffset)
    self.leftColumn:SetWidth(leftW)
    self.leftColumn:SetHeight(h)

    if hasSubOptions then
        self.middleColumn:Show()
        self.middleColumn:ClearAllPoints()
        self.middleColumn:SetPoint("TOPLEFT", self.leftColumn, "TOPRIGHT", gap, 0)
        self.middleColumn:SetWidth(middleW)
        self.middleColumn:SetHeight(h)

        self.contentHost:ClearAllPoints()
        self.contentHost:SetPoint("TOPLEFT", self.middleColumn, "TOPRIGHT", gap, 0)
        self.contentHost:SetWidth(self:GetWidth() - (pad * 2 + leftW + middleW + gap * 2))
        self.contentHost:SetHeight(h)

        self.sep1:Show()
        self.sep2:Show()
        self.sep1:ClearAllPoints()
        self.sep1:SetPoint("TOPLEFT", self.leftColumn, "TOPRIGHT", floor(gap / 2), 0)
        self.sep1:SetPoint("BOTTOMLEFT", self.leftColumn, "BOTTOMRIGHT", floor(gap / 2), 0)
        self.sep2:ClearAllPoints()
        self.sep2:SetPoint("TOPLEFT", self.middleColumn, "TOPRIGHT", floor(gap / 2), 0)
        self.sep2:SetPoint("BOTTOMLEFT", self.middleColumn, "BOTTOMRIGHT", floor(gap / 2), 0)
    else
        self.middleColumn:Hide()
        self.contentHost:ClearAllPoints()
        self.contentHost:SetPoint("TOPLEFT", self.leftColumn, "TOPRIGHT", gap, 0)
        self.contentHost:SetWidth(self:GetWidth() - (pad * 2 + leftW + gap))
        self.contentHost:SetHeight(h)

        self.sep1:Show()
        self.sep2:Hide()
        self.sep1:ClearAllPoints()
        self.sep1:SetPoint("TOPLEFT", self.leftColumn, "TOPRIGHT", floor(gap / 2), 0)
        self.sep1:SetPoint("BOTTOMLEFT", self.leftColumn, "BOTTOMRIGHT", floor(gap / 2), 0)
    end
end

function aDF.Options:ClearContent()
    if not self.contentWidgets then self.contentWidgets = {} end
    for _, w in ipairs(self.contentWidgets) do
        if w and w.Hide then
            w:Hide()
            if w.SetParent then
                w:SetParent(nil)
            end
        end
    end
    self.contentWidgets = {}
end

function aDF.Options:AddContentWidget(widget)
    self.contentWidgets = self.contentWidgets or {}
    tinsert(self.contentWidgets, widget)
end

function aDF.Options:RenderView(viewId)
    local db = GetDB()
    local W = aDF_OptionsWidgets
    local host = self.contentHost

    self:ClearContent()

    local function add(w) self:AddContentWidget(w) end

    if viewId == "general_size" then
        add(W:CreateTitle(host, "General / Size", 16, -16))
        add(W:CreateLabel(host, "Debuff frame scale", 16, -44))

        local slider = CreateFrame("Slider", nil, host, "OptionsSliderTemplate")
        slider:SetWidth(220)
        slider:SetHeight(18)
        slider:SetPoint("TOPLEFT", host, "TOPLEFT", 16, -62)
        slider:SetMinMaxValues(0.1, 10)
        slider:SetValueStep(0.05)
        slider:SetValue(db.display.scale)
        add(slider)

        local edit = CreateFrame("EditBox", nil, host, "InputBoxTemplate")
        edit:SetWidth(40)
        edit:SetHeight(20)
        edit:SetPoint("LEFT", slider, "RIGHT", 12, 0)
        edit:SetAutoFocus(false)
        edit:SetText(string.format("%.2f", db.display.scale))
        add(edit)

        local dec = CreateFrame("Button", nil, host, "UIPanelButtonTemplate")
        dec:SetWidth(20)
        dec:SetHeight(20)
        dec:SetPoint("RIGHT", edit, "LEFT", -4, 0)
        dec:SetText("-")
        add(dec)

        local inc = CreateFrame("Button", nil, host, "UIPanelButtonTemplate")
        inc:SetWidth(20)
        inc:SetHeight(20)
        inc:SetPoint("LEFT", edit, "RIGHT", 4, 0)
        inc:SetText("+")
        add(inc)

        local updating = false
        local function ApplyScale(v)
            if not v then return end
            if v < 0.1 then v = 0.1 end
            if v > 10 then v = 10 end
            db.display.scale = v

            local size = floor(ICON_BASE * db.display.scale + 0.5)
            for _, frame in pairs(aDF_frames) do
                frame:SetWidth(size)
                frame:SetHeight(size)
                frame.nr:SetFont("Fonts\\FRIZQT__.TTF", floor(FONT_BASE_NR * db.display.scale + 0.5))
            end

            if aDF_DebuffFrame then
                aDF_DebuffFrame:SetWidth(size * (db.debuffSettings.maxColumns or 7))
                aDF_DebuffFrame:SetHeight(size * (db.debuffSettings.maxRows or 3))
            end

            updating = true
            slider:SetValue(db.display.scale)
            edit:SetText(string.format("%.2f", db.display.scale))
            updating = false
            aDF:Sort()
        end

        slider:SetScript("OnValueChanged", function()
            if updating then return end
            ApplyScale(this:GetValue())
        end)

        edit:SetScript("OnEnterPressed", function()
            local v = tonumber(this:GetText())
            if v then ApplyScale(v) end
            this:ClearFocus()
        end)
        edit:SetScript("OnEscapePressed", function() this:ClearFocus() end)
        edit:SetScript("OnEditFocusLost", function()
            this:SetText(string.format("%.2f", db.display.scale))
        end)

        dec:SetScript("OnClick", function()
            ApplyScale(floor((db.display.scale - 0.05) * 100 + 0.5) / 100)
        end)
        inc:SetScript("OnClick", function()
            ApplyScale(floor((db.display.scale + 0.05) * 100 + 0.5) / 100)
        end)

        return
    end

    if viewId == "general_display" then
        add(W:CreateTitle(host, "General / Display", 16, -16))

        add(W:CreateCheck(host, "Armor Background", db.display.showArmorBackground, function(v)
            db.display.showArmorBackground = v
            ApplyPanelBackdrops(db)
        end, 14, -50))

        add(W:CreateCheck(host, "Resistance Background", db.display.showResistanceBackground, function(v)
            db.display.showResistanceBackground = v
            ApplyPanelBackdrops(db)
        end, 14, -76))

        add(W:CreateCheck(host, "Debuff Background", db.display.showDebuffBackground, function(v)
            db.display.showDebuffBackground = v
            ApplyPanelBackdrops(db)
        end, 14, -102))

        add(W:CreateCheck(host, "Show Armor Text", db.display.showArmorText, function(v)
            db.display.showArmorText = v
            if aDF_ArmorFrame and aDF_ArmorFrame.armor then
                if v then aDF_ArmorFrame.armor:Show() else aDF_ArmorFrame.armor:Hide() end
            end
        end, 14, -136))

        add(W:CreateCheck(host, "Show Resistance Text", db.display.showResistanceText, function(v)
            db.display.showResistanceText = v
            if aDF_ResFrame and aDF_ResFrame.res then
                if v then aDF_ResFrame.res:Show() else aDF_ResFrame.res:Hide() end
            end
        end, 14, -162))
        return
    end

    if viewId == "general_locks" then
        add(W:CreateTitle(host, "General / Locks", 16, -16))
        add(W:CreateCheck(host, "Lock Armor Frame", db.locks.armor, function(v) db.locks.armor = v end, 14, -50))
        add(W:CreateCheck(host, "Lock Resistance Frame", db.locks.resistance, function(v) db.locks.resistance = v end, 14, -76))
        add(W:CreateCheck(host, "Lock Debuff Frame", db.locks.debuffs, function(v) db.locks.debuffs = v end, 14, -102))
        return
    end

    if viewId == "notifications_chat" then
        add(W:CreateTitle(host, "Notifications / Chat", 16, -16))

        local announceCheck = W:CreateCheck(host, "Announce armor changes", db.notifications.announceArmorDrop, function(v)
            db.notifications.announceArmorDrop = v
        end, 14, -50)
        add(announceCheck)

        local channels = db.notifications.channels or { "Say", "Yell", "Party", "Raid", "Raid_Warning" }
        local selected = db.notifications.channel or "Say"
        local lbl = W:CreateLabel(host, "Channel", 16, -86)
        add(lbl)

        local dropdown = self.channelDropdown
        if not dropdown then
            dropdown = CreateFrame("Button", "aDF_ChannelDropdown", host, "UIDropDownMenuTemplate")
            self.channelDropdown = dropdown
        else
            dropdown:SetParent(host)
            dropdown:Show()
        end
        dropdown:SetPoint("TOPLEFT", host, "TOPLEFT", 6, -98)
        add(dropdown)

        local function InitializeChannelDropdown()
            for _, ch in ipairs(channels) do
                local info = {}
                info.text = ch
                info.value = ch
                info.func = function()
                    UIDropDownMenu_SetSelectedValue(dropdown, this.value)
                    UIDropDownMenu_SetText(this.value, dropdown)
                    db.notifications.channel = this.value
                end
                info.checked = (ch == selected)
                UIDropDownMenu_AddButton(info)
            end
        end

        UIDropDownMenu_Initialize(aDF_ChannelDropdown, InitializeChannelDropdown)

        UIDropDownMenu_SetWidth(120, dropdown)
        UIDropDownMenu_SetSelectedValue(dropdown, selected)
        UIDropDownMenu_SetText(selected, dropdown)

        return
    end

    if viewId == "debuff_armor" or viewId == "debuff_resistance" or viewId == "debuff_utility" or viewId == "debuff_damage" or viewId == "debuff_other" then
        local catKey = string.gsub(viewId, "debuff_", "")
        local titleMap = {
            armor = "Armor",
            resistance = "Resistance",
            utility = "Utility",
            damage = "Damage",
            other = "Other",
        }
        local label = titleMap[catKey] or "Debuff"
        add(W:CreateTitle(host, "Debuff / " .. label, 16, -16))

        local ordered = GetDebuffsByCategory(catKey)
        if table.getn(ordered) == 0 then
            add(W:CreateLabel(host, "In progress", 16, -64))
            return
        end

        local x, y = 14, -64
        for _, name in ipairs(ordered) do
            local debuffName = name
            if y < -338 then
                y = -64
                x = x + 92
            end

            local row = CreateFrame("Frame", nil, host)
            row:SetPoint("TOPLEFT", host, "TOPLEFT", x, y)
            row:SetWidth(86)
            row:SetHeight(22)
            row:EnableMouse(1)

            local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
            cb:SetPoint("LEFT", row, "LEFT", 0, 0)
            cb:SetChecked(db.enabledDebuffs[debuffName] and true or false)

            local ic = row:CreateTexture(nil, "ARTWORK")
            ic:SetTexture(aDFDebuffs[debuffName])
            ic:SetWidth(18)
            ic:SetHeight(18)
            ic:SetPoint("LEFT", cb, "RIGHT", 2, 0)

            cb:SetScript("OnClick", function()
                db.enabledDebuffs[debuffName] = this:GetChecked() and true or false
                aDF:Sort()
                aDF:Update()
            end)

            row:SetScript("OnEnter", function()
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                GameTooltip:SetText(debuffName, 1, 1, 0, 1, 1)
                GameTooltip:Show()
            end)
            row:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)

            add(row)
            y = y - 24
        end
        return
    end

    add(W:CreateTitle(host, "Sin vista", 16, -16))
end

function aDF.Options:SelectSection(sectionId)
    local section = aDF_OptionsRegistry:GetSection(sectionId)
    if not section then return end

    self.activeSection = sectionId
    self.activeChild = nil
    local hasSubOptions = section.children and table.getn(section.children) > 1

    for _, btn in ipairs(self.mainButtons) do
        if btn.sectionId == sectionId then
            btn:Disable()
        else
            btn:Enable()
        end
    end

    for _, btn in ipairs(self.childButtons) do
        btn:Hide()
        btn:SetParent(nil)
    end
    self.childButtons = {}

    self:LayoutColumns(hasSubOptions)
    if hasSubOptions then
        local y = -12
        for _, child in ipairs(section.children or {}) do
            local b = CreateFrame("Button", nil, self.middleColumn, "UIPanelButtonTemplate")
            b.sectionId = sectionId
            b.childId = child.id
            b.viewId = child.view
            b:SetWidth(102)
            b:SetHeight(20)
            b:SetPoint("TOPLEFT", self.middleColumn, "TOPLEFT", 6, y)
            b:SetText(child.text)
            b:SetScript("OnClick", function()
                aDF.Options:SelectChild(this.sectionId, this.childId, this.viewId)
            end)
            tinsert(self.childButtons, b)
            y = y - 22
        end
    end

    if section.children and section.children[1] then
        self:SelectChild(sectionId, section.children[1].id, section.children[1].view)
    else
        self:ClearContent()
    end
end

function aDF.Options:SelectChild(sectionId, childId, viewId)
    self.activeSection = sectionId
    self.activeChild = childId

    for _, btn in ipairs(self.childButtons) do
        if btn.childId == childId then
            btn:Disable()
        else
            btn:Enable()
        end
    end

    self:RenderView(viewId)
end

function aDF.Options:Gui()
    local backdropMain = MakeBackdrop(1)
    local backdropCol = MakeBackdrop(0.35)
    local backdropContent = MakeBackdrop(0.9)

    self:SetFrameStrata("DIALOG")
    self:SetToplevel(true)
    self:SetFrameLevel(20)
    self:SetWidth(700)
    self:SetHeight(470)
    self:SetPoint("CENTER", 0, 0)
    self:SetMovable(1)
    self:EnableMouse(1)
    self:RegisterForDrag("LeftButton")
    self:SetScript("OnDragStart", function() this:StartMoving() end)
    self:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    self:SetScript("OnShow", function() this:Raise() end)
    self:SetScript("OnHide", function() GameTooltip:Hide() end)
    ApplyBackdrop(self, backdropMain)

    tinsert(UISpecialFrames, "aDF_OptionsFrame")

    self.mainButtons = self.mainButtons or {}
    self.childButtons = self.childButtons or {}
    self.contentWidgets = self.contentWidgets or {}

    self.title = self.title or self:CreateFontString(nil, "OVERLAY")
    self.title:SetPoint("TOP", self, "TOP", 0, -12)
    self.title:SetFont("Fonts\\FRIZQT__.TTF", 20)
    self.title:SetTextColor(1, 0.92, 0.35, 1)
    self.title:SetText("aDF Configuration")

    if not self.leftColumn then
        self.leftColumn = CreateFrame("Frame", nil, self)
        ApplyBackdrop(self.leftColumn, backdropCol)
    end

    if not self.middleColumn then
        self.middleColumn = CreateFrame("Frame", nil, self)
        ApplyBackdrop(self.middleColumn, backdropCol)
    end

    if not self.contentHost then
        self.contentHost = CreateFrame("Frame", nil, self)
        ApplyBackdrop(self.contentHost, backdropContent)
    end

    if not self.sep1 then
        self.sep1 = self:CreateTexture(nil, "BORDER")
        self.sep1:SetTexture(1, 1, 1, 0.22)
        self.sep1:SetWidth(1)
    end
    if not self.sep2 then
        self.sep2 = self:CreateTexture(nil, "BORDER")
        self.sep2:SetTexture(1, 1, 1, 0.22)
        self.sep2:SetWidth(1)
    end

    if not self.closeButton then
        self.closeButton = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
        self.closeButton:SetWidth(92)
        self.closeButton:SetHeight(22)
        self.closeButton:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -12, 10)
        self.closeButton:SetText("Done")
        self.closeButton:SetFrameStrata("DIALOG")
        self.closeButton:SetFrameLevel(self:GetFrameLevel() + 2)
        self.closeButton:SetScript("OnClick", function()
            PlaySound("igMainMenuOptionCheckBoxOn")
            aDF:Sort()
            aDF:Update()
            aDF.Options:Hide()
        end)
    end

    for _, btn in ipairs(self.mainButtons) do
        btn:Hide()
        btn:SetParent(nil)
    end
    self.mainButtons = {}

    local y = -10
    for _, section in ipairs(aDF_OptionsRegistry.sections) do
        local b = CreateFrame("Button", nil, self.leftColumn, "UIPanelButtonTemplate")
        b.sectionId = section.id
        b:SetWidth(130)
        b:SetHeight(20)
        b:SetPoint("TOPLEFT", self.leftColumn, "TOPLEFT", 7, y)
        b:SetText(section.text)
        b:SetScript("OnClick", function()
            aDF.Options:SelectSection(this.sectionId)
        end)
        tinsert(self.mainButtons, b)
        y = y - 22
    end

    self:LayoutColumns(false)
    self:SelectSection("general")
    self:Hide()
end
