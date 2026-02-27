-- Module: options_widgets.lua
-- Purpose: reusable helper widgets for the options shell.
-- Exports: aDF_OptionsWidgets helper table.
-- Depends on: WoW frame API.
-- Used by: ui/options_shell.lua.

-- Shared UI widget helpers for the new options shell.

aDF_OptionsWidgets = {}
local W = aDF_OptionsWidgets

function W:CreateTitle(parent, text, x, y)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetFont("Fonts\\FRIZQT__.TTF", 16)
    fs:SetTextColor(1, 0.92, 0.35, 1)
    fs:SetText(text or "")
    return fs
end

function W:CreateLabel(parent, text, x, y)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetFont("Fonts\\FRIZQT__.TTF", 12)
    fs:SetTextColor(0.95, 0.95, 0.95, 1)
    fs:SetText(text or "")
    return fs
end

function W:CreateCheck(parent, text, checked, onClick, x, y)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    cb:SetChecked(checked and true or false)
    cb:SetScript("OnClick", function()
        local v = cb:GetChecked() and true or false
        if onClick then onClick(v) end
    end)
    local t = cb:CreateFontString(nil, "OVERLAY")
    t:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    t:SetFont("Fonts\\FRIZQT__.TTF", 12)
    t:SetTextColor(1, 1, 1, 1)
    t:SetText(text or "")
    return cb
end
